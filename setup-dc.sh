cd /var/www
docker-compose build
docker-compose up -d db --wait && docker-compose up -d mautic_web --wait

echo "## Wait for basic-mautic_web-1 container to be fully running"
while ! docker exec basic-mautic_web-1 sh -c 'echo "Container is running"'; do
    echo "### Waiting for basic-mautic_web-1 to be fully running..."
    sleep 2
done

echo "## Check if Mautic is installed"
if docker-compose exec -T mautic_web test -f /var/www/html/config/local.php && docker-compose exec -T mautic_web grep -q "site_url" /var/www/html/config/local.php; then
    echo "## Mautic is installed already."
else
    # Check if the container exists and is running
    # replace basic with the Docker network of the client
    if docker ps --filter "name=basic-mautic_worker-1" --filter "status=running" -q | grep -q .; then
        echo "Stopping basic-mautic_worker-1 to avoid https://github.com/mautic/docker-mautic/issues/270"
        docker stop basic-mautic_worker-1
        echo "## Ensure the worker is stopped before installing Mautic"
        while docker ps -q --filter name=basic-mautic_worker-1 | grep -q .; do
            echo "### Waiting for basic-mautic_worker-1 to stop..."
            sleep 2
        done
    else
        echo "Container basic-mautic_worker-1 does not exist or is not running."
    fi
    echo "## Installing Mautic..."
    # Check if the ports block each other when supporting multiple clients, look into a way to pick an available port automatically
    docker-compose exec -T -u www-data -w /var/www/html mautic_web php ./bin/console mautic:install --force --admin_email {{AGENCY_ADMIN_EMAIL_ADDRESS}} --admin_password {{AGENCY_ADMIN_PASSWORD}} http://{{SERVER_IP_ADDRESS}}:{{SERVER_PORT}}
fi

echo "## Starting all the containers"
docker-compose up -d

CLIENT_SUBDOMAIN="{{CLIENT_SUBDOMAIN}}"

if [[ "$CLIENT_SUBDOMAIN" == *"CLIENT_SUBDOMAIN"* ]]; then
    echo "The CLIENT_SUBDOMAIN variable is not set yet."
    exit 0
fi

SERVER_IP_ADDRESS=$(curl -s http://icanhazip.com)

echo "## Checking if $CLIENT_SUBDOMAIN points to this IP address..."
DOMAIN_IP=$(dig +short $CLIENT_SUBDOMAIN)
if [ "$DOMAIN_IP" != "$SERVER_IP_ADDRESS" ]; then
    echo "## $CLIENT_SUBDOMAIN does not point to this IP address ($SERVER_IP_ADDRESS). Exiting..."
    exit 1
fi

echo "## $CLIENT_SUBDOMAIN is available and points to this droplet. Nginx configuration..."

SOURCE_PATH="/var/www/nginx-virtual-host-$CLIENT_SUBDOMAIN"
TARGET_PATH="/etc/nginx/sites-enabled/nginx-virtual-host-$CLIENT_SUBDOMAIN"

# Remove the existing symlink if it exists
if [ -L "$TARGET_PATH" ]; then
    rm $TARGET_PATH
    echo "Existing symlink for $CLIENT_SUBDOMAIN configuration removed."
fi

# Create a new symlink
ln -s $SOURCE_PATH $TARGET_PATH
echo "Symlink created for $CLIENT_SUBDOMAIN configuration."

if ! nginx -t; then
    echo "Nginx configuration test failed, stopping the script."
    exit 1
fi

# Check if Nginx is running and reload to apply changes
if ! pgrep -x nginx > /dev/null; then
    echo "Nginx is not running, starting Nginx..."
    systemctl start nginx
else
    echo "Reloading Nginx to apply new configuration."
    nginx -s reload
fi

echo "## Configuring Let's Encrypt for $CLIENT_SUBDOMAIN..."

# Use Certbot with the Nginx plugin to obtain and install a certificate
certbot --nginx -d $CLIENT_SUBDOMAIN --non-interactive --agree-tos -m {{AGENCY_ADMIN_EMAIL_ADDRESS}}

# Nginx will be reloaded automatically by Certbot after obtaining the certificate
echo "## Let's Encrypt configured for $CLIENT_SUBDOMAIN"

# Check if the cron job for renewal is already set
if ! crontab -l | grep -q 'certbot renew'; then
    echo "## Setting up cron job for Let's Encrypt certificate renewal..."
    (crontab -l 2>/dev/null; echo "0 0 1 * * certbot renew --post-hook 'systemctl reload nginx'") | crontab -
else
    echo "## Cron job for Let's Encrypt certificate renewal is already set"
fi

echo "## Check if Mautic is installed"
if docker-compose exec -T mautic_web test -f /var/www/html/config/local.php && docker-compose exec -T mautic_web grep -q "site_url" /var/www/html/config/local.php; then
    echo "## Mautic is installed already."
    
    # Replace the site_url value with the domain
    echo "## Updating site_url in Mautic configuration..."
    docker-compose exec -T mautic_web sed -i "s|'site_url' => '.*',|'site_url' => 'https://$CLIENT_SUBDOMAIN',|g" /var/www/html/config/local.php
fi

echo "## Script execution completed"

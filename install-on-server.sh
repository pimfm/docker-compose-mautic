
# Install dependencies
echo "## Installing dependencies..."
sudo yum install git -y
sudo yum install docker -y
sudo yum install nginx -y
sudo yum install certbot -y
sudo yum install python3-certbot-nginx -y
sudo yum install vim -y
sudo yum install nano -y
sudo yum install cronie -y
echo "## Done"

# Setup docker compose
# TODO: Quote unames to suppress warning
echo "## Installing Docker Compose..."
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version
echo "## Done"

# Setup docker
echo "## Starting Docker..."
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl is-enabled docker
echo "## Done"

# Setup cron
echo "## Starting Cron..."
sudo systemctl start crond
sudo systemctl enable crond
sudo systemctl is-enabled crond
echo "## Done"

# Configure Domain with NGINX
# Generate subdomain from CLIENT_PREFIX and AGENCY_DOMAIN
echo "## Configuring NGINX..."
mv nginx-virtual-host-template "nginx-virtual-host-demo.ormine.nl"
sed -i "s/{{CLIENT_SUBDOMAIN}}/demo.ormine.nl/g" "nginx-virtual-host-demo.ormine.nl"
sed -i "s/{{PORT}}/8001/g" "nginx-virtual-host-demo.ormine.nl"
sudo mkdir -p /etc/nginx/sites-available
mv nginx-virtual-host-demo.ormine.nl /etc/nginx/sites-available/nginx-virtual-host-demo.ormine.nl
echo "## Done"

# Configure HTTPS with Certbot
echo "## Configuring HTTPS with Certbot..."
sed -i "s/{{SERVER_IP_ADDRESS}}/18.197.107.66/g" setup-dc.sh
sed -i "s/{{SERVER_PORT}}/8001/g" setup-dc.sh
sed -i "s/{{AGENCY_ADMIN_EMAIL_ADDRESS}}/example-email@ormine.nl/g" setup-dc.sh
sed -i "s/{{AGENCY_ADMIN_PASSWORD}}/examplepassword/g" setup-dc.sh
sed -i "s/{{CLIENT_SUBDOMAIN}}/demo.ormine.nl/g" setup-dc.sh
echo "## Done"

# Install Mautic
echo "## Installing Mautic..."
sudo mkdir -p /var/www
./setup-dc.sh
echo "## Done"
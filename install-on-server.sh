
# Install dependencies
sudo yum install -y curl git docker nginx certbot python3-certbot-nginx vim nano
curl --version
git --version
docker --version

# Clone repository
git clone https://github.com/pimfm/docker-compose-mautic demo
cd demo || exit

# Setup docker compose
# TODO: Quote unames to suppress warning
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# Setup docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl is-enabled docker

# Configure Domain with NGINX
# Generate subdomain from CLIENT_PREFIX and AGENCY_DOMAIN
mv nginx-virtual-host-template "nginx-virtual-host-demo.ormine.nl"
sed -i "s/{{CLIENT_SUBDOMAIN}}/demo.ormine.nl/g" "nginx-virtual-host-demo.ormine.nl"
sed -i "s/{{PORT}}/8001/g" "nginx-virtual-host-demo.ormine.nl"
cat nginx-virtual-host-demo.ormine.nl

# Configure HTTPS with Certbot
sed -i "s/{{SERVER_IP_ADDRESS}}/18.197.107.66/g" setup-dc.sh
sed -i "s/{{SERVER_PORT}}/8001/g" setup-dc.sh
sed -i "s/{{AGENCY_ADMIN_EMAIL_ADDRESS}}/example-email@ormine.nl/g" setup-dc.sh
sed -i "s/{{AGENCY_ADMIN_PASSWORD}}/examplepassword/g" setup-dc.sh
sed -i "s/{{CLIENT_SUBDOMAIN}}/demo.ormine.nl/g" setup-dc.sh

# Install Mautic
sudo mkdir -p /var/www && cd /var/www || exit
./setup-dc.sh


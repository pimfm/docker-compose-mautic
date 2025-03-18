
# Install dependencies
sudo yum install -y curl git docker nginx certbot python3-certbot-nginx vim nano
curl --version
git --version
docker --version

# Clone repository
git clone https://github.com/pimfm/docker-compose-mautic ${{ vars.CLIENT_PREFIX }}
cd ${{ vars.CLIENT_PREFIX }}

# Setup docker compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# Setup docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl is-enabled docker

# Configure Domain with NGINX
# Generate subdomain from CLIENT_PREFIX and AGENCY_DOMAIN
mv nginx-virtual-host-template "nginx-virtual-host-${{ vars.CLIENT_SUBDOMAIN }}"
sed -i "s/DOMAIN_NAME/${{ vars.CLIENT_SUBDOMAIN }}/g" "nginx-virtual-host-${{ vars.CLIENT_SUBDOMAIN }}"
sed -i "s/PORT/${{ env.MAUTIC_PORT }}/g" "nginx-virtual-host-${{ vars.CLIENT_SUBDOMAIN }}"
cat nginx-virtual-host-${{ vars.DOMAIN }}

# Configure Let's Encrypt
sed -i "s/{{IP_ADDRESS}}/${{ vars.SERVER_IP_ADDRESS }}/g" setup-dc.sh
sed -i "s/{{PORT}}/${{ env.MAUTIC_PORT }}/g" setup-dc.sh
sed -i "s/{{EMAIL_ADDRESS}}/${{ env.AGENCY_ADMIN_EMAIL_ADDRESS }}/g" setup-dc.sh
sed -i "s/{{MAUTIC_PASSWORD}}/${{ secrets.AGENCY_ADMIN_PASSWORD }}/g" setup-dc.sh
if [ ! -z "${{ env.CLIENT_SUBDOMAIN }}" ]; then
  sed -i "s/{{DOMAIN_NAME}}/${{ env.CLIENT_SUBDOMAIN }}/g" setup-dc.sh
fi

./setup-dc.sh

# Docker compose up
sudo docker-compose up -d

# Set IP address
sed -i "s/{{IP_ADDRESS}}/${{ vars.SERVER_IP_ADDRESS }}/g" setup-dc.sh
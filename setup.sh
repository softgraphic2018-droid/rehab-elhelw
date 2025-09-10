#!/bin/bash
set -e

# Basic setup - installs docker, docker-compose, clones repo and runs compose.
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
usermod -aG docker ${SUDO_USER:-$USER}

mkdir -p /opt/edustream
cd /opt/edustream

if [ ! -d ".git" ]; then
  echo "[+] Cloning repo..."
  git clone YOUR_REPO_URL .
else
  echo "[=] Repo already present."
fi

echo "[+] Building and starting compose stack..."
/usr/local/bin/docker-compose -f docker-compose.prod.yml build
/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d

# Obtain Let's Encrypt certificate (one-time)
docker run -it --rm --name certbot \
  -v $(pwd)/certbot/www:/var/www/certbot \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  certbot/certbot certonly --webroot -w /var/www/certbot -d YOUR_DOMAIN -d www.YOUR_DOMAIN --email your@email.com --agree-tos --no-eff-email

/usr/local/bin/docker-compose -f docker-compose.prod.yml restart nginx

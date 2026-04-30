#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
newgrp docker

# Install Docker Compose v2
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Install Certbot for SSL certificate management
sudo apt-get update
sudo apt-get install -y certbot

# Clone the repository
git clone https://github.com/Musty2025x/shopflow.git
cd shopflow

# Obtain SSL certificates using Certbot
sudo certbot certonly --standalone \
  -d mustydevops.com.ng \
  -d www.mustydevops.com.ng \
  --email musty2025x@gmail.com \
  --agree-tos \
  --non-interactive

# Build and run the application
docker-compose up -d --build
sleep 15
docker ps
curl https://mustydevops.com.ng/health
docker logs shopflow_app


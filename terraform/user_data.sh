#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y nginx rsync

sudo snap install amazon-ssm-agent --classic || true
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

snap install aws-cli --classic

systemctl enable nginx 
systemctl start nginx

echo "<h1>Cloud Support Lab by Cho- NGINX is running</h1>" > /var/www/html/index.html



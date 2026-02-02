#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx rsync

snap install aws-cli --classic

systemctl enable nginx 
systemctl start nginx

echo "<h1>Cloud Support Lab by Cho- NGINX is running</h1>" > /var/www/html/index.html



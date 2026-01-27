#!/bin/bash
set -eux

apt-get update -y
apt-get install -y nginx

snap install aws-cli --classic

systemctl enable nginx 
systemctl start nginx

echo "<h1>Cloud Support Lab by Cho- NGINX is running</h1>" > /var/www/html/index.html

# Test S3 access using the instance role creds (no keys stored)
echo "hello from cloud lab instance" > /tmp/hello.txt
aws s3 cp /tmp/hello.txt ${my_s3_bucket}/hello_from_instance.txt
aws s3 ls ${my_s3_bucket}/

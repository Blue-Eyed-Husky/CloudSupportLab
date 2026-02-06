#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

REGION="us-west-1"

apt-get update -y
apt-get install -y nginx rsync curl ca-certificates

# Ensure log file exists for collection
touch /var/log/deploy.log
chmod 644 /var/log/deploy.log

# Start NGINX so logs exist
systemctl enable nginx
systemctl start nginx
echo "<h1>Cloud Support Lab by Cho — NGINX is running</h1>" > /var/www/html/index.html

# Install CloudWatch Agent (Ubuntu amd64) from AWS (NOT apt)
curl -fSL "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb" \
  -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

# Write agent config
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "/cloudlab/nginx/access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/error.log",  "log_group_name": "/cloudlab/nginx/error",  "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/deploy.log",       "log_group_name": "/cloudlab/deploy",       "log_stream_name": "{instance_id}" }
        ]
      }
    }
  }
}
JSON

# Start + enable agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl enable amazon-cloudwatch-agent

# Evidence markers (create log events immediately)
echo "$(date -Is) user_data complete: nginx+cloudwatch-agent configured" | tee -a /var/log/deploy.log
curl -s localhost >/dev/null || true

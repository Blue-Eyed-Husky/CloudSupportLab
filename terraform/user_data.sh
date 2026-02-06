#!/bin/bash
set -euo pipefail

CW_DEB_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
CW_JSON="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

apt-get update -y
apt-get install -y nginx rsync curl ca-certificates snapd

apt-get install -y awscli --classic

# SSM Agent (snap)
snap install amazon-ssm-agent --classic || true
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# Deploy evidence log
touch /var/log/deploy.log
chmod 644 /var/log/deploy.log

# NGINX
systemctl enable --now nginx
echo "<h1>Cloud Support Lab by Cho — NGINX is running</h1>" > /var/www/html/index.html
curl -s localhost >/dev/null || true

# CloudWatch Agent (download .deb, install, configure)
curl -fsSL "$CW_DEB_URL" -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || (apt-get -f install -y && dpkg -i /tmp/amazon-cloudwatch-agent.deb)

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > "$CW_JSON" <<'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "/cloud_lab/nginx/access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/error.log",  "log_group_name": "/cloud_lab/nginx/error",  "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/deploy.log",       "log_group_name": "/cloud_lab/deploy",       "log_stream_name": "{instance_id}" }
        ]
      }
    }
  }
}
JSON

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:"$CW_JSON" -s

systemctl enable amazon-cloudwatch-agent

echo "Deploy test $(date -u +%FT%TZ) user_data complete" >> /var/log/deploy.log

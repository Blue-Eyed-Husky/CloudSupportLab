#!/bin/bash
set -euo pipefail

LOG_DEPLOY="/var/log/deploy.log"
CW_DEB_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
CW_JSON="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

echo "BOOT_START: $(date -Is)" | tee -a "$LOG_DEPLOY"

############################################
# Base packages (needed by your SSM deploy)
############################################
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  nginx \
  unzip \
  curl \
  ca-certificates \
  jq \
  rsync

############################################
# AWS CLI v2 (required by your deploy.yml remote script)
# Your deploy script calls: aws s3 cp s3://bucket/key artifact.zip
############################################
if ! command -v aws >/dev/null 2>&1; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

echo "AWS_CLI_VERSION: $(aws --version 2>&1)" | tee -a "$LOG_DEPLOY"

############################################
# SSM Agent (best practice: install official deb)
# This makes the instance show up in Systems Manager reliably.
############################################
if ! systemctl is-active --quiet amazon-ssm-agent; then
  TMP_SSM_DEB="/tmp/amazon-ssm-agent.deb"
  curl -fsSL "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb" -o "$TMP_SSM_DEB"
  dpkg -i "$TMP_SSM_DEB" || apt-get -f install -y
  systemctl enable --now amazon-ssm-agent
fi

echo "SSM_STATUS: $(systemctl is-active amazon-ssm-agent || true)" | tee -a "$LOG_DEPLOY"

############################################
# NGINX
# Your deploy.yml copies into /var/www/html and restarts nginx.
############################################
systemctl enable --now nginx

mkdir -p /var/www/html
cat > /var/www/html/index.html <<'HTML'
<h1>Cloud Support Lab by Cho — NGINX is running</h1>
<p>If you see this, user_data ran and nginx is serving /var/www/html</p>
HTML

# Touch deploy evidence log (CloudWatch will ship this)
touch "$LOG_DEPLOY"
chmod 644 "$LOG_DEPLOY"

# Quick local smoke check (won’t fail boot if nginx needs a moment)
curl -sSf localhost >/dev/null 2>&1 || true
echo "NGINX_STATUS: $(systemctl is-active nginx || true)" | tee -a "$LOG_DEPLOY"

############################################
# CloudWatch Agent (logs -> your Terraform log groups)
############################################
curl -fsSL "$CW_DEB_URL" -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || (apt-get -f install -y && dpkg -i /tmp/amazon-cloudwatch-agent.deb)

mkdir -p "$(dirname "$CW_JSON")"

cat > "$CW_JSON" <<'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/cloud_lab/nginx/access",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/cloud_lab/nginx/error",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/deploy.log",
            "log_group_name": "/cloud_lab/deploy",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
JSON

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:"$CW_JSON" -s

systemctl enable amazon-cloudwatch-agent

echo "CW_AGENT_STATUS: $(systemctl is-active amazon-cloudwatch-agent || true)" | tee -a "$LOG_DEPLOY"

echo "BOOT_DONE: $(date -Is)" | tee -a "$LOG_DEPLOY"

#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y nginx rsync wget ca-certificates curl

# Ensure deploy log exists (we ship this)
touch /var/log/deploy.log
chmod 644 /var/log/deploy.log

# --- SSM Agent (snap) ---
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl start  snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# --- Start NGINX early so logs exist ---
systemctl enable nginx
systemctl start nginx

# --- Install CloudWatch Agent (official AWS installer) ---
cd /tmp
curl -fsSL https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/install.sh -o install.sh
bash install.sh

# --- Write CloudWatch Agent config ---
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/cloudsupportlab/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/cloudsupportlab/nginx/error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/deploy.log",
            "log_group_name": "/cloudsupportlab/deploy",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
JSON

# --- Start + enable CloudWatch Agent ---
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl enable amazon-cloudwatch-agent

# Optional: AWS CLI (not required for CW agent)
snap install aws-cli --classic || true

# Page + boot marker
echo "<h1>Cloud Support Lab by Cho — NGINX is running</h1>" > /var/www/html/index.html
echo "$(date -Is) user_data complete: nginx+ssm+cloudwatch configured" | tee -a /var/log/deploy.log

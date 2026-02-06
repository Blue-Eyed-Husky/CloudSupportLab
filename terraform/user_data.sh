#!/bin/sh
set -eu

# Log everything (critical for debugging)
exec > /var/log/user-data.log 2>&1

CW_DEB_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
CW_DEB_PATH="/tmp/amazon-cloudwatch-agent.deb"
CW_JSON_PATH="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

echo "=== user-data start ==="
date -u

# Wait for apt/dpkg locks (cloud-init sometimes races apt on first boot)
i=0
while [ $i -lt 60 ]; do
  if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
    echo "dpkg/apt lock present... waiting ($i)"
    sleep 2
    i=$((i+1))
  else
    break
  fi
done

echo "=== apt update/install prereqs ==="
apt-get update -y
apt-get install -y nginx curl ca-certificates

# Ensure deploy log exists (we ship this)
touch /var/log/deploy.log
chmod 644 /var/log/deploy.log

# Start nginx early so logs exist
systemctl enable nginx
systemctl start nginx
echo "<h1>Cloud Support Lab by Cho — NGINX is running</h1>" > /var/www/html/index.html

# Generate a log line
curl -s localhost >/dev/null 2>&1 || true

echo "=== download cloudwatch agent deb ==="
rm -f "$CW_DEB_PATH"
curl -fSL "$CW_DEB_URL" -o "$CW_DEB_PATH"
ls -lh "$CW_DEB_PATH"
file "$CW_DEB_PATH" || true

echo "=== install cloudwatch agent deb ==="
dpkg -i -E "$CW_DEB_PATH" || (apt-get -f install -y && dpkg -i -E "$CW_DEB_PATH")

# Hard check: binary must exist
if [ ! -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then
  echo "FATAL: amazon-cloudwatch-agent-ctl not found after install"
  ls -R /opt/aws/amazon-cloudwatch-agent || true
  exit 1
fi

echo "=== write cw agent config ==="
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > "$CW_JSON_PATH" <<'JSON'
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

echo "=== start cw agent ==="
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:"$CW_JSON_PATH" \
  -s

systemctl enable amazon-cloudwatch-agent || true
systemctl restart amazon-cloudwatch-agent || true

echo "=== evidence markers ==="
echo "Deploy test $(date -u +%FT%TZ) user_data complete" >> /var/log/deploy.log
curl -s localhost >/dev/null 2>&1 || true

echo "=== cw agent service status ==="
systemctl status amazon-cloudwatch-agent --no-pager || true

echo "=== cw agent log tail ==="
tail -n 80 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log || true

echo "=== user-data end ==="
date -u

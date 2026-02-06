## Incident 006 - CloudWatch Logs failures (Bootsrap Failed)

## Summary
CloudWatch Logs were not being shipped from the EC2 instance because the CloudWatch Agent was never installed. The issue was caused by an early exit in the EC2 `user_data` bootstrap script during the SSM agent setup. A package conflict between a snap-installed SSM agent and a `.deb` installation caused the script to terminate before reaching the CloudWatch Agent installation step.

As a result, the instance came online without log shipping enabled.

## Impact 
No NGINX access, error, or deploy logs were available in CloudWatch.
No deployment audit trail during this period.
**Severity: Low** — the application itself was functional; only observability was affected.

## Symptoms
- CloudWatch log groups were successfully created via Terraform:
  - `/cloud_lab/nginx/access`
  - `/cloud_lab/nginx/error`
  - `/cloud_lab/deploy`
No log streams or events appeared in any of the log groups.
On the instance:
-  ```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager

## Detection and Verification
The issue was identified by checking cloud-init and boostrap output on the instance: 
    '/var/log/cloud-init-output.log' showed the 'user_data' script started but did not complete 
    Log showed SSM installation errors indicating a packaging conflict

## Root Cause
'user_data.sh' attempted to install and enable the SSM agent using a '.deb' package and service that was already installed via snap that uses a different service unit. Due to this the '.deb' installation failed and the script exited early due to 'set -e' prevent further isntallations including CloudWatch agent installation and configuration.

## Resolution
Modified the 'user_data.sh' SSM section to detect snap unit existence and enable that service if present
Ensure failures in the SSM section does not halt the entire bootstrap
Recreated the EC2 isntance to run 'user_data.sh' cleanly
Verified CloudWatch Agent installed and shipping logs: 
    confirmed with sudo systemctl status amazon-cloudwatch-agent --no-pager
    confirmed streams/events appeared in: /cloud_lab/nginx/access, cloud_lab/nginx/errors, and cloud_lab/depoy

## Preventative Actions
Add explicit bootstrap logging checkpoints to quickly identifiy where bootstrap script stops
Add deploy "evidence lines" writtent to '/var/log/deploy.log' during every deployment so CloudWatch becomes a deployment audit trail

## Lessons learned
'set -euo pipefail' is nice but requires careful handling 
Cloud-init logs are a quick way to diagnose bootstrap failures.
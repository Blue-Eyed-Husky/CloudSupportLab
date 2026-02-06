## Incident 006 - CloudWatch Logs failures (Bootsrap Failed)

## Summary
CloudWatch was not installing into the instance due to early termination in the EC2 user_data boostrap script that exited early during the SSM agent installation due to a snap vs deb package conflict. Since user_data termianted before CloudWatch agent install step, the agen never installed and logs were never shipped. 

## Impact 
No deploy evidence logs in CloudWatch
Severity: low. All other environments were funcational with the lack of logs 

## Symptoms
CLoudWatch log groups were created via terraform but 
    no logs streams appeared in any of the log groups (/cloud_lab/nginx/access, cloud_lab/nginx/error, cloud_lab/deploy)
In SSM, sudo systemctl status amazon-cloudwatch-agent --no-pager -> service not found

## Detection and Verification
The issue was identified by checking cloud-init and boostrap output on the instance: 
    '/var/log/cloud-init-output.log' showed the 'user_data' script started but did not complete 
    Log showed SSM installation errors indicating a packaging conflict

## Root Cause
'user_data.sh' attempted to isntall and enable the SSM agent using a '.deb' package and service that was already installed via snap that uses a different service unit. Du eto this the '.deb' installation failed and the script exited early due to 'set -e' prevent further isntallations including CloudWatch agent installation and configuration.

## Resolution
Modified the 'user_data.sh' SSM seciton to detect snap unit existence and enable that service if present
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
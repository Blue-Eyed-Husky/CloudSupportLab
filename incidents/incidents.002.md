## Failure Scenario 2 - HTTP Failure



Summary: NGINX site became unreachable over HTTP because the Security Group inbound rule allowing TCP/80 was removed via terraform.



Symptoms: 
 http://<public-ip> failed (browser "site can't be reached")
 curl -v http://<public-ip> -> timed out / no response

Impact: Low, as sole instance user could not reach HTTP.

Diagnosis: 
 Confirmed the instance was running and reachable via SSH.
 Verified NGINX was installed/running (e.g., nginx -v and/or systemctl status nginx).
 Since SSH worked but HTTP timed out, suspected L4 filtering on port 80 (SG/NACL) rather than instance state or NGINX process.



Evidence: 
 Accessing AWS console -> EC2 console -> Security Group -> ingress for HTTP was removed



Root Cause:
 Security Group inbound filtering dropped inbound TCP/80 packets at the instance ENI, preventing traffic from reaching the OS/NGINX, even though the instance and NGINX were healthy.

Fix: 
 Added the ingress rule to HTTP and terraform apply.

Validation:
 Following adding the ingress rule, I was able to access NGINX site via http:/<public ip>


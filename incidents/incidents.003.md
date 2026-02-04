## Failure Scenario 3 - NGINX failure 

# Summary
User attempted to access NGINX with HTTP://<public-ip>. User received 
"can't connect to the Server"

# Symptoms
User browser "can't connect to the Server"

# Diagnosis
SSH into the system and sudo systemctl status nginx -> inactive (dead)

# Root Cause
Browser unable to access nginx site as the appilcation is inactive/dead.

# Fix
Re-enable application nginx with sudo systemctl start nginx 

# Validation
sudo systemctl status nginx -> nginx active (running)
browser -> http://<public-ip>

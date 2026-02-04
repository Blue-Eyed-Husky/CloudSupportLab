# Failure Scenario 5 - CI/CD Deploy Failure -> Artifact-Based redesign using SSM 

## Summary
A CI/CD pipeline was built using GitHub Actions to deploy application updates to an EC2 instance via AWS Systems Manager (SSM) Run Command.
The initial deployment approach attempted to run 'git pull' inside '/var/www/html' on the EC2 instance. This failed because the directory was not a Git repository. Further attempts exposed multiple architectural flaws in the deployment strategy, including:
    incorrect assumptions about how code should exist on the server
    Quoting and shell exsecution issues between GitHub Actions _. AWS CLI -> SSM -> Bash
    Misalignment between repository structure and NGINX document root
    Confusion between SSH-style deployments and modern SSM-based management
The deployment method was redesigned to follow a proper artifact-based CI/CD pattern:

> GitHub -> S3 Artifact -> SSM Run Command -> EC2 -> NGINX

This eliminated the need for Git on the server, removed credential management from EC2, and created a reproducible, auditable deployment process

---

## Original Deployment Attempt

The pipeline attempted: git push -> GitHub Actions -> SSM -> git pull -> restart nginx

# Failure
/var/www/html was not a git clone
EC2 did not have GitHub credentials
The server should not be responsible for pulling source code

# Symptoms
SSM rum Command succeeded but 'git pull' failed
NGINX returned '403 forbidden'
Files deployed to incorrect directory structure (site/ folder not aligned with nginx root)
Mulitple failures related to quoting, shell parsing, and parameter formatting when passing scripts through SSM

# Root Cause
The deployment strategy assumed a traditional SSH + git server workflow. 
Artifacts shoudl be delivered to the server, not pulled from source control
SSM shoudl be used for remote execution, not SSH

# Resolution
The deployment pipeline was redesigned to: 
    Package the site as a zip artifact in GitHub Actions
    Upload the artifact to a private s3 bucket
    Use SSM Run Command to:
        Download the artifact from S3
        Unzip into a temporary directory
        Copy only the 'site/' folder into '/var/www/html'
        Restart nginx
This ensured:
    No git credentials on EC2
    No SSH usage
    Fully IAM-controlled deployment
    Clean separation of build vs deploy responsibilities

## Final Deployment Flow
git push -> GitHub Actions runner -> zip artifact -> upload to private S3 -> SSM Run Command -> EC2 downloads artifact -> site files placed correctly for NGINX -> nginx restart

# Lesson learned
'git pull' is an anti-pattern for cloud deployments
SSM Run Command requires careful handling of shell quoting and JSON paramters
Artifact-based deployment is more secure and reliable
Directory structure must align wiht application server configuration
SSM is a superior alternative to SSH for server management

## Preventative measueres
Adopt artifact-based deployments for all future projects
Avoid server-side source control operations
Verify deploy paths match application root
Use SSM for all remote execution instead of SSH
## Incident 005 — CI/CD Deploy Failure Leading to Artifact-Based Redesign Using SSM

## Summary
A CI/CD pipeline was initially built using GitHub Actions to deploy application updates to an EC2 instance via AWS Systems Manager (SSM) Run Command. The original deployment strategy attempted to run `git pull` directly on the EC2 instance within `/var/www/html`.

This approach failed because the directory was not a Git repository and the instance was not designed to manage source control or GitHub credentials. Further troubleshooting exposed broader architectural issues, including incorrect assumptions about server responsibility, misalignment between repository structure and the NGINX document root, and complications caused by passing shell commands through multiple execution layers.

As a result, the deployment strategy was redesigned to follow a proper artifact-based CI/CD model:

**GitHub Actions → S3 Artifact → SSM Run Command → EC2 → NGINX**

This redesign eliminated the need for Git on the server, removed credential management from EC2, and resulted in a reproducible and auditable deployment process.

---

## Original Deployment Attempt
The initial pipeline followed this flow:

`git push → GitHub Actions → SSM Run Command → git pull on EC2 → nginx restart`

---

## Failure
- `/var/www/html` was not a Git repository.
- The EC2 instance had no GitHub credentials and should not have them.
- The server was incorrectly responsible for pulling source code.
- Repository structure did not align with the NGINX document root.

---

## Symptoms
- SSM Run Command executed successfully, but `git pull` failed.
- NGINX returned `403 Forbidden` errors.
- Files were deployed into incorrect directory paths (e.g., `site/` not matching the configured NGINX root).
- Multiple failures occurred due to quoting and shell parsing issues when passing commands from:
  - GitHub Actions
  - AWS CLI
  - SSM Run Command
  - Bash on the EC2 instance

---

## Root Cause
The deployment strategy assumed a traditional SSH-based workflow where servers manage source control and pull code directly from GitHub. This conflicted with modern cloud deployment best practices.

In a cloud environment:
- Servers should **receive artifacts**, not pull source code.
- CI systems should handle builds and packaging.
- SSM should be used for controlled remote execution, not as a replacement for SSH-based workflows.

---

## Resolution
The deployment pipeline was redesigned to use an artifact-based approach:

- GitHub Actions packages the site into a ZIP artifact.
- The artifact is uploaded to a private S3 bucket.
- SSM Run Command is used to:
  - Download the artifact from S3
  - Extract it into a temporary directory
  - Copy only the required `site/` content into `/var/www/html`
  - Restart NGINX

This ensured:
- No Git or GitHub credentials on the EC2 instance
- No SSH access required
- IAM-controlled, auditable deployments
- Clear separation between build and deploy responsibilities

---

## Final Deployment Flow
`git push → GitHub Actions runner → build ZIP artifact → upload to private S3 → SSM Run Command → EC2 downloads artifact → site files placed correctly → nginx restart`

---

## Lessons Learned
- Using `git pull` on production servers is an anti-pattern for cloud deployments.
- Artifact-based deployments are more secure, repeatable, and auditable.
- SSM Run Command requires careful handling of shell quoting and parameter formatting.
- Repository structure must align with application server configuration.
- SSM is a safer and more controlled alternative to SSH for server management.

---

## Preventative Measures
- Use artifact-based deployments for all future projects.
- Avoid server-side source control operations.
- Validate deploy paths against application document roots.
- Standardize on SSM for all remote execution instead of SSH.

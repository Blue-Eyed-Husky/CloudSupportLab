## Failure Scenario 007 — Blue/Green Static Site Deployment via Symlink

## Summary
A Blue/Green deployment pattern was implemented for a static NGINX site by configuring NGINX to serve content from `/var/www/current`, which points to versioned release directories under `/var/www/releases`. Deployments create new release directories and only switch production traffic by flipping the symlink after validation.

A controlled failure was intentionally introduced during deployment. Because the failure occurred before the symlink was updated, production traffic continued to serve the last known good release, and no outage occurred. The deployment was then corrected and successfully rolled forward.

---

## Symptoms
- A deployment executed via SSM Run Command failed.
- The new release directory was missing a required file (`index.html`).
- The deployment exited with a non-zero status.
- Production traffic continued serving the previous release without interruption.

---

## Root Cause
An intentional bad deployment artifact was created that lacked required site content, causing the deployment to fail before the symlink switch occurred.

---

## Resolution
- Verified that `/var/www/current` still pointed to the previous release.
- Confirmed NGINX continued serving the last known good deployment.
- Executed a corrected deployment via SSM Run Command.
- Successfully flipped the symlink to the new release and reloaded NGINX.

---

## Lessons Learned
- Blue/Green deployments using symlinks prevent partial or broken deployments from impacting production traffic.
- Gated deployments ensure failures occur before traffic is switched.
- SSM Run Command provides auditable, repeatable deployment execution with clear success and failure signals.
- SSM Session Manager is better suited for interactive troubleshooting, while Run Command is preferable for operational changes.

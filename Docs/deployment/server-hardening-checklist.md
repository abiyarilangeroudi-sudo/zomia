# Server Hardening Checklist

Date: 2026-06-25

This checklist prepares the Hetzner private pilot server before installing Zomia.
It is intentionally written as a controlled gate list, not as an automatic script.

Target server:

```text
Provider: Hetzner
Plan: ubuntu-4gb-nbg1-1
Location: Nuremberg, Germany
IPv4: 178.104.74.107
IPv6: 2a01:4f8:1c19:49f0::/64
OS: Ubuntu 24.04
```

## Goal

Prepare a safe baseline for a real-customer private pilot.

This checklist must be completed before installing the Zomia application stack.

## Out Of Scope

- Installing Zomia backend.
- Installing Flutter web build.
- Running Alembic migrations.
- Creating production secrets.
- Configuring real domain DNS.
- Enabling customer traffic.

## Phase 1: Access Baseline

- [ ] Confirm SSH access works.
- [ ] Confirm the server is Ubuntu 24.04.
- [ ] Confirm the server timezone.
- [ ] Confirm server hostname.
- [ ] Confirm current root access method.
- [ ] Add a dedicated non-root admin/deployment user.
- [ ] Confirm the deployment user can use sudo.
- [ ] Confirm SSH key login works for the deployment user.
- [ ] Keep root login available only until deployment-user access is verified.

Gate:

- Do not disable root/password access until deployment-user SSH key access has been tested in a separate terminal session.

## Phase 2: SSH Hardening

- [ ] Disable SSH password authentication after key access is verified.
- [ ] Disable direct root SSH login after deployment-user access is verified.
- [ ] Keep SSH on port 22 for now unless there is a clear reason to change it.
- [ ] Confirm SSH still works after changes.
- [ ] Document the final SSH access method outside Git.

Gate:

- Do not continue if SSH access is uncertain.

## Phase 3: System Updates

- [ ] Update package index.
- [ ] Apply security updates.
- [ ] Reboot if the server requires it.
- [ ] Confirm SSH works after reboot.
- [ ] Confirm system time and timezone after reboot.

Gate:

- Do not install application dependencies before the system baseline is updated.

## Phase 4: Firewall Baseline

Allowed public ports for pilot:

```text
22/tcp  SSH
80/tcp  HTTP
443/tcp HTTPS
```

Required rules:

- [ ] Enable firewall.
- [ ] Allow SSH.
- [ ] Allow HTTP.
- [ ] Allow HTTPS.
- [ ] Deny all other inbound traffic by default.
- [ ] Confirm PostgreSQL port `5432` is not publicly reachable.
- [ ] Confirm backend app port is not publicly reachable.

Gate:

- Do not enable firewall rules that could lock out SSH.

## Phase 5: Intrusion And Abuse Baseline

- [ ] Install and enable a basic SSH brute-force protection tool such as fail2ban.
- [ ] Confirm SSH jail is active.
- [ ] Confirm system logs are available.
- [ ] Decide where operational notes for blocked IPs and access issues will live.

Gate:

- This does not replace proper password/key and firewall hardening.

## Phase 6: Application Users And Directories

Recommended users:

```text
zomia
```

Recommended directories:

```text
/opt/zomia/backend
/opt/zomia/env
/var/www/zomia/releases
/var/www/zomia/current
/var/backups/zomia
/var/log/zomia
```

Checklist:

- [ ] Create application user.
- [ ] Create backend directory.
- [ ] Create protected env directory.
- [ ] Create frontend releases directory.
- [ ] Create frontend current symlink target plan.
- [ ] Create backup directory.
- [ ] Create application log directory if needed.
- [ ] Assign ownership intentionally.
- [ ] Ensure secrets are readable only by the required user/group.

Gate:

- Do not place secrets inside the Git working tree.

## Phase 7: Database Isolation Baseline

If PostgreSQL starts on the same server for private pilot:

- [ ] Bind PostgreSQL to localhost only.
- [ ] Use a dedicated database user for Zomia.
- [ ] Use a strong database password.
- [ ] Do not expose `5432` publicly.
- [ ] Confirm local backend can reach PostgreSQL.
- [ ] Confirm remote public access to PostgreSQL is blocked.

Gate:

- Same-server PostgreSQL is not production-ready until backup and restore are tested.

## Phase 8: Backup Baseline

Before real customer usage:

- [ ] Define backup directory.
- [ ] Define daily backup command.
- [ ] Define backup retention.
- [ ] Run one manual backup.
- [ ] Restore that backup into a separate test database.
- [ ] Document restore result.

Gate:

- Do not allow real customer traffic until restore has been tested.

## Phase 9: Nginx And HTTPS Prerequisites

Before installing the app:

- [ ] Choose domain.
- [ ] Point DNS to server IPv4.
- [ ] Decide IPv6 DNS usage.
- [ ] Install Nginx.
- [ ] Prepare HTTP site config.
- [ ] Prepare HTTPS plan with Certbot or equivalent.
- [ ] Confirm TLS certificate can be renewed.

Gate:

- Customer registration and login must not be exposed over plain HTTP.

## Phase 10: Pre-Application Verification

Before installing Zomia:

- [ ] SSH key login works.
- [ ] Password SSH is disabled or explicitly accepted as a temporary risk.
- [ ] Root SSH is disabled or explicitly accepted as a temporary risk.
- [ ] Firewall allows only required public ports.
- [ ] Server is updated.
- [ ] Nginx is ready or planned.
- [ ] PostgreSQL exposure is controlled.
- [ ] Backup location exists.
- [ ] Restore test is planned or complete.
- [ ] Deployment directories exist.
- [ ] Secrets location exists and is outside Git.

## Current Status

F15.2 is documentation-only.

No server command has been run by this checklist yet.

Next step after approval:

```text
Use this checklist to perform server baseline setup step by step.
```

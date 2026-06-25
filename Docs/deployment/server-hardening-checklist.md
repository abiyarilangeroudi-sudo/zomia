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

- [x] Confirm SSH access works.
- [x] Confirm the server is Ubuntu 24.04.
- [x] Confirm the server timezone.
- [x] Confirm server hostname.
- [x] Confirm current root access method.
- [x] Add a dedicated non-root admin/deployment user.
- [x] Confirm the deployment user can use sudo.
- [x] Confirm SSH key login works for the deployment user.
- [x] Keep root login available only until deployment-user access is verified.

Gate:

- Do not disable root/password access until deployment-user SSH key access has been tested in a separate terminal session.

## Phase 2: SSH Hardening

- [x] Disable SSH password authentication after key access is verified.
- [x] Disable direct root SSH login after deployment-user access is verified.
- [x] Keep SSH on port 22 for now unless there is a clear reason to change it.
- [x] Confirm SSH still works after changes.
- [x] Document the final SSH access method outside Git.

Gate:

- Do not continue if SSH access is uncertain.

## Phase 3: System Updates

- [x] Update package index.
- [x] Apply security updates.
- [x] Reboot if the server requires it.
- [x] Confirm SSH works after reboot.
- [x] Confirm system time and timezone after reboot.

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

- [x] Enable firewall.
- [x] Allow SSH.
- [x] Allow HTTP.
- [x] Allow HTTPS.
- [x] Deny all other inbound traffic by default.
- [x] Confirm PostgreSQL port `5432` is not publicly reachable after PostgreSQL is installed.
- [ ] Confirm backend app port is not publicly reachable after backend is installed.

Gate:

- Do not enable firewall rules that could lock out SSH.

## Phase 5: Intrusion And Abuse Baseline

- [x] Install and enable a basic SSH brute-force protection tool such as fail2ban.
- [x] Confirm SSH jail is active.
- [x] Confirm system logs are available.
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

- [x] Create application user.
- [x] Create backend directory.
- [x] Create protected env directory.
- [x] Create frontend releases directory.
- [x] Create frontend current symlink target plan.
- [x] Create backup directory.
- [x] Create application log directory if needed.
- [x] Assign ownership intentionally.
- [x] Ensure secrets are readable only by the required user/group.

Gate:

- Do not place secrets inside the Git working tree.

## Phase 7: Database Isolation Baseline

If PostgreSQL starts on the same server for private pilot:

- [x] Bind PostgreSQL to localhost only.
- [x] Use a dedicated database user for Zomia.
- [x] Use a strong database password.
- [x] Do not expose `5432` publicly.
- [x] Confirm local backend can reach PostgreSQL.
- [x] Confirm remote public access to PostgreSQL is blocked.

Gate:

- Same-server PostgreSQL is not production-ready until backup and restore are tested.

## Phase 8: Backup Baseline

Before real customer usage:

- [x] Define backup directory.
- [x] Define daily backup command.
- [x] Define backup retention.
- [x] Run one manual backup.
- [x] Restore that backup into a separate test database.
- [x] Document restore result.

Gate:

- Do not allow real customer traffic until restore has been tested.

## Phase 9: Nginx And HTTPS Prerequisites

Before installing the app:

- [x] Choose domain.
- [x] Point DNS to server IPv4.
- [x] Decide IPv6 DNS usage.
- [x] Install Nginx.
- [x] Prepare HTTP site config.
- [x] Prepare HTTPS plan with Certbot or equivalent.
- [x] Confirm TLS certificate can be renewed.
- [x] Confirm sensitive paths such as `.env`, config files, secret files, and backup files do not fall through to the frontend app.

Gate:

- Customer registration and login must not be exposed over plain HTTP.

## Phase 10: Pre-Application Verification

Before installing Zomia:

- [x] SSH key login works.
- [x] Password SSH is disabled or explicitly accepted as a temporary risk.
- [x] Root SSH is disabled or explicitly accepted as a temporary risk.
- [x] Firewall allows only required public ports.
- [x] Server is updated.
- [x] Nginx is ready.
- [x] PostgreSQL exposure is controlled.
- [x] Backup location exists.
- [x] Restore test is planned or complete.
- [x] Deployment directories exist.
- [x] Secrets location exists and is outside Git.

## Current Status

F15.2 server baseline is partially applied.

Completed:

- Server boots Ubuntu 24.04.
- SSH key access works with deployment user `delopram`.
- Direct root SSH login is disabled.
- SSH password authentication is disabled.
- `delopram` has passwordless sudo.
- Timezone is `Europe/Berlin`.
- System updates were applied and the server was rebooted.
- UFW is active and allows only `22/tcp`, `80/tcp`, and `443/tcp`.
- fail2ban is active with the `sshd` jail.
- Application user `zomia` exists.
- Deployment user `delopram` is a member of the `zomia` group.
- Base directories exist:
  - `/opt/zomia/backend`
  - `/opt/zomia/env`
  - `/var/www/zomia/releases`
  - `/var/backups/zomia`
  - `/var/log/zomia`
- `/var/www/zomia/current` is intentionally pending until the first frontend release is published.
- PostgreSQL 16.14 is installed and active.
- PostgreSQL listens only on `127.0.0.1:5432` and `[::1]:5432`.
- Database `zomia` exists.
- Database user `zomia_app` exists.
- `DATABASE_URL` is stored in `/opt/zomia/env/backend.env`.
- `/opt/zomia/env/backend.env` is owned by `delopram:zomia` with mode `640`.
- UFW does not expose port `5432`.
- Manual PostgreSQL backup directory exists at `/var/backups/zomia/postgresql`.
- Manual PostgreSQL backup/restore test passed using a temporary database.
- Restore test database was removed after verification.
- Daily PostgreSQL backup script exists at `/opt/zomia/backend/scripts/backup_postgres.sh`.
- Cron job exists at `/etc/cron.d/zomia-postgres-backup`.
- Daily backup schedule is `03:15 Europe/Berlin`.
- Backup retention is 14 days.
- Cron service is active and enabled.
- Backup files are stored with mode `640` and group `zomia`.
- Domain `zomia.eu` is selected for the private pilot.
- DNS points `zomia.eu` and `www.zomia.eu` to the server IPv4 and IPv6 addresses.
- Nginx is installed and active.
- A bootstrap static site is served from `/var/www/zomia/current`.
- Let's Encrypt HTTPS is active for `zomia.eu` and `www.zomia.eu`.
- HTTP redirects to HTTPS.
- Sensitive paths are blocked at Nginx before frontend fallback handling.
- External checks confirmed:
  - `https://zomia.eu` over IPv4 returns the bootstrap site.
  - `https://www.zomia.eu` returns the bootstrap site.
  - Direct IPv6 to `2a01:4f8:1c19:49f0::1` returns the bootstrap site.
  - Sensitive probes such as `/.env`, `/config/default.json`, `/secrets.yaml`, `/.aws/credentials`, and `/terraform.tfstate` return `404`.

Pending before installing Zomia:

- Clear local DNS cache if a workstation still resolves `zomia.eu` to an older IPv6 address.

Next step after approval:

```text
Run manual production smoke QA.
```

## Application Stack Install

F15.4 was applied on 2026-06-25.

Release:

```text
Release id: 20260625201754
Backend current: /opt/zomia/backend/releases/20260625201754
Frontend current: /var/www/zomia/releases/20260625201754
```

Completed:

- Backend source was deployed without local development `.venv` or cache files.
- Backend production virtualenv was created inside the backend release.
- Runtime dependencies were installed from `backend/pyproject.toml`.
- `zomia-backend.service` was created and enabled.
- Backend runs as user/group `zomia`.
- Backend listens only on `127.0.0.1:8000`.
- Alembic migrations were applied to `0011_staff_invitations (head)`.
- Flutter web was built with `API_BASE_URL=https://zomia.eu/api/v1`.
- Frontend release was published to `/var/www/zomia/releases/20260625201754`.
- `/var/www/zomia/current` points to the release above.
- Nginx proxies `/api/` and `/health` to the backend.
- Nginx serves Flutter web for all other frontend routes.
- Nginx sensitive-path blocking was kept before frontend fallback handling.
- The Nginx `.json` block was corrected so required Flutter assets such as `manifest.json` and `version.json` remain reachable.
- SMTP host was corrected to `smtp.zoho.eu`.
- SMTP login/send check passed with the configured Zomia sender.

Verification:

- `https://zomia.eu` returns the Flutter web app.
- `https://www.zomia.eu` returns the Flutter web app.
- `https://zomia.eu/health` returns `{"status":"ok"}`.
- `https://zomia.eu/manifest.json` returns `200`.
- Unknown API route under `/api/v1/` returns backend `404`.
- Sensitive probe `https://zomia.eu/.env` returns `404`.
- Public `http://178.104.74.107:8000/health` is not reachable.
- `nginx`, `postgresql`, and `zomia-backend.service` are active.

## Webapp Subpath

F15.5 was applied on 2026-06-25.

Reason:

- Keep `https://zomia.eu/` available for a future public landing/index page.
- Serve the MVP Flutter web app under `https://zomia.eu/webapp/`.

Completed:

- Flutter web was rebuilt with `--base-href=/webapp/`.
- Flutter web still uses `API_BASE_URL=https://zomia.eu/api/v1`.
- New frontend release was published to `/var/www/zomia/releases/20260625203255`.
- `/var/www/zomia/webapp` points to `/var/www/zomia/releases/20260625203255`.
- `/var/www/zomia/root/index.html` is a blank root page.
- Nginx serves:
  - `/` from `/var/www/zomia/root`.
  - `/webapp/` from `/var/www/zomia/webapp`.
  - `/api/` and `/health` through the backend proxy.
- Backend `FRONTEND_BASE_URL` is now `https://zomia.eu/webapp` so staff invitation and account links point to the app subpath.

Verification:

- `https://zomia.eu/` returns a blank root HTML page.
- `https://zomia.eu/webapp` redirects to `https://zomia.eu/webapp/`.
- `https://zomia.eu/webapp/` returns the Flutter web app.
- `https://zomia.eu/webapp/manifest.json` returns `200`.
- `https://zomia.eu/webapp/main.dart.js` returns `200`.
- `https://zomia.eu/health` returns `200`.
- Unknown API route under `/api/v1/` returns backend `404`.
- Sensitive probes under both `/` and `/webapp/` return `404`.

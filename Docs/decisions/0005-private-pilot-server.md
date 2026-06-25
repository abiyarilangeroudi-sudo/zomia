# 0005: Private Pilot Server

Date: 2026-06-25

## Status

Accepted for F15 planning.

## Context

Zomia is moving from a local MVP to a real-customer private pilot. This is not just a technical demo anymore; customer and business data may be created on the deployed system.

The deployment target must therefore be treated as a production-like pilot, even if the first release is still small.

## Decision

Use the following Hetzner server for the first private pilot:

```text
Provider: Hetzner
Plan: ubuntu-4gb-nbg1-1
Location: Nuremberg, Germany
Country: Germany
Network zone: eu-central
IPv4: 178.104.74.107
IPv6: 2a01:4f8:1c19:49f0::/64
```

For the private pilot:

- Nginx, Flutter web static files, and FastAPI backend will run on this server.
- PostgreSQL may run on this same server only as a private-pilot fallback.
- The preferred later direction remains managed PostgreSQL in an EU/Germany region.

## Required Gates Before Real Customer Usage

- SSH access hardened.
- Non-root deployment user created.
- Firewall configured.
- HTTPS enabled.
- Backend bound to localhost or private interface only.
- PostgreSQL not publicly reachable.
- Production secrets stored outside Git.
- Daily database backup configured.
- Restore procedure tested at least once.
- Minimal legal pages and privacy position reviewed for pilot usage.

## Consequences

- F15 should next prepare server baseline steps before installing the application.
- Backup/restore is no longer optional because real customer data may exist.
- Deployment docs should be written for this server first, while keeping later migration to managed PostgreSQL possible.
- Any shortcut taken for the pilot must be tracked as a production risk.

## Open Follow-Up

- Choose production domain and DNS target.
- Decide whether PostgreSQL starts on the same server for pilot.
- Define exact backup retention.
- Prepare Nginx and Systemd drafts.
- Prepare server hardening checklist.

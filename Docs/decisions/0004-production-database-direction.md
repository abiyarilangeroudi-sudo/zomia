# 0004: Production Database Direction

Date: 2026-06-25

## Status

Accepted for F15 planning.

## Context

Zomia is moving from local MVP validation toward production deployment preparation.

The database stores identity, owner, staff, customer, business, QR, loyalty action, points ledger, campaign, reward, and account lifecycle data. The deployment plan must avoid creating a fragile production setup that becomes hard to migrate later.

## Decision

The preferred production database direction is:

```text
Managed PostgreSQL in an EU/Germany region
```

Same-server PostgreSQL on Ubuntu 24.04 is allowed only as a temporary private-beta fallback.

## Rationale

Managed PostgreSQL is preferred because:

- It reduces operational risk for backups, upgrades, disk reliability, and monitoring.
- It keeps application deployment and database durability separate.
- It is a better fit for a production system storing customer and business data.
- It avoids making the first application server the only recovery point.

Same-server PostgreSQL remains acceptable only when:

- The launch is private beta or very early MVP traffic.
- PostgreSQL is not exposed publicly.
- Automated daily backup exists.
- Manual backup is taken before every migration.
- Restore is tested before launch.
- A future migration to managed PostgreSQL remains possible without schema changes.

## Consequences

- F15 should next choose the actual production database provider/location.
- Backup and restore planning must be written before real deployment.
- The deployment plan should not assume Docker Compose for production.
- Local Docker Compose remains only a development tool.

## Open Follow-Up

- Choose the exact provider and region.
- Define backup retention.
- Define restore test procedure.
- Decide whether staging gets a separate database before first public release.

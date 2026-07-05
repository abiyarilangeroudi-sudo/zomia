# First Private Pilot Onboarding Plan

Date: 2026-06-28

Status: `Ready to run with one real business`

This document defines the smallest safe onboarding path for the first real-customer private pilot.
The goal is to validate the production system with real usage while keeping scope, support, and risk controlled.

## Scope

Start with exactly one real business:

- 1 owner account.
- 1 business.
- 1 staff account.
- 1 customer account.
- 1 mission.
- 1 campaign.
- 1 reward template.

Do not add extra business rules, UI changes, analytics, group campaigns, cross-network campaigns, or automation during the first onboarding session.
Owner Home includes a first setup checklist for the Mission, Reward Template, Campaign, and Staff invitation steps; use it as the in-app guide during the session.

## Pre-Onboarding Checks

Before the session starts, confirm:

- The production data reset has been explicitly requested by the project owner the day before the real customer session.
- A fresh local backup and encrypted off-server backup have been created before the reset.
- Production test data has been fully reset.
- No account is seeded after reset; the first real Business Owner must register through the normal Business Register UI.
- A fresh post-reset baseline backup has been created after the clean database state is confirmed.
- `https://zomia.eu/health` returns `{"status":"ok"}`.
- UptimeRobot monitor for `https://zomia.eu/health` is operational.
- UptimeRobot public status page is reachable: `https://stats.uptimerobot.com/nxgv77u55I`.
- UptimeRobot alert recipient is `info@zomia.eu`.
- Production health-check script recently returned `production_health status=ok`.
- `/docs`, `/redoc`, and `/openapi.json` return `404` in production.
- Public legal pages are reachable:
  - `https://zomia.eu/legal`
  - `https://zomia.eu/legal/privacy`
  - `https://zomia.eu/legal/terms`
  - `https://zomia.eu/legal/business-terms`
  - `https://zomia.eu/legal/cookies`
  - `https://zomia.eu/legal/impressum`
- Latest local PostgreSQL backup exists.
- Latest encrypted off-server backup exists.
- Rollback runbook is available.
- Private-pilot boundaries are accepted:
  - same-server PostgreSQL;
  - manual deployment;
  - draft legal pages;
  - UI polish not final;
  - no new feature changes during onboarding.

## Production Data Reset Decision

Status: `Approved but intentionally paused`

Before the first real customer session, production test data will be fully reset using a controlled runbook:

- Take a fresh local PostgreSQL backup.
- Take a fresh encrypted off-server backup.
- Reset production data.
- Re-apply migrations to the current head.
- Do not seed any account, owner, business, customer, staff, mission, campaign, or reward template.
- Let the first real Business Owner register through the normal UI flow.
- Take a fresh post-reset baseline backup.

This reset must not be executed during ordinary development. It is paused until the project owner explicitly requests it, expected on the day before the first real customer meeting.

## Pre-Private-Pilot Production Data Reset Execution Text

When the project owner explicitly requests the reset, execute the following flow:

- Goal: fully remove production test data before the first real customer onboarding.
- No backend or frontend code changes are part of this reset.
- Before reset:
  - Create a complete local PostgreSQL backup.
  - Create a complete encrypted off-server backup.
  - Record both backup names and timestamps in the operations checklist.
- Reset production database data:
  - Remove all test data.
  - Recreate the schema through the current Alembic migration head.
  - Keep the database in a clean state with no seeded accounts.
- After reset:
  - Do not create any owner, business, customer, staff, mission, campaign, reward template, action, or reward manually.
  - The first real Business Owner registers through the normal Business Register UI.
  - Run the private-pilot smoke checks.
  - Create a fresh post-reset baseline local backup.
  - Create a fresh post-reset baseline encrypted off-server backup.
  - Record the reset result, smoke-check result, and backup names in the operations checklist.

## Recommended Test Business Setup

Use a small, understandable loyalty setup:

- Mission:
  - Name: `Buy Coffee`
  - Points: `1`
- Reward Template:
  - Template name: `Free Coffee`
  - Reward item: `Free coffee`
  - Valid days: `30`
- Campaign:
  - Name: `Coffee Reward`
  - Required points: `5`
  - Start date: onboarding day
  - End date: about 3 months later
  - Repeatable: enabled
  - Completion limit: disabled unless the business explicitly wants a limit

This setup keeps the first real flow easy to explain:

```text
5 coffee purchases -> 1 free coffee reward
```

## Onboarding Flow

Run the session in this order:

1. Owner registers the business account.
2. Owner verifies email.
3. Owner signs in.
4. Owner confirms business information.
5. Owner follows the first setup checklist.
6. Owner creates the mission.
7. Owner creates the reward template.
8. Owner creates the campaign and connects mission plus reward template.
9. Owner invites one staff member.
10. Staff accepts the invitation.
11. Staff signs in.
12. Customer registers.
13. Customer verifies email.
14. Customer signs in and opens QR.
15. Staff scans QR.
16. Staff confirms customer.
17. Staff registers the mission action.
18. Customer campaign progress updates.
19. Repeat action registration until reward is issued.
20. Staff uses the reward with confirmation.
21. Owner checks staff recent actions.

## Pass Criteria

The first private-pilot onboarding is considered passed when:

- Owner registration and login work.
- Business setup is visible to the owner.
- Mission, reward template, and campaign are created successfully.
- Staff invitation and staff login work.
- Customer registration, verification, login, and QR display work.
- Staff can scan customer QR.
- Staff can register an action.
- Customer progress changes after action registration.
- Reward is issued after the campaign threshold is reached.
- Reward can be used once.
- Owner can see relevant staff activity.
- Browser console shows no unexpected `4xx` or `5xx` errors during the tested flow.

## Stop Conditions

Stop the onboarding session and investigate before continuing if:

- Customer actions are registered but points/progress do not change.
- Reward is not issued after the threshold is clearly reached.
- Used rewards remain usable.
- Staff can act on the wrong business or wrong customer.
- Owner sees another business's data.
- Login, verification, or invitation flow repeatedly fails.
- Production logs show repeated new backend errors.
- Backups or health checks are not available before the session.

## Support Notes

During the first real onboarding:

- Keep one person responsible for operating the session.
- Keep one person responsible for observing logs and health.
- Avoid changing production unless a blocking issue appears.
- Prefer recording findings over fixing cosmetic UI issues during the session.
- Treat any data correctness issue as higher priority than UI polish.

## After Onboarding

After the session:

- Record pass/fail result.
- Record any customer-facing confusion.
- Record any owner/staff workflow confusion.
- Check backend logs.
- Check Nginx logs.
- Check external uptime monitor state.
- Confirm next scheduled backup still runs.
- Decide whether to continue with the same business or pause for fixes.

## Current Recommendation

Proceed with the first private pilot only as a controlled session.
Reliability, data correctness, and clear recovery paths are more important than adding new features at this stage.

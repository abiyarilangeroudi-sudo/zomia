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

## Pre-Onboarding Checks

Before the session starts, confirm:

- `https://zomia.eu/health` returns `{"status":"ok"}`.
- External uptime monitor for `https://zomia.eu/health` is operational.
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
5. Owner creates the mission.
6. Owner creates the reward template.
7. Owner creates the campaign and connects mission plus reward template.
8. Owner invites one staff member.
9. Staff accepts the invitation.
10. Staff signs in.
11. Customer registers.
12. Customer verifies email.
13. Customer signs in and opens QR.
14. Staff scans QR.
15. Staff confirms customer.
16. Staff registers the mission action.
17. Customer campaign progress updates.
18. Repeat action registration until reward is issued.
19. Staff uses the reward with confirmation.
20. Owner checks staff recent actions.

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

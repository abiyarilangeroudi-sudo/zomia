# First Private Pilot Onboarding Plan

Date: 2026-07-21

Status: `Ready to onboard the first real business`

This document defines the smallest safe onboarding path for the first real-customer private pilot.
The goal is to validate the production system with real usage while keeping scope, support, and risk controlled. The production reset is complete and the first real Customer account now exists; the next session starts with the first real Business Owner.

## Current Pilot State

- The production data reset completed successfully on 2026-07-09.
- Pre-reset and post-reset local and encrypted off-server backups were created.
- The clean database state and production smoke checks passed after the reset.
- No demo account was seeded after the reset.
- The first real Customer registered through the normal production flow and must be retained.
- The first real Owner, Business, and Staff are not yet recorded as onboarded in this plan.
- Current production deployment details remain tracked in `production-operations-checklist.md`.

## Scope

Start with exactly one real business:

- 1 owner account.
- 1 business.
- 1 staff account.
- 1 existing real customer account.
- 1 mission.
- 1 campaign.
- 1 reward template.

Do not add extra business rules, UI changes, analytics, group campaigns, cross-network campaigns, or automation during the first onboarding session.
Owner Home includes a first setup checklist for the Mission, Reward Template, Campaign, and Staff invitation steps; use it as the in-app guide during the session.

## Pre-Onboarding Checks

Before the session starts, confirm:

- The completed production reset record remains available in `production-operations-checklist.md`.
- The existing real Customer is present and no demo Owner, Business, Staff, Mission, Reward Template, or Campaign has been introduced after the reset.
- The first real Business Owner will register through the normal Business Register UI.
- A recent scheduled local backup and encrypted off-server backup are available.
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

Status: `Completed on 2026-07-09`

The one-time production reset completed on server `178.104.74.107`. Backups, migration replay, empty-state verification, health checks, production smoke checks, and post-reset baseline backups all passed. The local development database was intentionally not reset.

Do not repeat this reset before onboarding the first Business. Production now contains the first real Customer, and the reset runbook remains destructive and approval-gated.

The reset runbook and historical execution record live in:

- `Docs/deployment/production-operations-checklist.md`
- `Docs/deployment/pre-pilot-production-data-reset-runbook.md`

## Recommended Test Business Setup

Use a small, understandable loyalty setup:

- Mission:
  - Name: `Buy Coffee`
  - Points: `1`
- Reward Template:
  - Template type: `Gift`
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
12. The existing real Customer signs in.
13. Customer opens QR.
14. Staff scans QR.
15. Staff confirms customer.
16. Staff registers the mission action.
17. Customer campaign progress updates.
18. Repeat action registration until reward is issued.
19. Staff uses the reward with confirmation.
20. Owner checks recent activity and campaign reporting.

## Pass Criteria

The first private-pilot onboarding is considered passed when:

- Owner registration and login work.
- Business setup is visible to the owner.
- Mission, reward template, and campaign are created successfully.
- Staff invitation and staff login work.
- Existing Customer login and QR display work.
- Staff can scan customer QR.
- Staff can register an action.
- Customer progress changes after action registration.
- Reward is issued after the campaign threshold is reached.
- Reward can be used once.
- Owner can see relevant staff activity.
- Browser console shows no unexpected `4xx` or `5xx` errors during the tested flow.

## Session Observation Checklist

Record the session without changing production during the workflow:

- [ ] Session date, start time, and end time recorded.
- [ ] Owner, Business, Staff, and Customer roles identified without recording passwords, OTPs, or tokens.
- [ ] Pre-session production health and latest backup status confirmed.
- [ ] Owner completed registration and email verification without operator intervention.
- [ ] Owner completed the in-app setup tasks.
- [ ] Staff invitation, acceptance, and sign-in completed.
- [ ] Customer QR, Staff scan, action registration, progress, reward issue, and reward use completed.
- [ ] Owner verified Recent activity and Campaign customer/reward counts.
- [ ] Any confusing text, unexpected navigation, delay, retry, or support prompt recorded at the step where it occurred.
- [ ] Any unexpected browser, backend, Nginx, or Sentry error recorded with timestamp and workflow step, without sensitive data.
- [ ] Post-session health and scheduled backup status confirmed.
- [ ] Session outcome marked `passed`, `passed with friction`, or `stopped`.

Classify each finding as one of:

- `Blocker`: prevents or corrupts the loyalty workflow; stop and investigate.
- `High`: workflow completes only with operator help or repeated retries.
- `Medium`: real confusion or avoidable friction, but the workflow completes.
- `Low`: cosmetic polish with no workflow impact.

Do not implement findings during the session unless a Blocker makes continued use unsafe. Record the evidence first, then prioritize a separate coherent change.

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

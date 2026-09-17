# Zomia Documentation

This folder is the primary source of truth for Zomia's decisions, MVP scope, architecture, and development plan.

Zomia is a loyalty platform whose main flow is:

```text
Customer QR
-> Staff Scan
-> Action Registration
-> Loyalty Engine
-> Point Accumulation
-> Campaign Evaluation
-> Reward Generation
-> Reward Use
```

## Document Index

* [Product Overview](./01-product-overview.md)
* [MVP Scope](./02-mvp-scope.md)
* [Architecture](./03-architecture.md)
* [Domain Glossary](./04-domain-glossary.md)
* [Workflows](./05-workflows.md)
* [Roadmap](./06-roadmap.md)
* [Local Development](./07-local-development.md)
* [Production Deployment Plan](./deployment/production-deployment-plan.md)
* [Server Hardening Checklist](./deployment/server-hardening-checklist.md)
* [First Private Pilot Onboarding Plan](./deployment/first-private-pilot-onboarding-plan.md)
* [API Endpoint Inventory](./api/api-endpoint-inventory.md)
* [Current Stability Check](./status/current-stability-check.md)
* [MVP Production Gap List](./status/mvp-production-gap-list.md)
* [Production Workflow Validation - 2026-07-01](./status/production-workflow-validation-2026-07-01.md)
* [Manual QA Release Candidate Checklist](./status/manual-qa-release-candidate-checklist.md)
* [Auth Recovery and Email Verification Contract](./status/auth-recovery-verification-contract.md)
* [Flutter MVP Phase](./roadmap/flutter-mvp-phase.md)
* [Flutter Branding Extraction](./roadmap/flutter-branding-extraction.md)
* [Business And Account Lifecycle Roadmap](./roadmap/business-account-lifecycle-roadmap.md)
* [Sprint 1: Identity Engine](./sprints/sprint-1-identity.md)
* [Sprint 2: Loyalty Foundation](./sprints/sprint-2-loyalty-foundation.md)
* [Sprint 3: Individual Campaign](./sprints/sprint-3-individual-campaign.md)
* [Sprint 4: Reward Engine](./sprints/sprint-4-reward-engine.md)
* [Sprint 5: QR Staff Workflow](./sprints/sprint-5-qr-staff-workflow.md)
* [Sprint 5.5: Staff Panel API Contract](./sprints/sprint-5-5-staff-panel-contract.md)
* [Sprint 5.6: Staff Context Endpoint](./sprints/sprint-5-6-staff-context.md)
* [Flutter F0: Project Setup](./sprints/flutter-f0-project-setup.md)
* [Flutter F1: Auth And Staff Context](./sprints/flutter-f1-auth-staff-context.md)
* [Flutter F2: Staff Service Panel MVP](./sprints/flutter-f2-staff-service-panel.md)
* [Flutter F2.5: Staff And Customer QR UX Polish](./sprints/flutter-f2-5-staff-customer-ux-polish.md)
* [Flutter F2.6: Manual End-to-End QA](./sprints/flutter-f2-6-manual-end-to-end-qa.md)
* [Flutter F2.7: Staff Panel UX Polish](./sprints/flutter-f2-7-staff-panel-ux-polish.md)
* [Flutter F2.8: Customer Minimal Status](./sprints/flutter-f2-8-customer-minimal-status.md)
* [Flutter F2.9: MVP Demo Readiness](./sprints/flutter-f2-9-mvp-demo-readiness.md)
* [Flutter F3: Customer QR Display](./sprints/flutter-f3-customer-qr-display.md)
* [Flutter F5: Owner Minimal Setup Screens](./sprints/flutter-f5-owner-minimal-setup-screens.md)
* [Flutter F6: Customer Campaign Progress](./sprints/flutter-f6-customer-campaign-progress.md)
* [Flutter F7: UI / Branding Recovery](./sprints/flutter-f7-ui-branding-recovery.md)
* [Decision 0001: MVP Scope](./decisions/0001-mvp-scope.md)
* [Decision 0002: Local MVP Stack](./decisions/0002-local-mvp-stack.md)
* [Decision 0004: Production Database Direction](./decisions/0004-production-database-direction.md)
* [Decision 0005: Private Pilot Server](./decisions/0005-private-pilot-server.md)

## Current Status

Sprint 1 has been completed and recorded as a secure baseline.

Completed:

* Backend skeleton
* Identity models
* Business Profile model
* Staff Membership model
* JWT Authentication
* Owner APIs for managing Business and Staff
* Initial Alembic migration
* API tests

Sprint 2 has been implemented and smoke-tested against a real PostgreSQL database.

Confirmed:

* PostgreSQL was run with Docker Compose
* Alembic migration was executed against real PostgreSQL
* API was smoke-tested against the real database
* OpenAPI was reviewed on the running backend
* Git baseline commit was created

Sprint 2:

* Mission API added
* Multi-item Action added
* Points Ledger added
* Idempotency for Action Registration added
* Basic Audit added
* Migration executed against real PostgreSQL
* API smoke-tested against the real database

Sprint 3 has been implemented and smoke-tested against a real PostgreSQL database.

Sprint 3:

* Individual Campaign API added
* Campaigns connected to Missions through `campaign_missions`
* Campaign Evaluation added after Action Registration
* Campaign Completion added
* Customer progress is calculated from the Points Ledger
* Rewards are not created in Sprint 3
* Migration executed against real PostgreSQL
* Campaign and idempotency tests passed

Sprint 4 has been implemented and smoke-tested against a real PostgreSQL database.

Sprint 4:

* Reward Template API added
* Generated Reward is created after Campaign Completion
* Customer can view their own Rewards
* Staff can use an active Reward
* Reward Use creates an Action of type `reward_use`
* Reward Use does not modify the Points Ledger
* Reward includes `issuer_business_id`, `redeem_scope`, and `settlement_policy` for future Cross functionality
* Generated Reward includes `source_type`, `source_id`, and `customer_id` for future Group functionality
* Reward usage records the redemption location through `redeemed_business_id`
* Migration executed against real PostgreSQL
* Reward Engine and idempotency tests passed

Sprint 5 has been implemented and smoke-tested against a real PostgreSQL database.

Sprint 5:

* Customer QR Token added
* Raw QR Tokens are not stored in the database; only `token_hash` is stored
* Customer can issue/rotate their own QR
* Staff can resolve a QR for their Business
* Staff Service Summary includes customer, points, active rewards, and recent actions
* Staff can register an Action using a QR
* Staff can use a Reward using a QR
* Reward Use via QR still does not modify the Points Ledger
* Migration executed against real PostgreSQL
* QR Staff Workflow tests passed

Sprint 5.5 has been implemented.

Sprint 5.5:

* API contract for the Staff Service Panel was clarified
* A Staff-specific endpoint for viewing registrable Missions was added
* `recent_actions` in the Staff Service Summary was strongly typed
* Staff Panel API Contract tests were added

Sprint 5.6 has been implemented.

Sprint 5.6:

* A Staff-specific Context endpoint was added
* After login, Flutter can retrieve the Businesses associated with the Staff member
* The response is designed as an array to support multiple Businesses in the future
* Staff Context tests were added

Flutter F0 has been implemented.

Flutter F0:

* Flutter project created in `frontend/`
* Base dependencies added
* Basic app shell, theme, and router created
* API config, Dio client, and secure token storage prepared
* `flutter analyze`, `flutter test`, and `flutter build web` passed

Flutter F1 has been implemented.

Flutter F1:

* Login screen added
* JWT is stored in secure storage
* Staff Context is loaded from the backend
* Business selection for multiple Businesses is ready
* Sign out added
* `flutter analyze`, `flutter test`, and `flutter build web` passed

Flutter F2 and F3 have been implemented.

Flutter F2/F3:

* Staff Service Panel connected to the backend
* Customer QR Display added
* Customer QR rotation added
* Staff can resolve a Customer QR
* Staff can register an Action and use an active Reward

Flutter F2.5:

* Staff camera QR scanning added
* Manual token input remained as a fallback at that stage; in the current state, the primary UI path is camera scanning only
* Initial polish applied to Customer QR and Staff QR entry
* Flutter version was incremented so that Login can detect a new build

Flutter F2.6:

* Manual end-to-end testing completed
* Customer login, Customer QR, Staff login, camera scan, customer resolution, Action registration, points, reward generation, reward use, and recent actions all passed
* The core Staff/Customer MVP loop became reliable enough for continued UX polish

Flutter F2.7:

* Confirmation before `Use Reward` added
* Action registration messaging was made clearer when no new reward is issued
* Customer loaded card and mission row were polished for practical Staff usage
* Local development seed for creating a test active reward was added

Flutter F2.8:

* `GET /customers/me/status` endpoint added
* Customer Dashboard displays active reward status
* Customer can manually refresh the status after Staff operations
* Total points display was removed for Customer; at that time, Campaign Progress was planned as a separate phase

Flutter F2.9:

* Official demo flow documented
* Seed strategy for reward-use QA documented
* Known product gaps and UI/Brand debt recorded
* Project prepared for the next-stage decision without adding new features

Flutter F5 through F8:

* A minimal Owner Dashboard was added for inviting Staff and creating Missions, Campaigns, and Reward Templates
* Customer Campaign Progress was designed and implemented without publicly displaying `total points`
* UI/Branding Recovery was completed, and the component catalog was added as the UI reference
* Main Flutter screens were migrated to the current structure:

  * `customer_screen.dart`
  * `staff_panel.dart`
  * `owner_screen.dart`
* Customer Registration was added, and Customers can open the registration page from Login
* Customer Registration currently includes only `name`, `email`, `password`, `confirm password`, and `Term Accept`
* `phone` is excluded from registration and will later be added as part of profile completion

## Current Status for Continuation

The short-form sources of truth for continuing the project are:

* [Current Stability Check](./status/current-stability-check.md)
* Current backend and frontend code
* This README as the overall snapshot

Older sprint documents preserve the history of decisions. If they contain statements such as the manual token fallback or references to old file names, they should be read as historical notes from that stage, not as the current product state.

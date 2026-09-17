# MVP Scope

The MVP should be small, but it must not compromise the final architecture.

**Small** means:

* Build only one complete loyalty workflow
* Keep the number of roles and screens to a minimum
* Start with the simplest possible implementation of Campaigns and Rewards
* Build only the infrastructure required for execution and verification

**Future-proof** means:

* Domain boundaries are clearly defined from the beginning
* The schema does not prevent future Group and Cross-Network Campaigns
* Points are stored as an append-only ledger
* Rewards have a lifecycle
* Actions are auditable and idempotent
* Business logic lives in Services, not inside Routers

## Included in MVP

### Identity

* Customer registration
* Owner registration
* Staff invitation by Owner through a secure email link
* JWT Authentication
* Role-based access control

### Business

* Business Profile
* Staff Membership
* Business management by Owner

### Loyalty Foundation

* Mission
* Action
* Points Ledger
* Individual Campaign

### Reward Engine

* Reward Template
* Generated Reward
* Reward lifecycle: `active`, `used`, `expired`

### QR Staff Workflow

* Customer QR Token
* Scan Resolve Endpoint
* Register Action Endpoint
* Use Reward Endpoint

### Minimal UI

The MVP needs the smallest practical UI for testing the real workflow. If Flutter is ready quickly, Flutter should be used; otherwise, a simpler UI for initial validation is acceptable.

For the initial Flutter implementation, the UI scope is defined as **Staff-first**:

* Staff Login
* Staff Context
* Staff Service Panel
* QR input/scan
* Action Registration
* Reward Use

Owner and Customer UIs will be added during the Flutter phase, but the MVP frontend starts with the Staff workflow.

The final frontend will be built in English. All user-visible text in Flutter, including titles, buttons, labels, error messages, and empty states, must be in English.

## Out of Scope for MVP

* Group Campaign execution
* Cross-Network Campaign execution
* Fans Group management
* Business Club management
* Settlement Engine
* Full Analytics
* Gamification
* Marketplace
* Full Production CI/CD

## MVP Completion Criteria

The MVP is complete when:

* Owner can create Staff
* Customer can be identified through a QR
* Staff can register an Action
* Points are recorded in the ledger
* An Individual Campaign can generate a Reward
* Staff can Use the Reward
* Core APIs have tests
* Migrations run successfully on PostgreSQL
* OpenAPI is usable

# AGENTS.md

Permanent instructions for Codex and other coding agents working on Zomia. This file applies to the entire repository unless a more specific nested `AGENTS.md` is added later.

## 1. Project Overview

Zomia is a private-pilot loyalty platform for local businesses. The MVP supports:

- Identity: Customer, Owner, Staff, Admin roles.
- Loyalty: Mission, Action, Points Ledger, Campaign, Reward Template, Reward.
- QR workflow: Customer QR -> Staff scan -> customer confirmation -> action or reward use.
- Owner setup: Business, Staff invitations, Missions, Reward Templates, Campaigns.
- Static public site at `https://zomia.eu/` and Flutter WebApp at `https://zomia.eu/webapp/`.

Build incrementally. Do not generate large unrelated systems at once. Keep the MVP small while preserving architecture for future Group and Cross-Network campaigns.

## 2. Repository Structure

- `backend/` - FastAPI backend, SQLAlchemy models, Alembic migrations, backend tests.
- `frontend/` - Flutter app for Customer, Staff, and Owner flows.
- `site/` - Static landing page and public legal pages served from the root domain.
- `Docs/` - Product, architecture, sprint, status, deployment, legal, and decision docs.
- `docker-compose.yml` - Local PostgreSQL dependency.
- `Makefile` - Common local commands.
- `scripts/` - Production-oriented frontend build script.

The canonical local project path is usually `/Users/mac-wahid/Documents/Zomia MVP`. Avoid leaving work only in `.codex/worktrees`.

## 3. Architecture Overview

Backend modules are organized by domain:

- `identity`: users, roles, registration, auth, refresh tokens, staff invitations, account lifecycle.
- `loyalty`: missions, actions, points ledger, campaigns, campaign progress, reward templates, rewards.
- `qr`: customer QR tokens and staff scan resolution.
- `core`: config, database, security, email, monitoring.

Backend layering:

- Router: validate request, enforce role access, return schemas.
- Service: business rules and workflow orchestration.
- Repository: database access.
- Model/schema: persistence and API contracts.

Frontend layering:

- Screens orchestrate state, navigation, and API calls.
- Presenters format display data only.
- Shared UI lives in `frontend/lib/app/ui/`.
- Domain decisions stay in backend contracts, not Flutter widgets.

## 4. Coding Conventions

- Prefer small, focused changes.
- Follow existing module patterns before adding new abstractions.
- Keep comments sparse and useful.
- Backend routers should stay thin; put business rules in services.
- Repositories should not contain product decisions.
- Frontend screens should stay orchestration-focused; extract repeated UI into feature widgets or shared UI.
- Keep frontend text in English.
- Do not introduce unrelated refactors while implementing a feature.

## 5. Naming Conventions

- Python files/modules: `snake_case.py`.
- Python classes: `PascalCase`.
- Python functions/variables: `snake_case`.
- Dart files: `snake_case.dart`.
- Dart classes/widgets: `PascalCase`.
- Dart fields/methods: `lowerCamelCase`.
- Database tables/columns: `snake_case`.
- API route paths: lowercase plural nouns where practical.
- Use domain names consistently: Mission, Action, Points Ledger, Campaign, Reward Template, Reward.

## 6. Preferred Libraries / Frameworks

Backend:

- FastAPI
- SQLAlchemy 2.x
- Alembic
- PostgreSQL / psycopg
- Pydantic Settings
- Pytest
- Ruff
- Sentry SDK for backend error tracking

Frontend:

- Flutter
- Riverpod
- GoRouter
- Dio
- flutter_secure_storage
- package:web for browser APIs
- Sofia Sans font and approved Zomia brand assets

Local infrastructure:

- Docker Compose for PostgreSQL only.

## 7. Error Handling Guidelines

- Never expose raw backend internals or secrets in user-facing errors.
- Map known backend error details to clear, short UI messages.
- Unknown backend errors should use generic UI copy.
- Backend should raise appropriate HTTP errors with stable detail strings when UI needs mapping.
- Network `400/401/422` entries may appear in browser devtools for invalid user input; the UI should still show a friendly message.
- Sentry must not collect passwords, OTPs, tokens, QR tokens, SMTP secrets, database URLs, email bodies, or other sensitive values.

## 8. Testing Commands

Backend:

```bash
cd backend
.venv/bin/python -m pytest
```

or:

```bash
make backend-test
```

Frontend:

```bash
cd frontend
flutter test
```

Full backend verification:

```bash
make verify
```

For production-sensitive backend changes, also verify Alembic migration state and migration SQL.

## 9. Linting and Formatting Commands

Backend lint:

```bash
make backend-lint
```

Backend formatter is not globally configured; avoid broad formatting churn unless explicitly requested.

Frontend format:

```bash
dart format frontend/lib frontend/test
```

Frontend analyze:

```bash
cd frontend
flutter analyze
```

For narrow edits, format only the touched Dart files.

## 10. Build Commands

Production Flutter web build:

```bash
./scripts/build_frontend_production.sh
```

This script builds with the production API base URL, `/webapp/` base href, and generated version metadata from `frontend/pubspec.yaml`.

Static site changes under `site/` do not require rebuilding the Flutter WebApp.

## 11. Development Workflow

1. Read existing code and docs before changing behavior.
2. For UI work, agree on a short execution text first when the product/design decision is not obvious.
3. Check `Docs/api/api-endpoint-inventory.md` before adding or changing backend endpoints.
4. Check `Docs/status/frontend-dialog-inventory.md` before adding dialogs or fullscreen flows.
5. Keep frontend loyalty logic out of Flutter; add backend API fields when display needs new business concepts.
6. Bump `frontend/pubspec.yaml` for every Flutter release that affects the WebApp.
7. Run focused tests first, then broader tests for risky changes.
8. Commit coherent changes with concise messages.
9. Keep `/Users/mac-wahid/Documents/Zomia MVP` synchronized with GitHub `main`.

Production deployment is currently manual for the private pilot. GitHub Actions is CI-only unless a later manual-approval deploy workflow is explicitly introduced.

Every Flutter production deployment must run through
`./scripts/deploy_frontend_production.sh`. Do not manually build, archive, copy,
or switch the Frontend symlink. The deployment script builds the exact pushed
`main` commit in a temporary worktree, validates and publishes an inactive
release, switches the symlink atomically, runs production smoke checks, and
rolls back automatically when post-activation verification fails. After a
successful deployment, record the release in
`Docs/deployment/production-operations-checklist.md` and commit/push that note.

## 12. Pull Request Expectations

A PR or commit summary should include:

- What changed and why.
- Backend/API changes, if any.
- Frontend/UI changes, if any.
- Migration impact, if any.
- Tests and checks run.
- Production/deployment notes, if relevant.

Do not mix unrelated product, UI, backend, and documentation work unless the task explicitly requires it.

## 13. Performance Guidelines

- Keep Flutter screens light; split large screens into feature widgets and presenters.
- Avoid adding heavy UI catalog or debug-only surfaces to production navigation.
- Avoid unnecessary backend queries in hot workflow paths such as Staff QR scan and action registration.
- Add pagination/limits for growing activity feeds.
- Keep static landing pages lightweight; do not turn `site/` into a heavy app.

## 14. Security Rules

- Never commit secrets, `.env`, SMTP credentials, JWT secrets, database URLs, backup credentials, private keys, or Sentry DSNs unless they are explicitly safe public examples.
- Store production secrets only in protected server env files.
- Passwords must be hashed; tokens stored server-side must be hashed when persisted.
- Refresh tokens rotate and are revocable.
- Access-token invalidation uses `users.session_version` for password recovery completion, password change, and customer account removal.
- Email verification and staff invitation flows must not allow account activation without the verified/invited email flow.
- QR tokens are sensitive and short-lived workflow credentials.
- Account deletion/anonymization must respect legal and audit requirements documented in `Docs/legal/`.

## 15. Files / Directories That Should Rarely Be Modified

- `frontend/build/` - generated build output.
- `frontend/.dart_tool/`, `.pytest_cache/`, `.venv/`, caches.
- Alembic migration files after they have been applied in production.
- Legal text under `site/legal/` without an explicit legal/content task.
- Production deployment docs without verifying actual server state.
- Brand assets and favicon files unless explicitly requested.
- Generated Flutter platform files under `frontend/android/`, `frontend/macos/`, etc., unless doing platform work.

## 16. Generated Files That Should Not Be Edited

- `frontend/build/web/index.html` and other `frontend/build/` files.
- Flutter generated registrant files.
- Dependency lock/build/cache files unless dependency changes require it.
- Alembic-generated migration revision IDs should not be hand-renamed after use.

Edit source files instead:

- Root landing source: `site/index.html` and `site/assets/site.css`.
- Flutter app source: `frontend/lib/`.
- Backend source: `backend/app/`.

## 17. How to Investigate Bugs

1. Reproduce or identify the failing workflow.
2. Check recent commits and whether production, local, and GitHub are synchronized.
3. Inspect browser console and Network tab for frontend issues.
4. Inspect backend tests, service code, and API contracts for logic issues.
5. Check production logs/Sentry only when production behavior is involved.
6. Verify database migrations and current schema for persistence issues.
7. Add or update a focused regression test before or with the fix.
8. Avoid masking a backend contract bug with frontend-only logic.

## 18. How to Implement New Features

1. Define the smallest useful MVP behavior.
2. Update or confirm the domain/API contract first.
3. Add or update database models and migrations when persistence changes.
4. Implement repository/service/router changes in that order when practical.
5. Add backend tests for role protection and business rules.
6. Implement frontend models/repositories/controllers/presenters/screens.
7. Use approved shared UI components; if a new reusable component is needed, add it to `frontend/lib/app/ui/` and get visual approval before broader product usage.
8. Update docs that represent current status or API contracts.
9. Run relevant tests, lint, analyze, and build checks.

## 19. How to Perform Refactoring Safely

- Preserve behavior unless the task explicitly changes it.
- Refactor in small, reviewable steps.
- Keep tests green before and after the refactor.
- Do not change API contracts accidentally.
- Do not move domain rules into Flutter during UI refactors.
- Do not rewrite migrations already used in production.
- When splitting large files, keep public imports stable with barrels only when that matches existing patterns.
- After refactoring production-sensitive workflows, run manual smoke checks or document why they were not run.

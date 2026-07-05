# Git Workflow Standard

Date: 2026-07-05

This document defines the working path and Git workflow for Zomia.

## Official Local Project Path

The official local project path is:

```text
/Users/mac-wahid/Documents/Zomia MVP
```

This path is the local source of truth for day-to-day work.

If Codex opens or creates a separate worktree, the path must be checked before making important changes. Any completed work from a Codex worktree must be moved back into the official `main` branch and pushed to GitHub.

## Official Remote

The official GitHub remote is:

```text
git@github.com:abiyarilangeroudi-sudo/zomia.git
```

The official branch is:

```text
main
```

## Normal Change Flow

For every meaningful change:

1. Make the code, site, or documentation change.
2. Run the relevant verification.
3. Commit the change.
4. Push `main` or the working branch to GitHub.
5. Deploy only from committed code whenever possible.

Production should not be built from uncommitted local changes. If a small urgent production change is deployed first, it must be committed and pushed immediately after verification.

## Branching Rule

Small, clear changes may be committed directly to `main`.

Larger or riskier changes should use a branch named:

```text
codex/<short-topic>
```

Examples:

```text
codex/ui-final-pass
codex/owner-polish
codex/private-pilot-hardening
```

After review and manual acceptance, the branch can be merged into `main` and pushed.

## Source Boundaries

`site/`

Public static website source, including the landing page and legal pages.

`frontend/`

Flutter application source.

`frontend/build/web/`

Generated Flutter build output. Do not edit manually.

`backend/`

FastAPI backend, SQLAlchemy models, Alembic migrations, services, and API logic.

`Docs/`

Architecture decisions, status notes, deployment runbooks, legal notes, and production gap tracking.

## Deployment Boundary

Deployments must be traceable to a Git commit.

Before deploying:

- Confirm the relevant commit exists locally.
- Prefer pushing the commit to GitHub before deployment.
- If deployment happens before push, push immediately after verification.

After deploying:

- Verify production.
- Record or confirm the related commit.


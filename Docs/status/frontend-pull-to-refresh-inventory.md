# Frontend Pull-To-Refresh Inventory

Date: 2026-07-07

This document tracks Flutter WebApp screens and fullscreen flows that support drag-down pull-to-refresh.

## Rule

- Pull-to-refresh is for read-heavy screens where data can change outside the current view.
- Pull-to-refresh must not reset an in-progress form or sensitive workflow.
- Customer QR tokens must not rotate during page pull-to-refresh. QR rotation stays explicit in the QR dialog.
- Backend domain rules stay in the API; Flutter refresh only reloads existing API data.
- Desktop browser testing is not reliable for this gesture. Mobile manual QA is required when this behavior changes.

## Current Pull-To-Refresh Surfaces

| Role | Surface | Flutter file | Reloaded data | Notes |
| --- | --- | --- | --- | --- |
| Owner | Home / Owner Dashboard | `frontend/lib/features/owner_setup/presentation/owner_screen.dart` | Owner setup data through `OwnerSetupController.load()` | Refreshes business/setup state, missions, reward templates, campaigns, staff, and recent activity used by setup/pilot tasks. |
| Owner | Recent activity fullscreen dialog | `frontend/lib/features/owner_setup/presentation/owner_activity_dialog.dart` | `/owner/activity/recent` through `OwnerSetupRepository.listRecentActivity()` | Keeps the dialog on the same business and reloads the activity list. |
| Staff | Recent Actions tab | `frontend/lib/features/staff_context/presentation/staff_home_screen.dart` | `/staff/service/recent-actions` through `StaffServiceRepository.listRecentActions()` | Does not touch the active Staff service panel or customer QR workflow. |
| Customer | Home tab | `frontend/lib/features/customer_qr/presentation/customer_screen.dart` | Customer status and campaign progress through `_loadStatus()` | Updates visible campaign/reward counts without issuing a new QR token. |
| Customer | Campaign tab | `frontend/lib/features/customer_qr/presentation/customer_screen.dart` | Customer status and campaign progress through `_loadStatus()` | Refreshes active/archive campaign progress. |
| Customer | Reward tab | `frontend/lib/features/customer_qr/presentation/customer_screen.dart` | Customer status and campaign progress through `_loadStatus()` | Refreshes active/archive rewards without issuing a new QR token. |

## Explicitly Not Enabled

| Surface | Reason |
| --- | --- |
| Owner Loyalty tab | Not added yet; current MVP need was Owner Home and Recent activity. Revisit if owner lists need manual refresh. |
| Owner Team tab | Not added yet; staff invitation and activation actions already reload through controller saves. |
| Owner create/edit fullscreen dialogs | Avoid resetting in-progress Mission, Reward Template, Campaign, Staff invite, or Business settings forms. |
| Staff Dashboard / Home service panel | Avoid resetting a loaded/scanned customer context or selected mission quantities during a service workflow. |
| Staff QR scanner fullscreen flow | Scanner is an active camera workflow, not a read-only list. |
| Customer QR dialog | QR token refresh must remain explicit because old QR codes become invalid after rotation. |
| Profile and account settings dialogs | Avoid resetting in-progress account/profile edits. |

## Release History

- `1.0.129 (130)` added pull-to-refresh for Owner Home and Owner Recent activity.
- `1.0.130 (131)` added pull-to-refresh for Staff Recent Actions and Customer Home, Campaign, and Reward tabs.

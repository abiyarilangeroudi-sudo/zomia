# Production Workflow Validation - 2026-07-01

Status: `PASS`

Date: 2026-07-01

Environment: production

## Goal

Validate the production loyalty workflow across multiple owners, staff members, customers, point ledger entries, campaign evaluation, and reward generation.

## Scenario

The manual production test used:

- 3 owners / businesses:
  - `Gillo Coffee`
  - `Pitto Baker`
  - `Nimmo Barber`
- 5 customers.
- 50 total mission-progress actions.
- 1 point per action.
- 1 active campaign per business.
- Campaign threshold: 5 points.
- Actions were distributed unevenly across the businesses and staff members.

## Production Data Summary

Business-level result:

| Business | Mission actions | Points | Generated rewards |
| --- | ---: | ---: | ---: |
| Gillo Coffee | 18 | 18 | 2 |
| Pitto Baker | 20 | 20 | 2 |
| Nimmo Barber | 12 | 12 | 1 |
| **Total** | **50** | **50** | **5** |

Customer-level result:

| Customer | Actions | Points | Rewards |
| --- | ---: | ---: | ---: |
| user01 | 10 | 10 | 1 |
| user02 | 10 | 10 | 1 |
| user03 | 10 | 10 | 1 |
| user04 | 10 | 10 | 1 |
| user05 | 10 | 10 | 1 |

Staff distribution:

| Business | Staff | Actions |
| --- | --- | ---: |
| Gillo Coffee | wahid.abi.89+04 | 9 |
| Gillo Coffee | wahid.abi.89+05 | 9 |
| Pitto Baker | wahid.abi.89+06 | 11 |
| Pitto Baker | wahid.abi.89+07 | 9 |
| Nimmo Barber | wahid.abi.89+08 | 12 |

## Validation Checks

Passed:

- All 3 businesses existed and were active.
- Each business had one active campaign with threshold 5.
- Each campaign was linked to one mission and one reward template.
- All 50 mission-progress actions were registered.
- All point ledger entries were 1 point.
- Business point totals matched mission action totals.
- Campaign completion generated rewards after customers reached the threshold.
- Every tested customer received at least one reward.
- No non-1-point action items were found.
- No non-1-point ledger entries were found.
- No non-threshold-5 campaign or completion anomalies were found.
- Backend warning/error log for the test day showed no entries.
- Nginx error log showed no suspicious entries during the check.

## Result

The tested production workflow passed:

```text
Staff action registration
-> points ledger
-> business/customer point totals
-> campaign threshold evaluation
-> reward generation
```

No mismatch was found in the tested production data.

## Follow-Up

Before onboarding the first real customer, decide whether to:

- reset production test data and start from a clean database state; or
- keep the current production test data until the private-pilot onboarding plan is complete.

If a reset is chosen, use a controlled pre-pilot database reset with a fresh backup first.

# Workflows

## Main MVP Workflow

```text
Customer registers
-> Owner registers and creates business
-> Owner creates staff
-> Owner creates mission
-> Owner creates individual campaign
-> Customer presents QR
-> Staff scans QR
-> Staff registers action
-> Points ledger records points
-> Campaign engine evaluates progress
-> Reward engine creates reward
-> Staff uses reward
```

## Staff Service Workflow

```text
Scan customer QR
-> Resolve customer
-> Show customer summary
-> Show active rewards
-> Load service missions
-> Register action
-> Return updated points and rewards
```

## Loyalty Engine Workflow

```text
Mission
-> Action
-> Points Ledger
-> Campaign Evaluation
-> Reward Generation
```

## Individual Campaign Workflow

```text
Action recorded
-> Load active individual campaigns for business
-> Match action items to campaign missions
-> Sum customer progress
-> If threshold reached, create campaign completion
-> Reward engine generates reward from completion
```

## Reward Use Workflow

```text
Staff selects active reward
-> System verifies staff belongs to business
-> System verifies reward belongs to customer and business
-> System records Reward Usage under the Action
-> Reward status changes to used
-> Audit event is recorded
```

Reward Use does not decrease Points. Points in Zomia represent progress/earned points, not wallet credit.

## Reward Generation Workflow

```text
Campaign completion created
-> Load active reward template linked to campaign
-> Create generated reward for customer
-> Mark completion reward_generated_at
-> Record audit event
```

In the MVP, a Campaign must have a Reward Template when it is created. Therefore, a valid Campaign completion can generate a Reward.

## Future Group Campaign Workflow

This workflow is intentionally out of scope for the MVP:

```text
Fans group joins campaign
-> Members complete actions
-> Group progress accumulates
-> Settlement engine checks threshold
-> Rewards are issued to eligible members
```

## Future Cross-Network Campaign Workflow

This workflow is intentionally out of scope for the MVP:

```text
Business club creates shared campaign
-> Customers earn across partner businesses
-> Campaign evaluates cross-network activity
-> Rewards are issued with issuer and redeem scope
-> Staff uses reward only in allowed business scope
-> Settlement engine calculates business payable/receivable amounts
```

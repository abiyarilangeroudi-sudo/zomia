# Domain Glossary

## Identity

### User

The user account record used for authentication. All roles, such as Customer, Owner, Staff, and Admin, are fundamentally Users.

### Customer

The end customer who displays a QR code, has Actions registered for them, earns Points, and receives Rewards.

### Owner

The business owner who manages the Business, Staff, Missions, Campaigns, and Rewards.

### Staff

A business employee who scans the customer's QR code, registers Actions, and Uses Rewards.

### Admin

A platform administrator. In the MVP, only the role exists.

## Business

### Business

A business or merchant that operates a loyalty program.

### Staff Membership

The relationship between a Staff User and a Business.

### Business Partner Club

A community of businesses for Cross-Network Campaigns. Out of scope for the MVP.

## Loyalty

### Mission

A defined behavior that can generate Points, such as a purchase, visit, check-in, friend referral, or review.

### Action

A record of a real-world operation performed for a Customer. A single Action can register multiple Missions simultaneously.

Example:

```text id="l0n1m2"
Ali bought 2 coffees and 1 cake
```

This is one Action, but it contains multiple Action Items.

In the future, an Action can also contain Reward Usage. Reward Usage records the consumption of a Reward and does not create or remove Points.

### Action Item

A row within an Action that is linked to a Mission.

Example:

```text id="a1b2c3"
Buy Coffee x 2
Buy Cake x 1
```

### Reward Usage

A record of a Reward being consumed as part of an Action. Reward Usage is not linked to a Mission and does not create a Points Ledger entry.

### Point

A unit representing customer progress. Points must be stored in the Points Ledger.

### Points Ledger

An append-only ledger of earned Points. The ledger is not a wallet or credit economy, and using a Reward does not decrease Points.

### Campaign

A set of rules that evaluates customer progress and determines whether a Reward should be issued.

A Campaign always has a `starts_at` and `ends_at` time range. Actions outside this range do not count toward the progress of that Campaign.

The Campaign's temporal status and the progress text displayed to the Customer are calculated by the Backend, not the Frontend.

A Campaign has two different types of ending:

* **Expired:** A natural, time-based ending that occurs when `ends_at` has passed. Incomplete progress remains archived with an `Expired` status, and no new Reward is issued.
* **Ended:** A manual ending performed by the Owner before `ends_at`. This status is accompanied by **Early End Settlement**: for every Customer with incomplete progress greater than zero in the current cycle, a final Reward is issued and the Campaign then ends. Customers with zero progress do not receive a Reward.

`Expired` is a calculated time status based on the time range; `Ended` is an explicit terminal status. This distinction and manual settlement are implemented in the Backend, not in Flutter.

### Individual Campaign

A Campaign in which each Customer progresses independently.

Example:

```text id="x7y8z9"
10 purchases -> 1 free coffee
```

### Repeatable Campaign Cycle

A cycle in which an Individual Campaign can create a Campaign Completion and consequently a new Reward each time the Customer reaches the threshold.

In the MVP, `max_completions_per_customer = null` means that the number of cycles is unlimited within the Campaign's time range. If a positive number is specified, that number becomes the maximum number of completions for each Customer.

Example:

```text id="r1s2t3"
threshold = 10 points
20 points -> 2 completed cycles -> 2 rewards
23 points -> current cycle progress is 3/10
```

### Group Campaign

A future Campaign in which members of a Fans Group collaborate toward a shared goal. Out of scope for the MVP.

### Cross-Network Campaign

A future Campaign that runs across multiple Businesses. Out of scope for the MVP.

## Rewards

### Reward Template

The Owner's definition of the Reward type, value, validity period, issuer, redemption scope, and settlement policy.

A Reward Template is independent of a Campaign. A Campaign selects a Template for Reward issuance through the `campaign_reward_templates` relationship.

In the MVP, each Campaign has exactly one Reward Template. This limitation keeps the MVP simple and can later be expanded to support multi-reward Campaigns.

### Generated Reward

The actual Reward issued to a Customer after a Campaign Completion. This record stores a snapshot of the Template information so that future changes to the Template do not affect previously issued Rewards.

### Reward Generation Source

The source that caused a Generated Reward to be issued.

In the MVP:

```text id="u4v5w6"
individual_campaign_completion
```

In the future:

```text id="g7h8i9"
group_campaign_completion
```

A Generated Reward is always issued to a Customer, but its source can be individual or group-based.

To prevent duplicate issuance:

```text id="j1k2l3"
source_type + source_id + customer_id
```

must be unique.

### Reward Recipient Policy

A rule used by a Group Campaign to determine who receives Generated Rewards after the group goal is completed.

Future options:

```text id="m4n5o6"
all_group_members
contributors_only
contributors_above_minimum
selected_members
```

### Reward Issuer

The Business that issues the Reward and, in the MVP, is responsible for its cost.

### Redeem Scope

A rule that determines which Businesses can be used to redeem a Reward.

In the MVP:

```text id="p7q8r9"
issuer_business_only
```

In the future:

```text id="s1t2u3"
campaign_participants
selected_businesses
```

### Settlement Policy

A rule that determines who is responsible for the cost of a Reward after it is redeemed.

In the MVP:

```text id="v4w5x6"
issuer_pays
```

### Reward Status

The lifecycle status of a Generated Reward.

In the MVP:

```text id="y7z8a9"
active
used
expired
```

### Gift

Receiving a specific product or service as a Reward.

### Percentage Discount

A percentage-based discount on a future purchase.

### Fixed Discount

A fixed-amount discount on a future purchase.

### Reward Lifecycle

The Reward status flow:

```text id="b1c2d3"
active -> used
active -> expired
```

In the future, `pending` may also be added, especially for Group Campaigns and Settlement.

### Reward Engine

The domain component that creates Generated Rewards from Campaign Completions and Reward Templates and manages Reward usage.

The Reward Engine does not add negative Points to the Points Ledger and is not a Wallet/Credit Economy.

## Operations

### QR Scan

A Staff operation that resolves a Customer token and opens the service screen.

### Customer QR Token

A random, rotatable/revocable token that the Customer displays as a QR code.

The QR Token is not a JWT and is used only to resolve the Customer within the Staff Workflow.

Only `token_hash` is stored in the database; the raw token is not stored.

### Action Registration

The process of registering an operation for a Customer. The operation can include one or multiple Missions.

### Idempotency

A mechanism that prevents the same Action from being registered more than once when a request is repeated.

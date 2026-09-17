# Product Overview

Zomia is a loyalty platform for businesses. Its goal is to turn recurring customer behaviors such as purchases, visits, check-ins, or referrals into points and rewards.

## Core Product Flow

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

## Roles

### Customer

The end customer who participates in the loyalty program, displays their QR code, earns points, and receives rewards.

### Owner

The business owner who manages the Business, Staff, Missions, Campaigns, and Rewards.

### Staff

A business employee or operator who scans the customer's QR code, registers Actions, views active Rewards, and marks Rewards as used.

### Admin

A platform-level administrator. In the MVP, only the role exists; the full Admin panel and operations will be built later.

## MVP Goal

The MVP should not build every Zomia idea. The MVP should only prove one real end-to-end loyalty cycle:

```text
Owner creates a Business
Owner creates a Staff member
Customer becomes identifiable
Staff scans the customer's QR
Staff registers an Action
The system records Points
The system evaluates an Individual Campaign
If the condition is completed, a Reward is generated
Staff can Use the Reward
```

## Out of Scope for MVP

These features are important for the future, but will not be built in the first MVP:

* Group Campaign
* Cross-Network Campaign
* Fans Group
* Business Partner Club
* Marketplace
* Gamification
* Advanced Analytics
* Full Admin Panel
* OAuth
* Multi-branch operations

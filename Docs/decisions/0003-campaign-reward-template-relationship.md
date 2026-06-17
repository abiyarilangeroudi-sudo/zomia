# Decision 0003: Campaign Owns Reward Selection

## Context

Owner workflow should match the domain model:

```text
Mission -> Reward Template -> Campaign
```

Mission defines what earns progress.

Reward Template defines what can be issued.

Campaign defines the rule that connects eligible Missions to one selected Reward Template.

## Decision

Reward Template is independent from Campaign.

Campaign links to Reward Template through `campaign_reward_templates`.

For MVP, each Campaign has exactly one Reward Template link. This is enforced by a unique constraint on `campaign_reward_templates.campaign_id`.

## Why

- Mission stays independent from Campaign.
- Reward Template stays independent from Campaign and can later support broader redeem/settlement rules.
- Campaign remains the orchestration point for Individual, Group, and Cross-Network rules.
- Future multi-reward Campaigns can be supported by removing the MVP unique constraint instead of changing the core model.

## Current MVP Rule

An Individual Campaign must select a Reward Template when it is created.

Reward generation loads the active Reward Template linked to the Campaign.

## Future Notes

For Group Campaign, the Campaign can later decide recipient policy separately from Reward Template definition.

For Cross-Network Campaign, the Campaign can later decide participating businesses and eligible Missions while Reward Template keeps issuer, redeem scope, and settlement policy.

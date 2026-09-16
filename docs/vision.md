# Palo Vision

## Mission

Palo makes game-development collaboration simple for individuals and small teams while keeping the underlying GitHub workflow reliable.

## Product architecture

Palo is a common platform with engine-specific integrations.

### Palo Platform

The platform owns:

- Palo accounts
- Workspaces
- Team membership
- Subscription status
- Project/repository associations
- GitHub connections
- Cross-device access control
- Engine integration discovery and installation metadata

### Engine Integrations

Integrations connect Palo to the developer's chosen engine. The first integration is Godot 3.x. The architecture must allow additional integrations for Godot 4.x, Unity, Unreal Engine, and future versions without changing the core account and workspace system.

## Plans

- Free — 1 person
- Team — 2–5 people, ₦1,200/year
- Team Plus — 6–20 people, ₦2,500/year
- Large Team — 21+ people, ₦4,500/year

Subscription enforcement must happen on the Palo backend rather than trusting the client plugin.

## Core principles

1. Simplicity over Git complexity.
2. One Palo identity across supported engines.
3. Workspaces control shared project access.
4. Subscription limits are enforced server-side.
5. Automatic safety mechanisms should protect project work.
6. Engine integrations should remain lightweight.

## Access model

A repository may be associated with a Palo workspace. A free workspace supports one person. When another person attempts to use that repository through Palo, the backend checks the workspace and subscription before granting access.

When the workspace needs additional members, the user should receive a clear upgrade message and be directed to contact the workspace administrator.

## Long-term goal

Palo should feel like one small product regardless of whether the developer uses Godot, Unity, Unreal Engine, or another supported engine. The user chooses an engine and version, installs the matching integration, signs into the same Palo account, and works inside the appropriate workspace.
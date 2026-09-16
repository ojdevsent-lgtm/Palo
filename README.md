# Palo

Palo is a small collaboration platform for game-development teams. It provides a simple experience on top of GitHub and installs an engine-specific integration for the game engine and version a developer uses.

## Product model

Palo has two layers:

- **Palo Platform** — accounts, workspaces, subscriptions, project access, GitHub connections, team membership, and licensing.
- **Engine Integrations** — lightweight plugins/packages for Godot, Unity, Unreal Engine, and supported engine versions.

The platform is engine-independent. A user's Palo account and team subscription work across supported engines.

## Plans

| Plan | Team size | Price |
|---|---:|---:|
| Free | 1 person | Free |
| Team | 2–5 people | ₦1,200/year |
| Team Plus | 6–20 people | ₦2,500/year |
| Large Team | 21+ people | ₦4,500/year |

The free plan is intended for personal use. Shared collaboration on the same Palo workspace requires a team plan.

## Core user flow

1. Install Palo.
2. Create or sign into a Palo account.
3. Choose a game engine.
4. Choose the engine version.
5. Palo installs the matching engine integration.
6. Connect GitHub and choose a repository.
7. Create or join a Palo workspace.
8. Collaborate according to the workspace's subscription and membership limits.

## Workspace access

A GitHub repository can be associated with a Palo workspace. Palo's backend is responsible for enforcing workspace ownership, membership, subscription limits, and access across devices.

If a second person attempts to use a repository through the free plan when it is already associated with another user's free workspace, Palo should show a clear message such as:

> **Team access required**  
> This project is currently using the Palo Free plan, which supports one person. Contact the workspace administrator to upgrade the plan before adding another person.

Users should not be able to bypass workspace limits by changing Palo accounts, GitHub accounts, or devices.

## Initial implementation

The current repository contains the first Godot 3.x integration. The next architectural step is to separate common Palo functionality from engine-specific integrations so that Godot, Unity, Unreal Engine, and future engine versions can be added without rebuilding the platform.

## Current target

- Palo Platform foundation
- Godot 3.x integration
- Windows first
- Small indie teams and friends
- GitHub as the initial source-control provider

## Long-term goal

A lightweight, affordable collaboration platform that lets game developers install the right Palo integration for their engine and version, then collaborate through a common Palo account and workspace.
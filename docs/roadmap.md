# Palo Roadmap

## Phase 0 — Platform Foundation

- [ ] Define Palo core and engine-integration boundaries
- [ ] Palo account system
- [ ] Workspace model
- [ ] Repository-to-workspace association
- [ ] Subscription/plan model
- [ ] Server-side membership and plan enforcement
- [ ] Cross-device session/access model
- [ ] Engine/version integration registry

## Phase 1 — Palo Installer / Launcher

- [ ] Palo desktop/launcher interface
- [ ] Sign up / sign in
- [ ] Choose game engine
- [ ] Detect or select engine version
- [ ] Show compatible Palo integrations
- [ ] Install/update/remove an integration
- [ ] Detect unsupported engine versions clearly

## Phase 2 — First Integration: Godot 3.x

- [x] Palo panel inside Godot
- [x] Git detection
- [x] Upload My Work
- [x] Get Team Updates
- [x] Create Backup
- [x] Team Activity Feed
- [ ] Connect the integration to Palo account/workspace
- [ ] Safe change review
- [ ] Conflict detection
- [ ] Conflict resolution UI

## Phase 3 — Team Collaboration

- [ ] Workspace invitations
- [ ] Member management
- [ ] Workspace administrator controls
- [ ] Contact Admin for Plan Upgrade flow
- [ ] Project management
- [ ] Improved sync experience
- [ ] Activity and notifications

## Phase 4 — Subscriptions

- [ ] Free personal plan — 1 person
- [ ] Team plan — 2–5 people — ₦1,200/year
- [ ] Team Plus — 6–20 people — ₦2,500/year
- [ ] Large Team — 21+ people — ₦4,500/year
- [ ] Payment provider integration
- [ ] Server-side payment verification
- [ ] Subscription expiry handling
- [ ] Upgrade/downgrade handling

## Phase 5 — More Engine Integrations

- [ ] Godot 4.x
- [ ] Unity
- [ ] Unreal Engine
- [ ] Version compatibility metadata
- [ ] Integration update mechanism

## Phase 6 — Advanced Collaboration

- [ ] Cloud backups
- [ ] Rich team workflows
- [ ] Additional source-control providers
- [ ] Additional engine integrations
- [ ] More advanced collaboration features

## Product rule

Palo is one platform with many engine integrations. Accounts, workspaces, subscriptions, and repository access are platform-level concepts. Godot, Unity, Unreal Engine, and future integrations should remain thin engine-specific layers.
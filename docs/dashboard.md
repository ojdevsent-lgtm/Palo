# Palo Dashboard

The Godot 3.x integration now exposes a first dashboard-style onboarding flow.

## Current flow

1. Connect GitHub with the existing Device Authorization Flow.
2. Load and filter the user's repositories.
3. Create a Palo workspace.
4. Choose the engine and engine version.
5. Associate the workspace with a GitHub repository.
6. View the workspace plan, repository, engine, and member count.
7. Select a workspace to inspect its details.
8. Continue using Git upload, pull/update, backup, and project-status tools.

## Current persistence

Workspace creation is stored locally at `user://palo_workspaces.json` so the UI can be tested immediately in Godot 3.x.

This local file is not authoritative. The production implementation will persist workspace metadata in Firebase Realtime Database and enforce membership/subscription limits on a trusted backend.

## Planned production flow

```text
Palo account
    ↓
Workspace
    ↓
Subscription
    ↓
Repository association
    ↓
Engine integration
    ↓
GitHub source control
```

The Free plan remains limited to one workspace member. Team access must be enforced server-side so the restriction cannot be bypassed by changing devices, Palo accounts, or GitHub accounts.

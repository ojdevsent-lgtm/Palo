# Palo Firebase backend

This directory contains the server-authoritative Firebase layer for Palo.

## Components

- `firebase/database.rules.json` locks workspace writes and the workspace index behind the trusted backend.
- `firebase/functions/index.js` provides callable functions for workspace creation, member addition, and access checks.
- `addons/palo/firebase_auth_manager.gd` exchanges the GitHub OAuth access token for a Firebase Authentication session.
- `addons/palo/palo_cloud_service.gd` calls Firebase Realtime Database and callable Functions from the Godot 3.x integration.

## Required Firebase setup

1. Create or use the Firebase project `palo-vx`.
2. Enable **Authentication → Sign-in method → GitHub**.
3. Add the GitHub OAuth client credentials required by Firebase's GitHub provider configuration.
4. Confirm Realtime Database is created in the expected region.
5. Put the Firebase web configuration in `user://palo_firebase.json` using `core/firebase_config.json.example` as the template. The `apiKey` is a Firebase web API key, not a service-account secret.

## Deploy the trusted backend

From a machine with the Firebase CLI and Node.js installed:

```text
firebase login
firebase use palo-vx
firebase deploy --config firebase/firebase.json --only database,functions
```

The callable functions are deployed to the configured Functions region. The Godot client currently uses `us-central1` in `palo_cloud_service.gd`; keep the backend in that region or change the client region before deployment.

## Security model

The Godot client must never contain a Firebase service-account key. Client requests authenticate with a Firebase ID token.

Workspace creation and membership changes are handled by Firebase Admin SDK code, which is trusted and is not subject to Realtime Database client rules. The database rules deny direct client writes to workspace records, members, subscriptions, and the user-workspace index.

The Free plan has a one-member limit. Team has five members, Team Plus has twenty, and Large Team is unlimited. The member-count check occurs in the trusted function transaction, so changing a local file, Godot account, device, or GitHub account does not bypass the workspace membership limit.

## Important current boundary

The backend is implemented in source control, but it is **not considered live until the Firebase deployment command has completed successfully** in the `palo-vx` project. Payment processing and plan upgrades are a later backend milestone; until then, newly created workspaces start on Free.

# Palo GitHub setup

Palo's current prototype uses GitHub's OAuth 2.0 Device Authorization flow for desktop sign-in. GitHub requires Device Flow to be enabled for the GitHub App before the sign-in button can work.

## Prototype setup

1. Create a GitHub App for Palo in GitHub Developer Settings.
2. Enable **Device Flow** in the app's user authorization settings.
3. Copy the app's **Client ID**. Palo only needs the Client ID; do not put a client secret in the Godot project.
4. Open Palo inside Godot and enter the Client ID.
5. Click **Connect GitHub**.
6. Palo opens GitHub's device authorization page and shows a verification code.
7. Approve Palo, then Palo loads the user's repositories.

## Current permissions

The prototype requests `repo` and `read:user` OAuth scopes because the next collaboration features need repository access and user identity. Permissions should be narrowed before a production release, with the final choice based on the exact GitHub App permissions and sync architecture.

## Important prototype limitation

The current token is stored in Godot's `user://palo_settings.json` so the prototype can reconnect. This is convenient for development but is not a production-grade credential vault. Before release, Palo should use safer platform-specific credential storage and support token expiry/refresh where the selected GitHub authorization configuration provides it.

## Why Device Flow

Palo is a desktop/editor tool and should not ship a GitHub client secret. GitHub documents Device Flow for desktop/headless-style applications and requires the app to poll at the interval returned by GitHub.

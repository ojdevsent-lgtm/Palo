# Palo Launcher

The launcher is the platform-level entry point for Palo. It is intentionally separate from engine integrations.

## Flow

1. Sign in to Palo.
2. Select a game engine.
3. Select the exact engine version.
4. Install or update the matching Palo integration.
5. Connect GitHub.
6. Select or create a Palo workspace.
7. Open the game project with its engine.

## Integration rule

The launcher must never install an incompatible integration. Engine and version are resolved against `core/integration_manifest.json`.

The first production integration is Godot 3.x under `addons/palo`.

Future integrations:

- Godot 4.x
- Unity
- Unreal Engine

## Security

The launcher uses the Palo Firebase account for identity and workspace metadata. GitHub OAuth remains the source-control authorization layer. Workspace membership and subscription limits are enforced by the trusted Firebase backend.

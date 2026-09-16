# Palo Core

This directory contains platform-level concepts shared by every Palo engine integration.

The core is intentionally engine-independent.

Planned responsibilities:

- account identity
- workspaces
- subscriptions
- membership and access control
- repository associations
- engine integration registry
- cross-device sessions

Engine-specific code belongs under `integrations/`.

The current implementation remains compatible with the existing Godot 3.x plugin while this platform layer is introduced incrementally.
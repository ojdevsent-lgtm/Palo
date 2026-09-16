# Palo Engine Integrations

Engine integrations are thin adapters installed into supported game engines.

## Integration contract

Each integration should declare:

- engine identifier
- supported engine versions
- Palo integration version
- installation location/method
- minimum required Palo platform version

## Initial integrations

- Godot 3.x — existing implementation
- Godot 4.x — planned
- Unity — planned
- Unreal Engine — planned

The platform should select an integration based on the user's engine and version instead of embedding engine-specific logic into Palo Core.
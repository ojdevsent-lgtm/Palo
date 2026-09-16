# Palo Admin Dashboard

The admin dashboard is a separate trusted web surface for aggregate product operations.

## Metrics

- Total users
- Active users
- Total workspaces
- Paid workspaces
- Users by country
- Users by region
- Workspaces by engine
- Workspaces by plan

## Security model

Admin access is based on the Firebase Auth custom claim `admin: true`. The client never decides who is an administrator.

`getAdminMetrics` is a callable Firebase function and rejects callers without the admin claim.

`setWorkspacePlan` is also admin-only. This keeps subscription state out of client-controlled database writes.

## Privacy

The dashboard uses aggregates and coarse country/region fields. Palo does not require precise location for these metrics.

## Payment boundary

Payment-provider credentials and webhook secrets must stay in the trusted backend environment. They must never be committed to GitHub or embedded in the Godot plugin.

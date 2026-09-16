# Palo Payment Provider Contract

Palo subscriptions are controlled by the trusted Firebase backend.

## Required payment flow

1. User selects a workspace and plan.
2. Palo creates a payment request through a future supported provider.
3. Provider processes the payment.
4. Palo backend verifies the transaction using the provider's server API/webhook.
5. Only after verification does trusted backend code call the equivalent of `setWorkspacePlan`.
6. Firebase stores the resulting subscription state.
7. Workspace membership limits immediately use the verified plan.

## Security requirements

- Never put a payment secret key in the Godot plugin.
- Never let the client write `plan_id`.
- Never treat a successful client-side payment redirect as proof of payment.
- Verify transaction/reference, amount, currency, status, workspace and intended plan on the server.
- Keep provider credentials in deployment secrets.

The repository currently contains the subscription contract and trusted plan mutation endpoint. A payment provider adapter must be selected before production payment processing is enabled.

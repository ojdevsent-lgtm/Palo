# Palo Firebase Setup

Palo uses Firebase Authentication for Palo account identity and Firebase Realtime Database for account/workspace metadata. GitHub remains the source-control provider for game repositories.

## Firebase project

Configured project:

- Project ID: `palo-vx`
- Auth domain: `palo-vx.firebaseapp.com`
- Realtime Database: `https://palo-vx-default-rtdb.europe-west1.firebasedatabase.app`

## Web app configuration

Copy `core/firebase_config.json.example` to a local configuration file and fill in the Firebase Web API key from Firebase Console → Project settings → Your apps.

Do not commit private service-account credentials or OAuth client secrets.

## Authentication

In Firebase Console:

1. Open Authentication.
2. Enable the GitHub provider under Sign-in method.
3. Configure the GitHub OAuth application using the callback URL shown by Firebase.

Firebase Authentication identifies the Palo account. The existing Palo GitHub client is a separate GitHub API authorization flow and should not be treated as the Firebase identity token.

## Realtime Database

Create the Realtime Database in Firebase Console. Palo stores metadata such as:

- users
- workspaces
- workspace members
- repository associations
- subscription state

Actual game files remain in GitHub repositories.

## Security

Client-side plan checks are only a UI convenience. The authoritative membership and subscription rules must be enforced server-side so users cannot bypass a Free-plan one-person limit by changing accounts or devices.

The database schema contract is defined in `core/firebase_data_contract.json`.

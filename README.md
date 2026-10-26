# Interior City FXServer

Copy `.env.example` to `.env` in this directory, then fill in fresh credentials. `start.bat` loads `.env` automatically. Variables already set in the Windows process environment take precedence over `.env`.

Configure these variables:

| Variable | Required | Purpose |
| --- | --- | --- |
| `CFX_SERVER_KEY` | Yes | Cfx.re server license key |
| `STEAM_WEB_API_KEY` | No | Steam authentication identifiers |
| `INTERIOR_CITY_WEBHOOK_LOGS` | No | Admin and vehicle event logs |
| `INTERIOR_CITY_WEBHOOK_BUGS` | No | In-game bug reports |

The optional webhook features are skipped when their variables are empty. The launcher expects `artifacts/FXServer.exe` two directories above this repository, matching the current project layout. It passes the values to FXServer as server-only convars; do not use `setr` or `sets` for these secrets. Command-line arguments may be visible to administrators of the host, so restrict access to the server process and its logs.

`config/keys.cfg` is no longer loaded. `.env` is ignored by Git; `.env.example` contains no credentials and is versioned. If starting FXServer without `start.bat`, provide the corresponding `+set` options through your deployment system before `+exec config/config.cfg`.

The license key, Steam key, and Discord webhook URLs present in the old initial commit must be revoked and replaced in their respective provider consoles. A later commit that deletes those strings would still send the old secret in Git history; publish only the replacement root commit.

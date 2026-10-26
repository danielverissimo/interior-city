# Interior City FXServer

`start.bat` starts the server using values supplied by the Windows process environment. Configure these variables in the server host or deployment environment before launching it:

| Variable | Required | Purpose |
| --- | --- | --- |
| `CFX_SERVER_KEY` | Yes | Cfx.re server license key |
| `STEAM_WEB_API_KEY` | No | Steam authentication identifiers |
| `INTERIOR_CITY_WEBHOOK_LOGS` | No | Admin and vehicle event logs |
| `INTERIOR_CITY_WEBHOOK_BUGS` | No | In-game bug reports |

The optional webhook features are skipped when their variables are empty. The launcher expects `artifacts/FXServer.exe` two directories above this repository, matching the current project layout. It passes the values to FXServer as server-only convars; do not use `setr` or `sets` for these secrets. Command-line arguments may be visible to administrators of the host, so restrict access to the server process and its logs.

`config/keys.cfg` is no longer loaded. Keep local `.env` files and key files out of Git. If starting FXServer without `start.bat`, provide the corresponding `+set` options through your deployment system before `+exec config/config.cfg`.

The license key, Steam key, and Discord webhook URLs present in the old initial commit must be revoked and replaced in their respective provider consoles. A later commit that deletes those strings would still send the old secret in Git history; publish only the replacement root commit.

#!/usr/bin/env bash
set -euo pipefail
umask 077
[[ "$(id -u)" -eq 0 ]] || { echo 'Run with sudo on Uriel.' >&2; exit 1; }
root=/opt/uriel/interior-city-tocado
scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
incoming="${1:-}"
names=(db_root_password db_app_password cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key resource_secrets.json)
if [[ -n "$incoming" ]]; then
  python3 "$scripts/configure-secrets.py" --directory "$incoming" \
    --schema "$scripts/../config/resource-secrets.schema.json" check
  # An existing database/credential must never be rotated by provisioning.
  for name in "${names[@]}"; do
    [[ -f "$incoming/$name" && ! -L "$incoming/$name" ]] || { echo 'Invalid staged private files.' >&2; exit 1; }
    if [[ -e "$root/secrets/$name" ]] && ! cmp -s "$incoming/$name" "$root/secrets/$name"; then
      echo 'Existing private configuration differs; rotate it explicitly after review.' >&2; exit 1
    fi
  done
fi
install -d -m 0700 "$root" "$root/secrets" "$root/state" "$root/state/txData" \
  "$root/state/kvp" "$root/state/resources" "$root/state/resources/radio" "$root/state/resources/vrp" "$root/state/manifests" "$root/releases" "$root/backups"
chown -R 1000:1000 "$root/state/txData" "$root/state/kvp" "$root/state/resources"
if [[ -n "$incoming" ]]; then
  for name in "${names[@]}"; do install -o root -g root -m 0444 "$incoming/$name" "$root/secrets/$name"; done
fi
python3 "$scripts/configure-secrets.py" --directory "$root/secrets" \
  --schema "$scripts/../config/resource-secrets.schema.json" init
if [[ ! -f "$root/.env" ]]; then
  cat > "$root/.env" <<'EOF'
COMPOSE_PROJECT_NAME=interior-city-tocado
INTERIOR_CITY_RELEASE_PATH=/opt/uriel/interior-city-tocado/current
INTERIOR_CITY_TXADMIN_PORT=40121
FIVEM_LISTING_ENABLED=false
PLAYIT_PUBLIC_ENDPOINT=
PLAYIT_HTTPS_HOST=
IC_ASSET_PROFILE=core
ASSET_STORE=/srv/diskaux/interior-city-assets
EOF
fi
chmod 0600 "$root/.env"
echo 'Isolated Uriel directories initialized. Configure private licenses before deploying.'
echo 'No containers started and no credentials copied from the previous base.'

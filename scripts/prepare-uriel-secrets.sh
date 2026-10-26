#!/usr/bin/env bash
set -euo pipefail
umask 077

root=/opt/uriel/interior-city
[[ "$(id -u)" -eq 0 ]] || { echo 'Run with sudo on Uriel.' >&2; exit 1; }
install -d -m 0700 "$root/secrets" "$root/backups" "$root/state" "$root/state/txData" "$root/state/cache" "$root/releases" "$root/state/manifests"
chown root:root "$root/secrets"
chown 1000:1000 "$root/state/txData" "$root/state/cache"

write_secret() {
  local name="$1" value
  read -r -s -p "$name (input hidden): " value
  printf '\n'
  printf '%s' "$value" > "$root/secrets/$name"
  chmod 0444 "$root/secrets/$name"
}

if [[ ! -e "$root/secrets/db_root_password" ]]; then
  openssl rand -hex 24 > "$root/secrets/db_root_password"
  chmod 0444 "$root/secrets/db_root_password"
fi
if [[ ! -e "$root/secrets/db_app_password" ]]; then
  openssl rand -hex 24 > "$root/secrets/db_app_password"
  chmod 0444 "$root/secrets/db_app_password"
fi

for name in cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key; do
  if [[ ! -e "$root/secrets/$name" ]]; then write_secret "$name"; fi
done
for name in cfx_license playit_agent_key; do
  [[ -s "$root/secrets/$name" ]] || { echo "Required secret is empty: $name" >&2; exit 1; }
done
chown root:root "$root/secrets/"*
chmod 0444 "$root/secrets/"*

if [[ ! -e "$root/.env" ]]; then
  cat > "$root/.env" <<'EOF'
INTERIOR_CITY_RELEASE_PATH=/opt/uriel/interior-city/current
PLAYIT_PUBLIC_ENDPOINT=
PLAYIT_HTTPS_HOST=
EOF
  chmod 0600 "$root/.env"
fi

echo 'Private secret files and nonsecret deployment configuration are ready.'

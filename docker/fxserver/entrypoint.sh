#!/usr/bin/env bash
set -euo pipefail
umask 077

secret() {
  local path="/run/secrets/$1"
  if [[ ! -r "$path" ]]; then
    printf 'Missing Docker secret: %s\n' "$1" >&2
    exit 1
  fi
  cat "$path"
}

valid_cfg_value() {
  local name="$1" value="$2"
  if [[ "$value" == *'"'* || "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    printf 'Invalid characters in %s\n' "$name" >&2
    exit 1
  fi
}

license="$(secret cfx_license)"
db_password="$(secret db_app_password)"
steam_key="$(secret steam_web_api)"
webhook_logs="$(secret webhook_logs)"
webhook_bugs="$(secret webhook_bugs)"

[[ "$license" =~ ^cfxk_[A-Za-z0-9_-]+$ ]] || { echo 'A fresh Cfx license key is required.' >&2; exit 1; }
[[ "$db_password" =~ ^[0-9a-fA-F]{48}$ ]] || { echo 'Database password must be 24 random bytes encoded as hex.' >&2; exit 1; }
if [[ -n "$steam_key" && ! "$steam_key" =~ ^[0-9a-fA-F]{32}$ ]]; then
  echo 'Steam Web API key must contain 32 hexadecimal characters.' >&2
  exit 1
fi
valid_cfg_value webhook_logs "$webhook_logs"
valid_cfg_value webhook_bugs "$webhook_bugs"

mkdir -p /server-data/runtime
{
  printf 'set sv_licenseKey "%s"\n' "$license"
  printf 'set mysql_connection_string "mysql://vrp:%s@db:3306/vrp?multipleStatements=true"\n' "$db_password"
  if [[ -n "$steam_key" ]]; then printf 'set steam_webApiKey "%s"\n' "$steam_key"; fi
  if [[ -n "$webhook_logs" ]]; then printf 'set interior_city_webhook_logs "%s"\n' "$webhook_logs"; fi
  if [[ -n "$webhook_bugs" ]]; then printf 'set interior_city_webhook_bugs "%s"\n' "$webhook_bugs"; fi
} > /server-data/runtime/secrets.cfg
chmod 0600 /server-data/runtime/secrets.cfg

public_endpoint="${PLAYIT_PUBLIC_ENDPOINT:-}"
https_host="${PLAYIT_HTTPS_HOST:-}"
if [[ -n "$public_endpoint" || -n "$https_host" ]]; then
  [[ "$public_endpoint" =~ ^[0-9.]+:[0-9]+$ && "$https_host" =~ ^[A-Za-z0-9.-]+$ ]] || {
    echo 'Both PLAYIT_PUBLIC_ENDPOINT (IPv4:port) and PLAYIT_HTTPS_HOST are required for listing.' >&2
    exit 1
  }
  {
    printf 'set sv_forceIndirectListing true\n'
    printf 'set sv_listingHostOverride "%s"\n' "$https_host"
    printf 'set sv_endpoints "%s"\n' "$public_endpoint"
  } > /server-data/runtime/listing.cfg
else
  : > /server-data/runtime/listing.cfg
fi
chmod 0600 /server-data/runtime/listing.cfg

cd /server-data
exec /opt/fxserver/run.sh

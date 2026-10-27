#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
sha="${1:-}"; archive="${2:-}"
[[ "$(id -u)" -eq 0 && "$sha" =~ ^[0-9a-f]{40}$ && -f "$archive" ]] || {
  echo 'Run as root with commit SHA and staged code archive.' >&2; exit 2;
}
root=/opt/uriel/interior-city-tocado
helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/release.py"
[[ -f "$helper" && -f "$root/.env" && -d "$root/secrets" ]] || {
  echo 'Run prepare-uriel-secrets.sh and configure private credentials first.' >&2; exit 1;
}
exec 9>"$root/state/deploy.lock"
flock -n 9 || { echo 'Another deployment is running.' >&2; exit 1; }
[[ "$(stat -c '%U:%a' "$root/secrets")" == root:700 ]] || { echo 'Private secret directory permissions required.' >&2; exit 1; }
# Read only supported, non-executable settings. Never source deployment .env.
setting() { sed -n "s/^$1=//p" "$root/.env" | tail -n 1; }
[[ "$(setting COMPOSE_PROJECT_NAME)" == interior-city-tocado ]] || { echo 'Unexpected Compose project.' >&2; exit 1; }
[[ "$(setting INTERIOR_CITY_RELEASE_PATH)" == "$root/current" ]] || { echo 'Unexpected release root.' >&2; exit 1; }
profile="$(setting IC_ASSET_PROFILE)"; store="$(setting ASSET_STORE)"
[[ "$profile" == core || "$profile" == full ]] || { echo 'Invalid asset profile.' >&2; exit 1; }
[[ "$store" == /srv/diskaux/interior-city-assets ]] || { echo 'Unexpected private asset store.' >&2; exit 1; }
[[ "$(setting FIVEM_LISTING_ENABLED)" == false ]] || { echo 'Public listing requires a separately reviewed change.' >&2; exit 1; }
endpoint="$(setting PLAYIT_PUBLIC_ENDPOINT)"; https_host="$(setting PLAYIT_HTTPS_HOST)"
profiles=()
if [[ -n "$endpoint" || -n "$https_host" ]]; then
  [[ "$endpoint" =~ ^[0-9.]+:[0-9]+$ && "$https_host" =~ ^[A-Za-z0-9.-]+$ ]] || { echo 'Configure both Playit endpoints together.' >&2; exit 1; }
  [[ -s "$root/secrets/playit_agent_key" ]] || { echo 'Playit agent credential is required for public test access.' >&2; exit 1; }
  profiles=(--profile public --profile listing)
fi
compose_at() {
  local release="$1"; shift
  INTERIOR_CITY_RELEASE_PATH="$release" COMPOSE_PROJECT_NAME=interior-city-tocado \
    docker compose --env-file "$root/.env" --project-directory "$root" -p interior-city-tocado \
    -f "$release/compose.yaml" ${profiles[@]+"${profiles[@]}"} "$@"
}
old=''
if [[ -L "$root/current" ]]; then
  old="$(readlink -f "$root/current")"
  [[ "$old" =~ ^$root/releases/[0-9a-f]{40}$ ]] || { echo 'Invalid current release link.' >&2; exit 1; }
  python3 "$helper" manifest "$old" "$root/state/manifests/${old##*/}.json" --check
elif [[ -e "$root/current" ]]; then
  echo 'Current release must be a managed symlink.' >&2; exit 1
fi
release="$root/releases/$sha"
if [[ ! -e "$release" ]]; then
  incoming="$(mktemp -d "$root/releases/.incoming-$sha.XXXXXX")"
  trap 'rm -rf "$incoming"' EXIT
  python3 "$helper" extract "$archive" "$incoming"
  python3 "$incoming/scripts/configure-secrets.py" --directory "$root/secrets" check
  python3 "$incoming/scripts/assets.py" sync --store "$store" --profile "$profile" \
    --lock "$incoming/assets.lock.json" --destination "$incoming"
  python3 "$incoming/scripts/assets.py" verify --profile "$profile" --lock "$incoming/assets.lock.json" --destination "$incoming"
  python3 "$helper" manifest "$incoming" "$root/state/manifests/$sha.json"
  chown -R 1000:1000 "$incoming"
  mv "$incoming" "$release"
  trap - EXIT
else
  python3 "$helper" manifest "$release" "$root/state/manifests/$sha.json" --check
  python3 "$release/scripts/configure-secrets.py" --directory "$root/secrets" check
  python3 "$release/scripts/assets.py" verify --profile "$profile" --lock "$release/assets.lock.json" --destination "$release"
fi
for name in db_root_password db_app_password cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key resource_convars; do
  [[ -f "$root/secrets/$name" && ! -L "$root/secrets/$name" && "$(stat -c '%U:%a' "$root/secrets/$name")" == root:444 ]] || {
    echo "Invalid private file ownership/mode: $name" >&2; exit 1;
  }
done
# Validate/build the candidate before stopping a currently running release.
compose_at "$release" config --quiet
compose_at "$release" build
restore_old() {
  trap - ERR
  if [[ -n "$old" ]]; then
    ln -sfn "$old" "$root/current.next"; mv -Tf "$root/current.next" "$root/current"
    compose_at "$old" up -d --build --force-recreate --wait --wait-timeout 180 || {
      echo 'Rollback restart failed; inspect private container logs.' >&2; return 1;
    }
    echo 'Previous code release restored. Database was not rolled back.' >&2
  else
    compose_at "$release" down --remove-orphans || true
    rm -f "$root/current"
  fi
}
if [[ -n "$old" ]]; then
  # Stop writers for a consistent predeploy database/txAdmin snapshot.
  trap restore_old ERR
  compose_at "$old" --profile public --profile listing stop connect_proxy playit fxserver
  compose_at "$old" run --rm --no-deps backup predeploy
fi
trap restore_old ERR
ln -sfn "releases/$sha" "$root/current.next"; mv -Tf "$root/current.next" "$root/current"
compose_at "$release" up -d --force-recreate --remove-orphans --wait --wait-timeout 180
trap - ERR
printf 'Installed %s; previous release: %s. Validate game resources and a real player separately.\n' "$sha" "${old:-none}"

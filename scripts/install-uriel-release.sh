#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
sha="${1:-}"; archive="${2:-}"
schema_mode=--no-schema
schema_option=''
config_cutover=false
for option in "${@:3}"; do
  case "$option" in
    --no-schema|--ic-admin-schema|--ic-admin-cutover)
      [[ -z "$schema_option" || "$schema_option" == "$option" ]] || { echo 'Conflicting schema flags.' >&2; exit 2; }
      schema_option="$option"; schema_mode="$option" ;;
    --ic-config-cutover) config_cutover=true ;;
    *) echo 'Supported flags: --ic-admin-schema, --ic-admin-cutover, --ic-config-cutover.' >&2; exit 2 ;;
  esac
done
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
asset_origin="$(setting IC_ASSETS_BASE_URL)"
if [[ -z "$asset_origin" && -n "$https_host" ]]; then asset_origin="https://$https_host"; fi
profiles=()
if [[ -n "$endpoint" || -n "$https_host" ]]; then
  [[ "$endpoint" =~ ^[0-9.]+:[0-9]+$ && "$https_host" =~ ^[A-Za-z0-9.-]+$ ]] || { echo 'Configure both Playit endpoints together.' >&2; exit 1; }
  [[ -s "$root/secrets/playit_agent_key" ]] || { echo 'Playit agent credential is required for public test access.' >&2; exit 1; }
  profiles=(--profile public --profile listing)
fi
compose_at() {
  local release="$1"; shift
  local runtime_override=()
  if [[ -f "$root/state/compose.runtime.yaml" ]]; then
    runtime_override=(-f "$root/state/compose.runtime.yaml")
  fi
  if [[ -f "$root/state/ic-config/overlays/${release##*/}.yaml" ]]; then
    runtime_override+=(-f "$root/state/ic-config/overlays/${release##*/}.yaml")
  fi
  INTERIOR_CITY_RELEASE_PATH="$release" COMPOSE_PROJECT_NAME=interior-city-tocado \
    docker compose --env-file "$root/.env" --project-directory "$root" -p interior-city-tocado \
    -f "$release/compose.yaml" ${runtime_override[@]+"${runtime_override[@]}"} ${profiles[@]+"${profiles[@]}"} "$@"
}
old=''
if [[ -f "$root/state/ic-config/selection.json" && "$config_cutover" != true ]]; then
  echo 'Own configuration state exists; use --ic-config-cutover for a forward fix. Legacy rollback requires reconciliation.' >&2; exit 1
fi
if [[ -L "$root/current" ]]; then
  old="$(readlink -f "$root/current")"
  [[ "$old" =~ ^$root/releases/[0-9a-f]{40}$ ]] || { echo 'Invalid current release link.' >&2; exit 1; }
  if [[ "$config_cutover" == true || -f "$root/state/ic-config/selection.json" ]]; then
    admin_state=()
    if [[ "$schema_mode" == --ic-admin-cutover ]]; then admin_state=(--allow-ic-admin-state); fi
    python3 -B "$(dirname "${BASH_SOURCE[0]}")/ic-config-cutover.py" check-previous --root "$root" --previous "$old" ${admin_state[@]+"${admin_state[@]}"}
  elif [[ "$schema_mode" == --ic-admin-cutover ]]; then
    # Only the explicit operational migrator can approve mutable legacy JSON drift.
    python3 -B "$(dirname "${BASH_SOURCE[0]}")/ic-admin-cutover.py" check-previous --root "$root" --previous "$old"
  else
    python3 "$helper" manifest "$old" "$root/state/manifests/${old##*/}.json" --check
  fi
elif [[ -e "$root/current" ]]; then
  echo 'Current release must be a managed symlink.' >&2; exit 1
fi
release="$root/releases/$sha"
if [[ ! -e "$release" ]]; then
  incoming="$(mktemp -d "$root/releases/.incoming-$sha.XXXXXX")"
  trap 'rm -rf "$incoming"' EXIT
  python3 "$helper" extract "$archive" "$incoming"
  if [[ -f "$incoming/config/ic_config_release.json" && "$config_cutover" != true ]]; then
    echo 'This candidate requires explicit --ic-config-cutover.' >&2; exit 1
  fi
  python3 "$incoming/scripts/configure-secrets.py" --directory "$root/secrets" check
  reuse_assets=()
  if [[ -n "$old" ]]; then reuse_assets=(--reuse-from "$old"); fi
  python3 "$incoming/scripts/assets.py" sync --store "$store" --profile "$profile" \
    --lock "$incoming/assets.lock.json" --destination "$incoming" ${reuse_assets[@]+"${reuse_assets[@]}"}
  python3 "$incoming/scripts/assets.py" verify --profile "$profile" --lock "$incoming/assets.lock.json" --destination "$incoming"
  # Render code only in the isolated candidate, before sealing its pristine manifest.
  # Never touch the previous release or URLs intentionally pointing at another CDN.
  if [[ -f "$incoming/scripts/web-assets.py" ]]; then
    if [[ -f "$root/state/www.manifest.json" ]]; then
      python3 "$incoming/scripts/web-assets.py" aliases --destination "$root/state/www"
    fi
    python3 "$incoming/scripts/web-assets.py" configure --release "$incoming" \
      --base-url "$asset_origin" --media "$root/state/www"
  fi
  if [[ "$config_cutover" == true ]]; then
    python3 -B "$incoming/scripts/ic-config-cutover.py" configure-candidate --root "$root" --release "$incoming"
  fi
  python3 "$helper" manifest "$incoming" "$root/state/manifests/$sha.json"
  chown -R 1000:1000 "$incoming"
  mv "$incoming" "$release"
  trap - EXIT
else
  python3 "$helper" manifest "$release" "$root/state/manifests/$sha.json" --check
  python3 "$release/scripts/configure-secrets.py" --directory "$root/secrets" check
  python3 "$release/scripts/assets.py" verify --profile "$profile" --lock "$release/assets.lock.json" --destination "$release"
  if [[ -f "$release/scripts/web-assets.py" ]]; then
    if [[ -f "$root/state/www.manifest.json" ]]; then
      python3 "$release/scripts/web-assets.py" aliases --destination "$root/state/www"
    fi
    python3 "$release/scripts/web-assets.py" configure --release "$release" \
      --base-url "$asset_origin" --media "$root/state/www"
  fi
fi
if [[ ( -f "$release/config/ic_config_release.json" || -f "$release/config/ic_config_runtime.cfg" ) && "$config_cutover" != true ]]; then
  echo 'An IC Config candidate requires explicit --ic-config-cutover, including forward fixes.' >&2; exit 1
fi
if [[ -f "$release/config/ic_admin.cfg" ]] && rg_mode="$(sed -n 's/^setr ic_admin_mode "\([^"]*\)"/\1/p' "$release/config/ic_admin.cfg")" && [[ "$rg_mode" == active && "$schema_mode" != --ic-admin-cutover ]]; then
  echo 'Active IC Admin requires explicit --ic-admin-cutover migration/forward-fix verification.' >&2; exit 1
fi
for name in db_root_password db_app_password cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key resource_convars; do
  [[ -f "$root/secrets/$name" && ! -L "$root/secrets/$name" && "$(stat -c '%U:%a' "$root/secrets/$name")" == root:444 ]] || {
    echo "Invalid private file ownership/mode: $name" >&2; exit 1;
  }
done
mkdir -p "$root/state/kvp" "$root/state/resources/radio" "$root/state/resources/vrp"
mkdir -p "$root/state/resources/m_desmanche"
desmanche_state="$root/state/resources/m_desmanche/config.json"
[[ ! -L "$root/state/resources/m_desmanche" && ! -L "$desmanche_state" ]] || { echo 'Persistent dismantling configuration must not use symlinks.' >&2; exit 1; }
desmanche_source="${old:-$release}/resources/[scripts]/m_desmanche/config.json"
if [[ -n "$old" ]]; then
  fxserver_id="$(docker ps -a --filter label=com.docker.compose.project=interior-city-tocado --filter label=com.docker.compose.service=fxserver -q)"
  if [[ -n "$fxserver_id" ]]; then
    mounted_config="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/server-data/resources/[scripts]/m_desmanche/config.json"}}{{.Source}}{{end}}{{end}}' "$fxserver_id")"
    [[ -z "$mounted_config" || "$mounted_config" == "$desmanche_state" ]] || { echo 'Unexpected dismantling configuration mount.' >&2; exit 1; }
    if [[ -n "$mounted_config" ]]; then desmanche_source="$desmanche_state"; fi
  fi
fi
preserve_desmanche() {
  [[ -f "$desmanche_source" && ! -L "$desmanche_source" ]] || { echo 'Missing authoritative dismantling configuration.' >&2; return 1; }
  python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); assert isinstance(v,dict) and isinstance(v.get("settings"),dict) and isinstance(v.get("desmanches"),list)' "$desmanche_source"
  if [[ "$desmanche_source" != "$desmanche_state" ]]; then cp "$desmanche_source" "$desmanche_state"; fi
  chown 1000:1000 "$desmanche_state"; chmod 0600 "$desmanche_state"
}
preserve_desmanche
[[ ! -L "$root/state/resources/vrp" ]] || { echo 'Persistent vRP groups must not use symlinks.' >&2; exit 1; }
if [[ ! -f "$root/state/resources/radio/private_radios.json" ]]; then
  cp "$release/resources/[voip]/radio/private_radios.json" "$root/state/resources/radio/private_radios.json"
fi
groups_source="${old:-$release}/resources/[vrp]/vrp/cfg/groups.json"
if [[ -e "$root/state/resources/vrp/groups.json" ]]; then
  [[ -f "$root/state/resources/vrp/groups.json" && ! -L "$root/state/resources/vrp/groups.json" ]] || { echo 'Invalid persistent vRP groups file.' >&2; exit 1; }
  groups_source="$root/state/resources/vrp/groups.json"
fi
[[ -f "$groups_source" && ! -L "$groups_source" ]] || { echo 'Existing vRP groups must be preserved before deployment.' >&2; exit 1; }
python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); assert isinstance(v,dict) and isinstance(v.get("groups"),list)' "$groups_source"
chown -R 1000:1000 "$root/state/kvp" "$root/state/resources"
chmod 0600 "$root/state/resources/radio/private_radios.json"
install -m 0600 "$release/compose.runtime.yaml" "$root/state/compose.runtime.yaml"
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
  # Refresh after stopping writers so the backup and both releases use the final edit.
  preserve_desmanche
  # Refresh from the authoritative old release only after all writers stop.
  if [[ ! -e "$root/state/resources/vrp/groups.json" ]]; then
    cp "$groups_source" "$root/state/resources/vrp/groups.json"
    chown 1000:1000 "$root/state/resources/vrp/groups.json"
    chmod 0600 "$root/state/resources/vrp/groups.json"
  fi
  compose_at "$old" run --rm --no-deps backup predeploy
fi
if [[ ! -e "$root/state/resources/vrp/groups.json" ]]; then
  cp "$groups_source" "$root/state/resources/vrp/groups.json"
  chown 1000:1000 "$root/state/resources/vrp/groups.json"
fi
chmod 0600 "$root/state/resources/vrp/groups.json"
python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); assert isinstance(v,dict) and isinstance(v.get("groups"),list)' "$root/state/resources/vrp/groups.json"
trap restore_old ERR
if [[ "$schema_mode" == --ic-admin-schema ]]; then
  # Explicit opt-in only, after the old writers stop and their backup succeeds.
  # DDL is additive and is deliberately NOT undone by a code rollback.
  python3 "$release/scripts/ic-admin-migrate.py" --env-file "$root/.env" \
    --project-name interior-city-tocado --project-directory "$root" \
    --compose-file "$release/compose.yaml" schema --apply --writers-stopped
fi
if [[ "$schema_mode" == --ic-admin-cutover ]]; then
  python3 -B "$release/scripts/ic-admin-cutover.py" prepare --root "$root" --previous "$old" --release "$release"
fi
if [[ "$config_cutover" == true ]]; then
  [[ -n "$old" ]] || { echo 'IC Config cutover requires an existing managed release to import.' >&2; exit 1; }
  python3 -B "$release/scripts/ic-config-cutover.py" prepare --root "$root" --previous "$old" --release "$release"
  compose_at "$release" config --quiet
fi
ln -sfn "releases/$sha" "$root/current.next"; mv -Tf "$root/current.next" "$root/current"
stop_candidate() {
  trap - ERR
  compose_at "$release" --profile public --profile listing stop connect_proxy playit fxserver || true
  echo 'Candidate stopped after startup failure. State retained; inspect reports and reconcile before any rollback.' >&2
}
if [[ "$config_cutover" == true ]]; then
  python3 -B "$release/scripts/ic-config-cutover.py" mark-starting --root "$root" --release "$release"
  trap stop_candidate ERR
fi
compose_at "$release" up -d --force-recreate --remove-orphans --wait --wait-timeout 180
if [[ "$schema_mode" == --ic-admin-cutover ]]; then
  # Do not automatically restore code over new operational data after starting writers.
  if [[ "$config_cutover" != true ]]; then trap - ERR; fi
  python3 -B "$release/scripts/ic-admin-cutover.py" verify-runtime --root "$root" --release "$release"
fi
if [[ "$config_cutover" == true ]]; then
  python3 -B "$release/scripts/ic-config-cutover.py" verify-runtime --root "$root" --release "$release"
fi
trap - ERR
printf 'Installed %s; previous release: %s. Validate game resources and a real player separately.\n' "$sha" "${old:-none}"

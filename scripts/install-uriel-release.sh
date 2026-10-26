#!/usr/bin/env bash
set -euo pipefail
umask 077

sha="${1:-}"
archive="${2:-}"
[[ "$(id -u)" -eq 0 && "$sha" =~ ^[0-9a-f]{40}$ && -f "$archive" ]] || {
  echo 'Run as root with a commit SHA and staged archive.' >&2
  exit 2
}

root=/opt/uriel/interior-city
[[ "$(stat -c '%U:%a' "$root/secrets")" == 'root:700' ]] || {
  echo 'Secret directory must be root-owned with mode 0700.' >&2
  exit 1
}
for name in db_root_password db_app_password cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key; do
  [[ -f "$root/secrets/$name" ]] || { echo "Missing secret file: $name" >&2; exit 1; }
  [[ "$(stat -c '%U:%a' "$root/secrets/$name")" == 'root:444' ]] || {
    echo "Incorrect Docker secret file ownership or mode: $name (run the preparation script)." >&2
    exit 1
  }
done
for name in db_root_password db_app_password cfx_license playit_agent_key; do
  [[ -s "$root/secrets/$name" ]] || { echo "Required secret is empty: $name" >&2; exit 1; }
done
[[ -f "$root/.env" ]] || { echo 'Missing Uriel deployment .env.' >&2; exit 1; }
public_endpoint="$(sed -n 's/^PLAYIT_PUBLIC_ENDPOINT=//p' "$root/.env" | tail -n 1)"
https_host="$(sed -n 's/^PLAYIT_HTTPS_HOST=//p' "$root/.env" | tail -n 1)"
if [[ -n "$public_endpoint" || -n "$https_host" ]]; then
  [[ "$public_endpoint" =~ ^[0-9.]+:[0-9]+$ && "$https_host" =~ ^[A-Za-z0-9.-]+$ ]] || {
    echo 'Configure both Playit endpoints together in Uriel .env.' >&2
    exit 1
  }
fi

compose() {
  local profiles=(--profile public)
  if grep -Eq '^PLAYIT_HTTPS_HOST=[A-Za-z0-9.-]+$' "$root/.env"; then
    profiles+=(--profile listing)
  fi
  docker compose --env-file "$root/.env" --project-directory "$root" -f "$root/current/compose.yaml" "${profiles[@]}" "$@"
}

old=''
if [[ -L "$root/current" ]]; then
  old="$(readlink "$root/current")"
  old_sha="${old##*/}"
  [[ -f "$root/state/manifests/$old_sha.sha256" ]] || {
    echo 'Current release lacks its pristine manifest.' >&2
    exit 1
  }
  (cd "$root/current" && sha256sum --status -c "$root/state/manifests/$old_sha.sha256") || {
    echo 'Current release files changed, possibly by txAdmin. Review them before deployment.' >&2
    exit 1
  }
fi

release="$root/releases/$sha"
if [[ ! -d "$release" ]]; then
  incoming="$root/releases/.incoming-$sha-$$"
  mkdir "$incoming"
  trap 'rm -rf "$incoming"' EXIT
  tar -xf "$archive" -C "$incoming" --no-same-owner
  (cd "$incoming" && find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$root/state/manifests/$sha.sha256"
  chown -R 1000:1000 "$incoming"
  mv "$incoming" "$release"
  trap - EXIT
elif [[ -f "$root/state/manifests/$sha.sha256" ]]; then
  (cd "$release" && sha256sum --status -c "$root/state/manifests/$sha.sha256") || {
    echo 'Target release files differ from their pristine manifest.' >&2
    exit 1
  }
else
  echo 'Target release lacks its pristine manifest.' >&2
  exit 1
fi
for path in server.cfg config/config.cfg config/resources.cfg \
  resources/oxmysql/fxmanifest.lua resources/vrp_oxmysql/fxmanifest.lua \
  'resources/[vRP]/vrp/fxmanifest.lua'; do
  [[ -f "$release/$path" ]] || { echo "Missing FXServer file in release: $path" >&2; exit 1; }
done
ln -sfn "releases/$sha" "$root/current.next"

restore_old() {
  trap - ERR
  if [[ -n "$old" ]]; then
    ln -sfn "$old" "$root/current.next"
    mv -Tf "$root/current.next" "$root/current"
    compose up -d --build --force-recreate --wait --wait-timeout 180 || {
      echo 'Rollback restart failed; inspect the previous release and container logs.' >&2
      return 1
    }
    echo 'Previous release restored; inspect logs before retrying.' >&2
  else
    compose down --remove-orphans || true
    rm -f "$root/current"
  fi
}

if [[ -n "$old" ]]; then
  trap restore_old ERR
  compose --profile listing stop connect_proxy playit fxserver
  compose run --rm --no-deps backup predeploy
fi
trap restore_old ERR
mv -Tf "$root/current.next" "$root/current"
compose config --quiet
compose up -d --build --force-recreate --wait --wait-timeout 180
trap - ERR
printf 'Installed release %s. Previous release: %s\n' "$sha" "${old:-none}"

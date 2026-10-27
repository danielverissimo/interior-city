#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

usage() {
  cat <<'USAGE'
Usage: scripts/dev.sh init|mac-start|mac-stop|assets-sync [core|full]|assets-verify [core|full]|set-license|set-secret NAME|up|down|status|logs|config

init           Create private, per-checkout Compose settings and Docker secrets.
mac-start      Start the isolated x86_64 Colima VM on Apple Silicon.
mac-stop       Stop that VM, preserving containers and volumes.
assets-sync    Install the private asset profile (default: core).
assets-verify  Verify every installed asset against its catalogue.
set-license    Enter a Cfx development license without echoing it.
set-secret     Enter steam_web_api, webhook_logs, or webhook_bugs without echoing it.
up             Build and start MariaDB and FXServer/txAdmin locally.
down           Stop the local stack, preserving database and txAdmin volumes.
status         Show local service status.
logs           Follow FXServer and database logs.
config         Validate the merged Compose configuration.
USAGE
}

require_checkout() {
  [[ -f .env.dev ]] || { echo 'Run scripts/dev.sh init first.' >&2; exit 1; }
  project="$(sed -n 's/^COMPOSE_PROJECT_NAME=//p' .env.dev | head -n 1)"
  [[ "$project" =~ ^interior-city-tocado-dev-[0-9a-f]{8}$ ]] || {
    echo 'Invalid development project name in .env.dev.' >&2
    exit 1
  }
}

compose() {
  require_checkout
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    echo 'Unset DOCKER_HOST before using the local development stack.' >&2
    exit 1
  fi
  local context endpoint
  context="$(sed -n 's/^IC_DEV_DOCKER_CONTEXT=//p' .env.dev | head -n 1)"
  context="${context:-$(docker context show)}"
  endpoint="$(docker context inspect "$context" --format '{{ .Endpoints.docker.Host }}')"
  case "$endpoint" in
    unix://*|npipe://*) ;;
    *) echo 'The selected Docker context is remote; select a local context first.' >&2; exit 1 ;;
  esac
  env -u COMPOSE_PROFILES INTERIOR_CITY_RELEASE_PATH=. \
    docker --context "$context" compose --env-file .env.dev -f compose.yaml -f compose.dev.yaml \
      -p "$project" "$@"
}

mac_start() {
  [[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || {
    echo 'mac-start is for Apple Silicon Macs. Use up directly on x86_64 hosts.' >&2
    exit 1
  }
  if ! command -v colima >/dev/null || ! command -v qemu-system-x86_64 >/dev/null; then
    echo 'Install the development tools: brew install colima qemu lima-additional-guestagents' >&2
    exit 1
  fi
  [[ -z "${DOCKER_HOST:-}" ]] || { echo 'Unset DOCKER_HOST first.' >&2; exit 1; }
  init
  colima start --profile interior-city-tocado --arch x86_64 --vm-type qemu --cpu-type max \
    --cpus 4 --memory 8 --disk 20 --root-disk 10 --mount-type 9p \
    --mount "$root:w" --port-forwarder grpc --activate=false --ssh-config=false
  local tmp
  tmp="$(mktemp .env.dev.XXXXXX)"
  chmod 0600 "$tmp"
  sed '/^IC_DEV_DOCKER_CONTEXT=/d' .env.dev > "$tmp"
  printf 'IC_DEV_DOCKER_CONTEXT=colima-interior-city-tocado\n' >> "$tmp"
  mv "$tmp" .env.dev
  echo 'Local commands now use colima-interior-city-tocado. The global Docker context is unchanged.'
}

write_secret() {
  local name="$1" value="$2" tmp
  tmp="$(mktemp "secrets/.${name}.XXXXXX")"
  printf '%s' "$value" > "$tmp"
  chmod 0444 "$tmp"
  mv -f "$tmp" "secrets/$name"
}

init() {
  command -v openssl >/dev/null || { echo 'OpenSSL is required.' >&2; exit 1; }
  umask 077
  install -d -m 0700 secrets
  if [[ ! -f .env.dev ]]; then
    local tmp
    tmp="$(mktemp .env.dev.XXXXXX)"
    {
      printf 'COMPOSE_PROJECT_NAME=interior-city-tocado-dev-%s\n' "$(openssl rand -hex 4)"
      printf 'INTERIOR_CITY_TXADMIN_PORT=40121\n'
      printf 'IC_DEV_GAME_BIND_IP=127.0.0.1\n'
      printf 'IC_DEV_GAME_PORT=30121\n'
    } > "$tmp"
    mv "$tmp" .env.dev
  fi
  if ! grep -q '^IC_DEV_UID=' .env.dev; then printf 'IC_DEV_UID=%s\n' "$(id -u)" >> .env.dev; fi
  if ! grep -q '^IC_DEV_GID=' .env.dev; then printf 'IC_DEV_GID=%s\n' "$(id -g)" >> .env.dev; fi
  for name in db_root_password db_app_password; do
    if [[ ! -f "secrets/$name" ]]; then
      write_secret "$name" "$(openssl rand -hex 24)"
    fi
  done
  for name in cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key; do
    if [[ ! -f "secrets/$name" ]]; then
      write_secret "$name" ''
    fi
  done
  chmod 0700 secrets
  chmod 0444 secrets/*
  python3 scripts/configure-secrets.py init
  install -d -m 0700 state/dev/resources/radio
  if [[ ! -f state/dev/resources/radio/private_radios.json ]]; then
    cp 'resources/[voip]/radio/private_radios.json' state/dev/resources/radio/private_radios.json
    chmod 0600 state/dev/resources/radio/private_radios.json
  fi
  require_checkout
  printf 'Local project %s initialized. Set its Cfx license with scripts/dev.sh set-license.\n' "$project"
}

set_secret() {
  local name="$1" value
  case "$name" in
    cfx_license|steam_web_api|webhook_logs|webhook_bugs) ;;
    *) echo 'Unsupported secret name.' >&2; exit 2 ;;
  esac
  [[ -t 0 ]] || { echo 'An interactive terminal is required.' >&2; exit 1; }
  require_checkout
  printf 'Enter %s (input hidden): ' "$name" >&2
  IFS= read -r -s value
  printf '\n' >&2
  case "$name" in
    cfx_license)
      [[ "$value" =~ ^cfxk_[A-Za-z0-9_-]+$ ]] || { echo 'Invalid Cfx license format.' >&2; exit 1; }
      ;;
    steam_web_api)
      [[ -z "$value" || "$value" =~ ^[0-9a-fA-F]{32}$ ]] || { echo 'Invalid Steam key format.' >&2; exit 1; }
      ;;
    *)
      [[ "$value" != *'"'* && "$value" != *$'\r'* ]] || { echo 'Invalid secret characters.' >&2; exit 1; }
      ;;
  esac
  write_secret "$name" "$value"
  python3 scripts/configure-secrets.py render
  unset value
  printf '%s saved in the private secrets directory.\n' "$name"
}

case "${1:-}" in
  init)
    init
    ;;
  mac-start)
    mac_start
    ;;
  mac-stop)
    colima stop --profile interior-city-tocado
    ;;
  assets-sync|assets-verify)
    [[ $# -le 2 ]] || { usage >&2; exit 2; }
    profile="${2:-core}"
    case "$profile" in core|full) ;; *) usage >&2; exit 2 ;; esac
    action=sync
    [[ "$1" != assets-verify ]] || action=verify
    python3 scripts/assets.py "$action" --profile "$profile"
    ;;
  set-license)
    set_secret cfx_license
    ;;
  set-secret)
    [[ $# -eq 2 ]] || { usage >&2; exit 2; }
    set_secret "$2"
    ;;
  up)
    require_checkout
    python3 scripts/configure-secrets.py check
    python3 scripts/assets.py verify --profile "${IC_ASSET_PROFILE:-core}"
    [[ -f secrets/cfx_license ]] || { echo 'Run scripts/dev.sh set-license first.' >&2; exit 1; }
    license="$(cat secrets/cfx_license)"
    [[ "$license" =~ ^cfxk_[A-Za-z0-9_-]+$ ]] || {
      echo 'Run scripts/dev.sh set-license before starting FXServer.' >&2
      exit 1
    }
    unset license
    compose up -d --build db fxserver
    ;;
  down)
    compose down
    ;;
  status)
    compose ps
    ;;
  logs)
    compose logs -f --tail=100 fxserver db
    ;;
  config)
    compose config --quiet
    echo 'Local Compose configuration is valid.'
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

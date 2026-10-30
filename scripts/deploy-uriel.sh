#!/usr/bin/env bash
set -euo pipefail
umask 077
mode="${1:---prepare}"
[[ "$mode" == --prepare || "$mode" == --configure || "$mode" == --apply ]] || { echo 'Usage: deploy-uriel.sh --prepare|--configure|--apply [commit]' >&2; exit 2; }
cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
sha="$(git rev-parse --verify "${2:-HEAD}^{commit}")"
migration_mode=--no-schema
schema_option=''
config_cutover=false
for option in "${@:3}"; do
  case "$option" in
    --no-schema|--ic-admin-schema|--ic-admin-cutover)
      [[ -z "$schema_option" || "$schema_option" == "$option" ]] || { echo 'Conflicting schema flags.' >&2; exit 2; }
      schema_option="$option"; migration_mode="$option" ;;
    --ic-config-cutover) config_cutover=true ;;
    *) echo 'Unsupported migration mode.' >&2; exit 2 ;;
  esac
done
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || exit 2
# An old master commit is not a valid migration release.
for path in assets.lock.json scripts/release.py scripts/configure-secrets.py config/resource-secrets.schema.json; do
  git cat-file -e "$sha:$path"
done
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive --format=tar "$sha" > "$tmp/release.tar"
git show "$sha:scripts/release.py" > "$tmp/release.py"
python3 "$tmp/release.py" extract "$tmp/release.tar" "$tmp/inspection"
if [[ -f "$tmp/inspection/config/ic_config_release.json" && "$config_cutover" != true ]]; then
  echo 'This candidate requires --ic-config-cutover for preparation and installation.' >&2; exit 1
fi
if [[ "$config_cutover" == true ]]; then
  python3 -B - "$tmp/inspection" <<'PY'
import pathlib,sys,types
release=pathlib.Path(sys.argv[1]);path=release/'scripts/ic-config-cutover.py'
module=types.ModuleType('candidate_preview');module.__file__=str(path)
exec(compile(path.read_text(),str(path),'exec'),module.__dict__)
module.configure_candidate(release)
print('Own-provider selection verified in an isolated preview; archive and server are unchanged.')
PY
fi
printf 'Release: %s; code archive: %s bytes; assets fetched separately on Uriel.\n' "$sha" "$(wc -c < "$tmp/release.tar" | tr -d ' ')"
if [[ "$mode" == --prepare ]]; then
  echo 'Preparation passed. No host changes, upload or deployment performed.'
  exit 0
fi
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit local changes before deployment.' >&2; exit 1; }
host="${INTERIOR_CITY_SSH_HOST:-danyelsanches@100.124.79.57}"
[[ "$host" != -* && "$host" =~ ^[A-Za-z0-9_.@:-]+$ ]] || { echo 'Invalid SSH host.' >&2; exit 2; }
staging="interior-city-tocado-$sha-$$"
if [[ "$mode" == --configure ]]; then
  python3 scripts/configure-secrets.py check
  ssh "$host" "umask 077; mkdir -p '$staging/scripts' '$staging/config' '$staging/secrets'"
  # Staged private files remain owner-only via the enclosing directory.
  trap 'rm -rf "$tmp"; ssh "$host" "rm -rf '\''$staging'\''" || true' EXIT
  scp "$tmp/inspection/scripts/prepare-uriel-secrets.sh" "$tmp/inspection/scripts/configure-secrets.py" "$host:$staging/scripts/"
  scp "$tmp/inspection/config/resource-secrets.schema.json" "$host:$staging/config/"
  for name in db_root_password db_app_password cfx_license steam_web_api webhook_logs webhook_bugs playit_agent_key resource_secrets.json; do
    scp "secrets/$name" "$host:$staging/secrets/"
  done
  ssh -tt "$host" "sudo bash '$staging/scripts/prepare-uriel-secrets.sh' \"\$HOME/$staging/secrets\""
  exit 0
fi
git show "$sha:scripts/install-uriel-release.sh" > "$tmp/install-release.sh"
helpers=()
if [[ "$migration_mode" == --ic-admin-cutover ]]; then
  git show "$sha:scripts/ic-admin-cutover.py" > "$tmp/ic-admin-cutover.py"
  git show "$sha:scripts/ic-admin-migrate.py" > "$tmp/ic-admin-migrate.py"
fi
if [[ "$config_cutover" == true ]]; then
  for name in ic-config-cutover.py ic-config-state.py ic-mansions-import.py; do
    git show "$sha:scripts/$name" > "$tmp/$name"; helpers+=("$tmp/$name")
  done
  if [[ ! -f "$tmp/ic-admin-migrate.py" ]]; then git show "$sha:scripts/ic-admin-migrate.py" > "$tmp/ic-admin-migrate.py"; fi
  helpers+=("$tmp/ic-admin-migrate.py")
fi
ssh "$host" "umask 077; mkdir '$staging'"
scp "$tmp/release.tar" "$tmp/install-release.sh" "$tmp/release.py" "$host:$staging/"
if [[ "$migration_mode" == --ic-admin-cutover ]]; then scp "$tmp/ic-admin-cutover.py" "$tmp/ic-admin-migrate.py" "$host:$staging/"; fi
if [[ ${#helpers[@]} -gt 0 ]]; then scp "${helpers[@]}" "$host:$staging/"; fi
config_args=''
if [[ "$config_cutover" == true ]]; then config_args='--ic-config-cutover'; fi
ssh -tt "$host" "sudo bash '$staging/install-release.sh' '$sha' \"\$HOME/$staging/release.tar\" '$migration_mode' $config_args"
ssh "$host" "rm -rf '$staging'"

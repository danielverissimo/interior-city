#!/usr/bin/env bash
set -euo pipefail
umask 077
mode="${1:---prepare}"
[[ "$mode" == --prepare || "$mode" == --configure || "$mode" == --apply ]] || { echo 'Usage: deploy-uriel.sh --prepare|--configure|--apply [commit]' >&2; exit 2; }
cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
sha="$(git rev-parse --verify "${2:-HEAD}^{commit}")"
migration_mode="${3:---no-schema}"
[[ "$migration_mode" == --no-schema || "$migration_mode" == --ic-admin-schema || "$migration_mode" == --ic-admin-cutover ]] || { echo 'Unsupported migration mode.' >&2; exit 2; }
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
if [[ "$migration_mode" == --ic-admin-cutover ]]; then
  git show "$sha:scripts/ic-admin-cutover.py" > "$tmp/ic-admin-cutover.py"
  git show "$sha:scripts/ic-admin-migrate.py" > "$tmp/ic-admin-migrate.py"
fi
ssh "$host" "umask 077; mkdir '$staging'"
scp "$tmp/release.tar" "$tmp/install-release.sh" "$tmp/release.py" "$host:$staging/"
if [[ "$migration_mode" == --ic-admin-cutover ]]; then scp "$tmp/ic-admin-cutover.py" "$tmp/ic-admin-migrate.py" "$host:$staging/"; fi
ssh -tt "$host" "sudo bash '$staging/install-release.sh' '$sha' \"\$HOME/$staging/release.tar\" '$migration_mode'"
ssh "$host" "rm -rf '$staging'"

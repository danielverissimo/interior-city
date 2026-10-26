#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: scripts/deploy-uriel.sh --prepare | --apply [commit]' >&2
  exit 2
}

mode="${1:-}"
[[ "$mode" == --prepare || "$mode" == --apply ]] || usage
commit="${2:-HEAD}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit or remove local changes first.' >&2; exit 1; }
sha="$(git rev-parse --verify "$commit^{commit}")"
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || exit 1

if [[ "$mode" == --prepare ]]; then
  printf 'Release commit: %s\n' "$sha"
  printf 'Tracked files in archive (excluding cache and shell history):\n'
  git archive --format=tar "$sha" -- . ':!cache' ':!.replxx_history' | tar -tf - | wc -l
  echo 'No remote changes were made.'
  exit 0
fi

host="${INTERIOR_CITY_SSH_HOST:-danyelsanches@100.124.79.57}"
staging="interior-city-$sha-$$"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive --format=tar "$sha" -- . ':!cache' ':!.replxx_history' > "$tmp/release.tar"
git show "$sha:scripts/install-uriel-release.sh" > "$tmp/install-release.sh"
ssh "$host" "mkdir -m 700 '$staging'"
scp "$tmp/release.tar" "$tmp/install-release.sh" "$host:$staging/"
ssh -tt "$host" "sudo bash '$staging/install-release.sh' '$sha' \"\$HOME/$staging/release.tar\""
ssh "$host" "rm -rf '$staging'"

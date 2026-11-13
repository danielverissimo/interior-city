#!/usr/bin/env bash
set -euo pipefail
sha=${1:-}
mode=${2:-check}
[[ "$sha" =~ ^[0-9a-f]{40}$ && "$mode" =~ ^(check|deploy)$ ]] || {
  echo 'Usage: runner-deploy.sh SHA check|deploy' >&2; exit 2;
}
[[ ${GITHUB_REPOSITORY:-} == danielverissimo/interior-city && ${GITHUB_REF:-} == refs/heads/master ]] || {
  echo 'Deployment accepts only the master branch of danielverissimo/interior-city.' >&2; exit 2;
}
[[ ${GITHUB_EVENT_NAME:-} == push || ${GITHUB_EVENT_NAME:-} == workflow_dispatch ]] || {
  echo 'Unsupported event; pull requests never receive deployment access.' >&2; exit 2;
}
[[ $(git rev-parse HEAD) == "$sha" ]] || { echo 'Checkout does not match the requested commit.' >&2; exit 2; }
ssh -T -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=4 interior-city-uriel "$mode $sha"

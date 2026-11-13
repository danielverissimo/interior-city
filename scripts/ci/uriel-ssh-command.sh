#!/usr/bin/env bash
# Forced SSH command: no shell, uploads, forwarding or user-selected program.
set -euo pipefail
request=${SSH_ORIGINAL_COMMAND:-}
if [[ "$request" == status ]]; then
  exec sudo -n /usr/local/libexec/interior-city-actions status
elif [[ "$request" =~ ^(check|deploy)\ ([0-9a-f]{40})$ ]]; then
  exec sudo -n /usr/local/libexec/interior-city-actions "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
fi
echo 'Only status, check SHA or deploy SHA are accepted.' >&2
exit 2

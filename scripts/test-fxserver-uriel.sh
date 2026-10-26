#!/usr/bin/env bash
set -euo pipefail
umask 077

[[ "$(id -u)" -eq 0 ]] || { echo 'Run with sudo on Uriel.' >&2; exit 1; }
[[ "$(uname -m)" == x86_64 ]] || { echo 'Native x86_64 host required.' >&2; exit 1; }

test_dir="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$test_dir/fxserver/Dockerfile" ]] || { echo 'Missing FXServer build context.' >&2; exit 1; }

image=interior-city-fx-native-test:35245
container=interior-city-fx-native-test
result="$test_dir/result.txt"
log="$test_dir/fxserver.log"
native_log="$test_dir/fxserver-native.log"
test_secrets="$test_dir/test-secrets"

if docker image inspect "$image" >/dev/null 2>&1 || docker container inspect "$container" >/dev/null 2>&1; then
  echo 'Temporary Docker image or container name is already in use.' >&2
  exit 1
fi

printf 'RUNNING\n' > "$result"
on_exit() {
  local status=$?
  trap - EXIT
  if [[ "$status" -ne 0 ]]; then printf 'FAIL exit=%s\n' "$status" >> "$result"; fi
  docker logs "$container" > "$log" 2>&1 || true
  docker container rm -f "$container" >/dev/null 2>&1 || true
  docker image rm "$image" >/dev/null 2>&1 || true
  if [[ -d "$test_secrets" ]]; then rm -r "$test_secrets"; fi
  if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown "$SUDO_UID:$SUDO_GID" "$result" "$log" "$test_dir/build.log"
    if [[ -f "$native_log" ]]; then chown "$SUDO_UID:$SUDO_GID" "$native_log"; fi
  fi
  chmod 0600 "$result" "$log" "$test_dir/build.log"
  if [[ -f "$native_log" ]]; then chmod 0600 "$native_log"; fi
  exit "$status"
}
trap on_exit EXIT

wait_http() {
  local state
  for attempt in $(seq 1 45); do
    state="$(docker inspect "$container" --format '{{.State.Status}}:{{.State.ExitCode}}')"
    if [[ "$state" != running:* ]]; then
      printf 'FXServer stopped: %s\n' "$state" >&2
      return 1
    fi
    if docker exec "$container" bash -c '
      exec 3<>/dev/tcp/127.0.0.1/40120
      printf "GET / HTTP/1.0\r\nHost: localhost\r\n\r\n" >&3
      IFS= read -r -t 3 status <&3
      [[ "$status" == HTTP/* ]]
    ' >/dev/null 2>&1; then return 0; fi
    sleep 2
  done
  echo 'FXServer remained running, but txAdmin did not answer HTTP within 90 seconds.' >&2
  return 1
}

docker build --platform linux/amd64 -t "$image" "$test_dir/fxserver" > "$test_dir/build.log" 2>&1
common_args=(
  --name "$container" --platform linux/amd64
  --memory 2g --cpus 2 --cap-drop ALL --security-opt no-new-privileges
  --tmpfs /server-data:uid=1000,gid=1000,mode=0700
  --tmpfs /txData:uid=1000,gid=1000,mode=0700
  --tmpfs /tmp:uid=1000,gid=1000,mode=1777
  -e TXHOST_DATA_PATH=/txData -e TXHOST_TXA_PORT=40120
  -e TXHOST_INTERFACE=0.0.0.0 -e TXHOST_MAX_SLOTS=7
)

docker run -d "${common_args[@]}" --entrypoint /opt/fxserver/run.sh "$image" >/dev/null
wait_http
printf 'PASS: native FXServer artifact and txAdmin HTTP startup.\n' >> "$result"
docker logs "$container" > "$native_log" 2>&1
docker container rm -f "$container" >/dev/null

mkdir -m 0700 "$test_secrets"
printf 'cfxk_testonly' > "$test_secrets/cfx_license"
printf '%048d' 2 > "$test_secrets/db_app_password"
for name in steam_web_api webhook_logs webhook_bugs; do : > "$test_secrets/$name"; done
chmod 0444 "$test_secrets/"*
secret_args=()
for name in cfx_license db_app_password steam_web_api webhook_logs webhook_bugs; do
  secret_args+=(--mount "type=bind,src=$test_secrets/$name,dst=/run/secrets/$name,readonly")
done

docker run -d "${common_args[@]}" \
  --tmpfs /server-data/runtime:uid=1000,gid=1000,mode=0700 \
  "${secret_args[@]}" \
  "$image" >/dev/null
wait_http
docker exec "$container" bash -c '
  [[ "$(stat -c %a /server-data/runtime/secrets.cfg)" == 600 ]]
  grep -q "^sv_licenseKey " /server-data/runtime/secrets.cfg
  grep -q "multipleStatements=true" /server-data/runtime/secrets.cfg
'
printf 'PASS: private entrypoint configuration and txAdmin HTTP startup.\n' >> "$result"
echo 'PASS: native FXServer artifact, entrypoint, and txAdmin HTTP startup.'
exit 0

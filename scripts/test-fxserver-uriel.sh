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

if docker image inspect "$image" >/dev/null 2>&1 || docker container inspect "$container" >/dev/null 2>&1; then
  echo 'Temporary Docker image or container name is already in use.' >&2
  exit 1
fi

printf 'RUNNING\n' > "$result"
on_exit() {
  local status=$?
  trap - EXIT
  if [[ "$status" -ne 0 ]]; then printf 'FAIL exit=%s\n' "$status" > "$result"; fi
  docker logs "$container" > "$log" 2>&1 || true
  docker container rm -f "$container" >/dev/null 2>&1 || true
  docker image rm "$image" >/dev/null 2>&1 || true
  if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown "$SUDO_UID:$SUDO_GID" "$result" "$log" "$test_dir/build.log"
  fi
  chmod 0600 "$result" "$log" "$test_dir/build.log"
  exit "$status"
}
trap on_exit EXIT

docker build --platform linux/amd64 -t "$image" "$test_dir/fxserver" > "$test_dir/build.log" 2>&1
docker run -d --name "$container" --platform linux/amd64 \
  --memory 2g --cpus 2 --cap-drop ALL --security-opt no-new-privileges \
  --tmpfs /server-data:uid=1000,gid=1000,mode=0700 \
  --tmpfs /txData:uid=1000,gid=1000,mode=0700 \
  --tmpfs /tmp:uid=1000,gid=1000,mode=1777 \
  -e TXHOST_DATA_PATH=/txData -e TXHOST_TXA_PORT=40120 \
  -e TXHOST_INTERFACE=0.0.0.0 -e TXHOST_MAX_SLOTS=7 \
  --entrypoint /opt/fxserver/run.sh "$image" >/dev/null

for attempt in $(seq 1 45); do
  state="$(docker inspect "$container" --format '{{.State.Status}}:{{.State.ExitCode}}')"
  if [[ "$state" != running:* ]]; then
    printf 'FXServer stopped: %s\n' "$state" >&2
    exit 1
  fi
  if docker exec "$container" bash -c '
    exec 3<>/dev/tcp/127.0.0.1/40120
    printf "GET / HTTP/1.0\r\nHost: localhost\r\n\r\n" >&3
    IFS= read -r -t 3 status <&3
    [[ "$status" == HTTP/* ]]
  ' >/dev/null 2>&1; then
    printf 'PASS: native FXServer started txAdmin and served HTTP on 40120 without a host port.\n' > "$result"
    echo 'PASS: native FXServer and txAdmin HTTP startup.'
    exit 0
  fi
  sleep 2
done

echo 'FXServer remained running, but txAdmin did not answer HTTP within 90 seconds.' >&2
exit 1

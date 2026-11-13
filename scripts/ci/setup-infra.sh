#!/usr/bin/env bash
# One-time, explicit root provisioning; STAGE contains only ephemeral registration
# material and public host keys. Application runtime never moves to this machine.
set -euo pipefail
umask 077
stage=${1:?Provide the absolute setup staging directory}
[[ $EUID -eq 0 && "$stage" == /home/infra/interior-city-actions-setup ]] || exit 2
framework=/home/infra/bootstrap/infra-github-runners
runner_key=danielverissimo/interior-city
runner_hash=$(printf '%s' "$runner_key" | sha256sum); runner_hash=${runner_hash:0:16}
runner_user="gha-interior-c-$runner_hash"
install_dir="/opt/github-actions/repositories/$runner_key"
if [[ ! -f "$install_dir/.runner" ]]; then
  [[ -s "$stage/registration-token" ]] || { echo 'Fresh runner registration token required.' >&2; exit 2; }
  trap 'rm -f "$stage/registration-token"' EXIT
  bash "$framework/scripts/install-runner.sh" danielverissimo interior-city basic < "$stage/registration-token"
  rm -f "$stage/registration-token"
fi
# Never grant the code/deployment runner Docker or sudo access on the shared host.
if id -nG "$runner_user" | tr ' ' '\n' | grep -qx docker; then
  echo 'Unexpected Docker access on this repository runner.' >&2; exit 1
fi
runner_home=$(getent passwd "$runner_user" | cut -d: -f6)
install -d -m 0700 -o "$runner_user" -g "$runner_user" "$runner_home/.ssh"
if [[ ! -f "$runner_home/.ssh/id_uriel_deploy" ]]; then
  runuser -u "$runner_user" -- ssh-keygen -q -t ed25519 -N '' \
    -f "$runner_home/.ssh/id_uriel_deploy" -C interior-city-infra-to-uriel
fi
read -r keytype keydata _ < "$stage/uriel-host.pub"
printf 'interior-city-uriel %s %s\n' "$keytype" "$keydata" > "$runner_home/.ssh/known_hosts"
cat > "$runner_home/.ssh/config" <<EOF
Host interior-city-uriel
  HostName 127.0.0.1
  Port 22247
  User ic-deploy
  IdentityFile $runner_home/.ssh/id_uriel_deploy
  IdentitiesOnly yes
  HostKeyAlias interior-city-uriel
  StrictHostKeyChecking yes
  BatchMode yes
EOF
chown "$runner_user:$runner_user" "$runner_home/.ssh/config" "$runner_home/.ssh/known_hosts"
chmod 0600 "$runner_home/.ssh/config" "$runner_home/.ssh/known_hosts"
if ! id ic-actions-tunnel >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /var/lib/interior-city-actions-tunnel --shell /usr/sbin/nologin ic-actions-tunnel
fi
install -d -m 0755 -o root -g root /var/lib/interior-city-actions-tunnel /var/lib/interior-city-actions-tunnel/.ssh
printf 'restrict,port-forwarding,permitlisten="127.0.0.1:22247" %s\n' "$(cat "$stage/uriel-tunnel.pub")" \
  > /var/lib/interior-city-actions-tunnel/.ssh/authorized_keys
chmod 0644 /var/lib/interior-city-actions-tunnel/.ssh/authorized_keys
cat > /etc/ssh/sshd_config.d/80-interior-city-tunnel.conf <<'EOF'
Match User ic-actions-tunnel
    AuthenticationMethods publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    AllowTcpForwarding remote
    PermitListen 127.0.0.1:22247
    GatewayPorts no
    AllowAgentForwarding no
    X11Forwarding no
    PermitTTY no
    MaxSessions 0
Match all
EOF
/usr/sbin/sshd -t
systemctl reload ssh
printf 'Runner configured: %s; SSH tunnel listener restricted to loopback:22247.\n' "$runner_user"

#!/usr/bin/env bash
# Explicit one-time provisioning. Never starts a game release or changes its data.
set -euo pipefail
umask 077
stage=${1:?Provide the absolute setup staging directory}
[[ $EUID -eq 0 && "$stage" == /home/danyelsanches/interior-city-actions-setup ]] || exit 2
[[ -L /opt/uriel/interior-city-tocado/current ]] || { echo 'Managed city installation missing.' >&2; exit 1; }
install -m 0755 -o root -g root "$stage/uriel-actions.py" /usr/local/libexec/interior-city-actions
install -m 0755 -o root -g root "$stage/uriel-ssh-command.sh" /usr/local/libexec/interior-city-ssh-command
if ! id ic-deploy >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /var/lib/interior-city-deploy --shell /bin/bash ic-deploy
fi
install -d -m 0755 -o root -g root /var/lib/interior-city-deploy /var/lib/interior-city-deploy/.ssh
printf 'restrict,command="/usr/local/libexec/interior-city-ssh-command" %s\n' "$(cat "$stage/runner-deploy.pub")" \
  > /var/lib/interior-city-deploy/.ssh/authorized_keys
chmod 0644 /var/lib/interior-city-deploy/.ssh/authorized_keys
printf 'ic-deploy ALL=(root) NOPASSWD: /usr/local/libexec/interior-city-actions\n' > "$stage/sudoers"
visudo -cf "$stage/sudoers"
install -m 0440 -o root -g root "$stage/sudoers" /etc/sudoers.d/interior-city-actions
if ! id ic-actions-tunnel >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /var/lib/interior-city-actions-tunnel --shell /usr/sbin/nologin ic-actions-tunnel
fi
tunnel=/var/lib/interior-city-actions-tunnel
install -d -m 0700 -o ic-actions-tunnel -g ic-actions-tunnel "$tunnel" "$tunnel/.ssh"
if [[ ! -f "$tunnel/.ssh/id_ed25519" ]]; then
  install -m 0600 -o ic-actions-tunnel -g ic-actions-tunnel "$stage/tunnel-key" "$tunnel/.ssh/id_ed25519"
fi
read -r keytype keydata _ < "$stage/infra-host.pub"
printf '177.73.48.204 %s %s\n' "$keytype" "$keydata" > "$tunnel/.ssh/known_hosts"
chown ic-actions-tunnel:ic-actions-tunnel "$tunnel/.ssh/known_hosts"
chmod 0600 "$tunnel/.ssh/known_hosts"
cat > /etc/systemd/system/interior-city-actions-tunnel.service <<'EOF'
[Unit]
Description=Private SSH reverse tunnel for Interior City deployments
Wants=network-online.target
After=network-online.target ssh.service
StartLimitIntervalSec=0

[Service]
User=ic-actions-tunnel
Group=ic-actions-tunnel
ExecStart=/usr/bin/ssh -NT -i /var/lib/interior-city-actions-tunnel/.ssh/id_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o ExitOnForwardFailure=yes -o ConnectTimeout=15 -o ServerAliveInterval=20 -o ServerAliveCountMax=3 -R 127.0.0.1:22247:127.0.0.1:22 ic-actions-tunnel@177.73.48.204
Restart=always
RestartSec=10
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
systemd-analyze verify /etc/systemd/system/interior-city-actions-tunnel.service
systemctl daemon-reload
systemctl enable --now interior-city-actions-tunnel.service
# Never emit game secrets, player data or container logs during provisioning.
/usr/local/libexec/interior-city-actions status

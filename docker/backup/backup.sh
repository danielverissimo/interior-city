#!/usr/bin/env bash
set -euo pipefail
umask 077

mode="${1:-loop}"
mkdir -p /backups

backup_once() {
  local stamp work output
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  work="$(mktemp -d /tmp/interior-backup.XXXXXX)"
  trap 'rm -rf "$work"' RETURN
  printf '[client]\nuser=root\npassword=%s\nhost=db\n' "$(cat /run/secrets/db_root_password)" > "$work/client.cnf"
  chmod 0600 "$work/client.cnf"
  output="/backups/vrp-$stamp.sql.gz"
  mariadb-dump --defaults-extra-file="$work/client.cnf" --single-transaction --quick --no-tablespaces --databases vrp | gzip -9 > "$work/db.sql.gz"
  gzip -t "$work/db.sql.gz"
  mv "$work/db.sql.gz" "$output"
  if [[ "$mode" == "predeploy" ]]; then
    tar -C /txData -czf "$work/txData.tar.gz" .
    mv "$work/txData.tar.gz" "/backups/txData-$stamp.tar.gz"
    if [[ -d /kvp && -d /resource-state ]]; then
      tar -C / -czf "$work/runtime.tar.gz" kvp resource-state
      mv "$work/runtime.tar.gz" "/backups/runtime-$stamp.tar.gz"
      (cd /backups && sha256sum "runtime-$stamp.tar.gz" > "runtime-$stamp.tar.gz.sha256")
    fi
  fi
  (cd /backups && sha256sum "$(basename "$output")" > "$(basename "$output").sha256")
  find /backups -maxdepth 1 -type f -mtime +6 -name 'vrp-*.sql.gz*' -delete
  find /backups -maxdepth 1 -type f -mtime +6 -name 'txData-*.tar.gz' -delete
  find /backups -maxdepth 1 -type f -mtime +6 -name 'runtime-*.tar.gz*' -delete
  printf 'Backup completed: %s\n' "$(basename "$output")"
}

case "$mode" in
  once|predeploy) backup_once ;;
  loop)
    while :; do
      backup_once
      sleep 86400
    done
    ;;
  *) echo "Usage: backup.sh [loop|once|predeploy]" >&2; exit 2 ;;
esac

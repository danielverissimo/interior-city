#!/usr/bin/env bash
set -euo pipefail
umask 077
healthcheck.sh --connect --innodb_initialized >/dev/null 2>&1
work="$(mktemp -d /tmp/interior-db-health.XXXXXX)"
trap 'rm -rf "$work"' EXIT
printf '[client]\nuser=vrp\npassword=%s\nhost=localhost\ndatabase=vrp\n' \
  "$(cat /run/secrets/db_app_password)" > "$work/client.cnf"
# MariaDB can restart after an init failure and otherwise look healthy with only
# a fraction of the schema. Do not let FXServer start against that partial DB.
sed -nE 's/^CREATE TABLE (IF NOT EXISTS )?`([^`]+)`.*/\2/p' \
  /docker-entrypoint-initdb.d/01-schema.sql | LC_ALL=C sort -u > "$work/expected"
[[ -s "$work/expected" ]] || exit 1
mariadb --defaults-extra-file="$work/client.cnf" --batch --skip-column-names \
  -e "SELECT table_name FROM information_schema.tables WHERE table_schema = 'vrp';" \
  | LC_ALL=C sort -u > "$work/actual"
[[ -z "$(LC_ALL=C comm -23 "$work/expected" "$work/actual")" ]]

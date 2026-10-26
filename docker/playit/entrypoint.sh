#!/bin/sh
set -eu

if [ ! -r /run/secrets/playit_agent_key ]; then
  echo 'Missing Playit agent Docker secret.' >&2
  exit 1
fi

if [ ! -s /run/secrets/playit_agent_key ]; then
  echo 'Playit agent key is empty.' >&2
  exit 1
fi
exec /usr/local/bin/playit \
  --secret-path /run/secrets/playit_agent_key \
  --socket-path /tmp/playit-agent.sock \
  --platform-docker

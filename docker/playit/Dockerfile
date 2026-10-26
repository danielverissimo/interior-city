FROM debian:bookworm-slim AS agent

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

ARG PLAYIT_URL=https://github.com/playit-cloud/playit-agent/releases/download/v1.0.10/playit-linux-amd64
ARG PLAYIT_SHA256=2df7d9f10227ab312b1ad341853db4e8a8243df5cfcdbae58713a4271711c339

RUN curl -fsSL --retry 3 "$PLAYIT_URL" -o /usr/local/bin/playit \
    && echo "$PLAYIT_SHA256  /usr/local/bin/playit" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/playit

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 interior \
    && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin interior

COPY --from=agent /usr/local/bin/playit /usr/local/bin/playit
COPY entrypoint.sh /usr/local/bin/playit-entrypoint

RUN chmod 0755 /usr/local/bin/playit-entrypoint

USER interior
ENV HOME=/tmp
ENTRYPOINT ["/usr/local/bin/playit-entrypoint"]

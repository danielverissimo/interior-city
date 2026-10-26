FROM debian:bookworm-slim AS artifact

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG FXSERVER_ARTIFACT_URL=https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/35245-6efb47dff473c0e2a12fb50b08d74c0eb24a50d5/fx.tar.xz
ARG FXSERVER_ARTIFACT_SHA256=16fcffd53a30a3909cbb2cfd26f89f950a59452792cafd0eda2174bdfeef9b2f

RUN curl -fsSL --retry 3 "$FXSERVER_ARTIFACT_URL" -o /tmp/fx.tar.xz \
    && echo "$FXSERVER_ARTIFACT_SHA256  /tmp/fx.tar.xz" | sha256sum -c - \
    && mkdir -p /opt/fxserver \
    && tar -xf /tmp/fx.tar.xz -C /opt/fxserver \
    && test -x /opt/fxserver/run.sh

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates libatomic1 libgcc-s1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 interior \
    && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin interior \
    && mkdir -p /server-data /txData \
    && chown interior:interior /server-data /txData

COPY --from=artifact /opt/fxserver /opt/fxserver
COPY entrypoint.sh /usr/local/bin/interior-city-entrypoint

RUN chmod 0755 /usr/local/bin/interior-city-entrypoint

USER interior
WORKDIR /server-data
ENTRYPOINT ["/usr/local/bin/interior-city-entrypoint"]

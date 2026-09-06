FROM ghcr.io/wkalescky/valheim-base:latest

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends awscli \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R steam:steam /home/steam/.config

USER steam
COPY --chmod=755 start_server.sh ${STEAMAPPDIR}/start_server.sh
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

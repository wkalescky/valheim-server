FROM debian:bookworm

ENV USER=steam
ENV HOMEDIR="/home/${USER}"
ENV STEAMCMDDIR="/usr/games/steamcmd"
ENV STEAMAPPID=896660
ENV STEAMAPP=valheim
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"

RUN set -x \
    && printf "deb http://deb.debian.org/debian stable main contrib non-free\n" >> /etc/apt/sources.list \
    && printf "deb-src http://deb.debian.org/debian stable main contrib non-free\n" >> /etc/apt/sources.list \
    && printf "deb http://deb.debian.org/debian stable-updates main contrib non-free\n" >> /etc/apt/sources.list \
    && printf "deb-src http://deb.debian.org/debian stable-updates main contrib non-free\n" >> /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
        lib32stdc++6 \
        lib32gcc-s1 \
        ca-certificates \
        curl \
        iproute2 \
        nano \
        procps \
        steamcmd \
        vim \
        awscli \
        jq \
        zip \
        python3 \
        python3-pip \
        supervisor \
    && pip3 install --break-system-packages python-a2s \
    && useradd -ms /bin/bash ${USER} \
    && rm -rf /var/lib/apt/lists/*

USER ${USER}
WORKDIR /home/${USER}

RUN set -x \
  && "$STEAMCMDDIR" +quit

RUN set -x \
  && for i in 1 2 3 4 5; do \
       "$STEAMCMDDIR" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" validate +quit \
       && break \
       || (echo "SteamCMD attempt $i failed, retrying in 30s..." && sleep 30); \
     done

COPY --chown=steam:steam --chmod=755 start_server.sh ${STEAMAPPDIR}/start_server.sh

USER root
COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY --chmod=755 cloudflare.sh /cloudflare.sh
COPY --chmod=755 world_bootstrap.sh /world_bootstrap.sh
COPY --chmod=755 valheim-start.sh /valheim-start.sh
COPY --chmod=755 watchdog.sh /watchdog.sh
COPY --chmod=755 save_manager.sh /save_manager.sh
COPY supervisord.conf /supervisord.conf

ENTRYPOINT ["/entrypoint.sh"]

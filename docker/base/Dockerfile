FROM debian:bookworm

ENV USER=steam
ENV HOMEDIR="/home/${USER}"
ENV STEAMCMDDIR="/usr/games/steamcmd"
ENV STEAMAPPID=896660
ENV SETAMAPP=valheim
ENV STEAMAPPDIR="${HOMEDIR}/${SETAMAPP}-dedicated"

RUN set -x \
	&& echo "hello world" \
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
  && useradd -ms /bin/bash ${USER}

USER ${USER}
COPY worlds/. /home/steam/.config/unity3d/IronGate/Valheim/worlds_local/
WORKDIR /home/${USER}
RUN set -x \
  && touch iamherenow \
  && "$STEAMCMDDIR" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" +quit
COPY start_server.sh ${STEAMAPPDIR}/start_server.sh
RUN chmod +x ${STEAMAPPDIR}/start_server.sh

# EXPOSE 2456/tcp \
# 	2456/udp \
# 	2457/udp


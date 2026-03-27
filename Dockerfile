# Debian 13 (trixie) slim: run local bin/install.sh; set INSTALL_MODULES (space-separated).
# Libs load from REPOSITORY (default file:///install/bin/ — no network for scripts).
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl sudo \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /install
COPY bin/ /install/bin/
RUN chmod +x /install/bin/install.sh /install/bin/docker-entrypoint-install.sh /install/bin/docker-start-xrdp.sh

ENV REPOSITORY=file:///install/bin/
ENV INSTALL_MODULES=tools

ENTRYPOINT ["/install/bin/docker-entrypoint-install.sh"]
CMD ["sleep", "infinity"]

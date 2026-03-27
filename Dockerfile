# Debian 13 (trixie) slim: run local bin/install.sh; set INSTALL_MODULES (space-separated).
# Libs load from REPOSITORY (default file:///install/bin/ — no network for scripts).
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl wget sudo \
  && printf '%s\n' 'Defaults env_keep += "DEBIAN_FRONTEND"' >/etc/sudoers.d/99-debconf \
  && chmod 440 /etc/sudoers.d/99-debconf \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /install
COPY bin/ /install/bin/
RUN chmod +x /install/bin/install.sh /install/bin/docker-entrypoint-install.sh /install/bin/docker-start-xrdp.sh

ENV REPOSITORY=file:///install/bin/

# Bake tools + chrome + xrdp-xfce into the image (override at build with BAKE_INSTALL_MODULES / XFCE_METAPACKAGE_BAKE).
ARG BAKE_INSTALL_MODULES="tools chrome xrdp-xfce"
ARG XFCE_METAPACKAGE_BAKE=xfce4
ENV BAKED_INSTALL_MODULES="${BAKE_INSTALL_MODULES}"
ENV XFCE_METAPACKAGE="${XFCE_METAPACKAGE_BAKE}"
ENV INSTALL_MODULES="${BAKE_INSTALL_MODULES}"
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive REPOSITORY=file:///install/bin/ \
    XFCE_METAPACKAGE="${XFCE_METAPACKAGE_BAKE}" \
    /install/bin/install.sh ${BAKE_INSTALL_MODULES} \
  && touch /var/lib/.make-install-baked \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/install/bin/docker-entrypoint-install.sh"]
CMD ["sleep", "infinity"]

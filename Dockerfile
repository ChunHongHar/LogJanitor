FROM docker.io/debian:trixie-slim

LABEL maintainer="ChunHongHar <102952248+ChunHongHar@users.noreply.github.com>"
LABEL org.opencontainers.image.source="https://github.com/ChunHongHar/LogJanitor"
ARG REVISION="0.1"
LABEL org.opencontainers.image.revision="${REVISION}"

# System settings
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ARG LOGROTATE_USER=logjanitor
ENV LOGROTATE_USER=$LOGROTATE_USER
ARG LOGROTATE_GROUP=logjanitor
ENV LOGROTATE_CONF="/etc/logrotate.conf"
ARG LOGROTATE_STATE_DIR="/home/logrotate/.local/share/logrotate.d"
ENV LOGROTATE_STATE_DIR=${LOGROTATE_STATE_DIR}
ENV LOGROTATE_STATE_FILE="${LOGROTATE_STATE_DIR}/status"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOF
#!/bin/bash

set -euo pipefail

# create a group for logrotate binary
groupadd -g $CONTAINER_GID $LOGROTATE_GROUP
useradd -u $CONTAINER_UID -g $CONTAINER_GID -c "" $LOGROTATE_USER

apt update -y \
    && apt --no-install-recommends install -y \
        cron \
        logrotate \
        tini \
        tzdata \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt remove apt --autoremove -y --allow-remove-essential

chmod u+s /usr/sbin/cron
rm -rf /etc/cron.*/*

EOF

# Logrotate user configuration
ENV LOGROTATE_CRON_EXPR= \
    LOGROTATE_LOGFILES= \
    LOGROTATE_MAXFILESIZE= \
    LOGROTATE_FILENUM= \
    LOGROTATE_OUTPUTFILE= \
    LOGROTATE_MAXAGE= \
    CROND_LOGLEVEL= \
    DEBUG=

RUN touch /var/log/cron.log \
    && chown ${LOGROTATE_USER}:${LOGROTATE_USER} /var/log/cron.log

# Recreate config and state storage
RUN if [ -f "${LOGROTATE_CONF}" ]; then rm -f ${LOGROTATE_CONF}; fi
RUN touch ${LOGROTATE_CONF} \
    && chown ${LOGROTATE_USER}:${LOGROTATE_USER} ${LOGROTATE_CONF}

RUN mkdir -p ${LOGROTATE_STATE_DIR} \
    && touch ${LOGROTATE_STATE_FILE} \
    && chown -R ${LOGROTATE_USER}:${LOGROTATE_USER} ${LOGROTATE_STATE_DIR}

COPY --chmod=755 execute-cron.sh /app/execute-cron.sh
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

USER ${LOGROTATE_USER}

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
CMD ["/bin/bash", "-c", "/app/execute-cron.sh"]

#!/usr/bin/env bash

set -eu

[[ ${DEBUG:-false} == true ]] && set -x

# Kubernetes default stdout
logrotate_logfiles="/var/log/*"

# Log files to rotate; separated by a space
if [ -n "${LOGROTATE_LOGFILES}" ]; then
  logrotate_logfiles="${LOGROTATE_LOGFILES}"
fi

cat >> ${LOGROTATE_CONF} << EOF
${logrotate_logfiles}
{
  nomail
  maxsize ${LOGROTATE_MAXFILESIZE:-10M}
  weekly
  missingok
  notifempty
  copytruncate
  rotate ${LOGROTATE_FILENUM:-5}
  delaycompress
  compress
EOF

# Additional directives
if [ -n "${LOGROTATE_MAXAGE}" ]; then
  cat >> ${LOGROTATE_CONF} << EOF
  maxage ${LOGROTATE_MAXAGE}
EOF
fi

cat >> ${LOGROTATE_CONF} << EOF
}
EOF

cat ${LOGROTATE_CONF}

cron_expr="0 0 * * *" # Rotates every 24 hours by default

# Set cron schedule
if [ -z "${LOGROTATE_CRON_EXPR}" ]; then
  echo "LOGROTATE_CRON_EXPR environment variable is not set. Set to default: ${cron_expr}"
else
  echo "LOGROTATE_CRON_EXPR environment variable set to ${LOGROTATE_CRON_EXPR}"
  cron_expr=${LOGROTATE_CRON_EXPR}
fi

logrotate_outputfile=""

# Log `logrotate` outputs to a file
if [ -n "${LOGROTATE_OUTPUTFILE}" ]; then
  logrotate_outputfile=" 2>&1 | tee -a ${LOGROTATE_OUTPUTFILE}"
fi

logrotate_cmd="/usr/sbin/logrotate -s ${LOGROTATE_STATE_DIR}/status -v ${LOGROTATE_CONF}${logrotate_outputfile}"
echo "${cron_expr} /bin/bash -c '${logrotate_cmd}'" | crontab -u ${LOGROTATE_USER} -

exec "$@"

#!/usr/bin/env bash

set -eu

[[ ${DEBUG:-false} == true ]] && set -x

/usr/sbin/cron -l ${CROND_LOGLEVEL:-8} -f 2>&1
less +F /var/log/cron.log

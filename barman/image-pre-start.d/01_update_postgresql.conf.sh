#!/bin/bash

set -eo pipefail

. /usr/local/bin/functions.sh

echo "Updating postgresql.conf to allow for streaming replication"
if verlt ${PG_MAJOR} 9.6; then
	WAL_LEVEL="hot_standby"
else
	WAL_LEVEL="replica"
fi

cat >>${PGDATA}/postgresql.conf <<EOF
wal_level = '${WAL_LEVEL}'
max_wal_senders = 2
max_replication_slots = 2
EOF

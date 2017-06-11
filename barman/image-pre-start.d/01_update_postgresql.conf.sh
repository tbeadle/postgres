#!/bin/bash

set -eo pipefail

. /usr/local/bin/functions.sh

echo "Updating postgresql.conf to allow for streaming replication"
if major_gte 9.6; then
	WAL_LEVEL="replica"
else
	WAL_LEVEL="hot_standby"
fi

cat >>${PGDATA}/postgresql.conf <<EOF
wal_level = '${WAL_LEVEL}'
max_wal_senders = 2
EOF

if major_gte 9.4 ; then
cat >>${PGDATA}/postgresql.conf <<EOF
max_replication_slots = 2
EOF
fi 

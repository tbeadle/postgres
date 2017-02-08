#!/bin/bash

set -eo pipefail

function add_user {
	local user=${!1}
	local pw=${!2}
	local db=${3}
	local options="${4}"

	echo "Creating ${user} user in database."
	local cmd="CREATE USER ${user} WITH ${options}"
	local auth
	if [[ -n ${pw} ]]; then
		cmd+=" ENCRYPTED PASSWORD '<password>'"
		auth="md5"
		echo "Be sure to add the following to the .pgpass file on the barman server:"
		echo "$(hostname):${PGPORT:-5432}:${PGDATABASE}:${user}:<password>"
	else
		auth="trust"
		echo "${user} is being created without any password!!!"
	fi

	echo "Running ${cmd}"
	psql -c "${cmd/<password>/${pw//\'/\'\'}}"

	echo "Adding ${user} to pg_hba.conf"
	echo "host ${db} ${user} 0.0.0.0/0 ${auth}" >> ${PGDATA}/pg_hba.conf
	echo "host ${db} ${user} ::/0 ${auth}" >> ${PGDATA}/pg_hba.conf
}

add_user BARMAN_USER BARMAN_PASSWORD all SUPERUSER
add_user STREAMING_USER STREAMING_PASSWORD replication REPLICATION

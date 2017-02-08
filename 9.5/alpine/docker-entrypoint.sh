#!/bin/bash
set -e
shopt -s nullglob

. /usr/local/bin/functions.sh

if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi

file_env 'PGUSER' 'postgres'
file_env 'PGDATABASE' "$PGUSER"
file_env 'PGPASSWORD'

if [ "$1" = 'postgres' ]; then
	for x in /image-pre-entrypoint.d/* /docker-pre-entrypoint.d/*; do
		if [ -f "${x}" -a -x "${x}" ]; then
			echo "-----> Running ${x}"
			"${x}"
		fi
	done

	mkdir -p "$PGDATA"
	chmod 700 "$PGDATA"
	chown -R postgres: "$PGDATA"

	mkdir -p /run/postgresql
	chmod g+s /run/postgresql
	chown -R postgres: /run/postgresql

	# look specifically for PG_VERSION, as it is expected in the DB dir
	if [ ! -s "$PGDATA/PG_VERSION" ]; then
		file_env 'POSTGRES_INITDB_ARGS'
		eval "su-exec postgres initdb $POSTGRES_INITDB_ARGS"

		# check password first so we can output the warning before postgres
		# messes it up
		if [ "$PGPASSWORD" ]; then
			pass="PASSWORD '$PGPASSWORD'"
			authMethod=md5
		else
			# The - option suppresses leading tabs but *not* spaces. :)
			cat >&2 <<-'EOWARN'
				****************************************************
				WARNING: No password has been set for the database.
				         This will allow anyone with access to the
				         Postgres port to access your database. In
				         Docker's default configuration, this is
				         effectively any other container on the same
				         system.

				         Use "-e PGPASSWORD=password" to set
				         it in "docker run".
				****************************************************
			EOWARN

			pass=
			authMethod=trust
		fi

		{ echo; echo "host all all samenet $authMethod"; } | su-exec postgres tee -a "$PGDATA/pg_hba.conf" > /dev/null

		echo
		# Adapted from https://www.youtube.com/watch?v=JqMduJimzFQ
		cat <<EOF >> ${PGDATA}/postgresql.conf
shared_buffers = 512MB                  # min 128kB
work_mem = 32MB                         # min 64kB
maintenance_work_mem = 128MB            # min 1MB
wal_buffers = 16MB                      # min 32kB, -1 sets based on shared_buffers
checkpoint_timeout = ${CHECKPOINT_TIMEOUT:-20min}              # range 30s-1h
checkpoint_completion_target = 0.9      # checkpoint target duration, 0.0 - 1.0
effective_cache_size = 938MB
logging_collector = on
log_destination = 'csvlog'              # Valid values are combinations of
log_filename = 'postgresql-%a.log' # log file name pattern,
log_rotation_age = 1440
log_truncate_on_rotation = on
log_min_duration_statement = ${LOG_MIN_DURATION_TIMEOUT:-600ms}      # -1 is disabled, 0 logs all statements
log_checkpoints = on
log_connections = off
log_disconnections = off
log_lock_waits = on                     # log lock waits >= deadlock_timeout
log_temp_files = 0                      # log temporary files equal or larger
EOF
		if verlt "${PG_MAJOR}" "9.5"; then
			# checkpoint_segments is deprecated in 9.5
			echo "checkpoint_segments = 32  # in logfile segments, min 1, 16MB each" >> ${PGDATA}/postgresql.conf
		fi

		echo

		for x in /image-pre-start.d/*; do
			if [ -f "${x}" -a -x "${x}" ]; then
				echo "-----> Running ${x}"
				"${x}"
			fi
		done

		# internal start of server in order to allow set-up using psql-client
		# does not listen on external TCP/IP and waits until start finishes
		su-exec postgres pg_ctl -D "$PGDATA" \
			-o "-c listen_addresses='localhost'" \
			-w start

		psql=( psql -v ON_ERROR_STOP=1 )

		if [ "$PGDATABASE" != 'postgres' ]; then
			"${psql[@]}" --username postgres --dbname postgres <<-EOSQL
				CREATE DATABASE "$PGDATABASE" ;
			EOSQL
			echo
		fi

		if [ "$PGUSER" = 'postgres' ]; then
			op='ALTER'
		else
			op='CREATE'
		fi
		"${psql[@]}" --username postgres <<-EOSQL
			$op USER "$PGUSER" WITH SUPERUSER $pass ;
		EOSQL

		echo

		for f in /image-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)     echo "$0: running $f"; . "$f" ;;
				*.sql)    echo "$0: running $f"; "${psql[@]}" -f "$f"; echo ;;
				*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
				*)        echo "$0: ignoring $f" ;;
			esac
			echo
		done

		su-exec postgres pg_ctl -D "$PGDATA" -m fast -w stop

		echo
		echo 'PostgreSQL init process complete; ready for start up.'
		echo
	fi

	for x in /image-post-entrypoint.d/* /docker-post-entrypoint.d/*; do
		if [ -f "${x}" -a -x "${x}" ]; then
			echo "-----> Running ${x}"
			"${x}"
		fi
	done

	exec su-exec postgres "$@"
fi

exec "$@"

#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Compare 2 version numbers
verlte() {
	[  "$1" == "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
	[ "$1" == "$2" ] && return 1 || verlte $1 $2
}

major_gte() { verlt $1 ${PG_MAJOR}; }
major_lt() { verlt ${PG_MAJOR} $1; }


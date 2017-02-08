#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( ../[0-9]*/ )
fi
versions=( "${versions[@]#../}" )
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	sed 's/%%PG_MAJOR%%/'"$version"'/g' Dockerfile.template > "Dockerfile-${version}"
done

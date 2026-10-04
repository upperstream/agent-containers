#!/bin/sh

# Build the root Dockerfile from the agents service, using the Docker
# daemon in the docker_builder service, and report whether the build
# succeeds.  The host Docker daemon is not used.

set -eu

# shellcheck disable=SC1007
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

if [ -z "${DOCKER_HOST:-}" ]; then
	DOCKER_HOST=tcp://docker_builder:2375
	export DOCKER_HOST
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "error: docker client not found" >&2
	exit 1
fi

echo "Waiting for Docker daemon at $DOCKER_HOST ..."
i=0
while [ "$i" -lt 30 ]; do
	if docker info >/dev/null 2>&1; then
		break
	fi
	i=$((i + 1))
	sleep 1
done

if ! docker info >/dev/null 2>&1; then
	echo "error: cannot reach Docker daemon at $DOCKER_HOST" >&2
	exit 1
fi

image=agent-containers-docker-build-test

# shellcheck disable=SC2329
cleanup() {
	docker rmi "$image" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Building $repo_root/Dockerfile ..."
if docker build -t "$image" -f Dockerfile .; then
	echo "ok: docker build succeeded"
	exit 0
fi

echo "error: docker build failed" >&2
exit 1

#!/bin/sh

# Build a Dockerfile from the agents service, using the Docker
# daemon in the docker_builder service, and report whether the build
# succeeds.  The host Docker daemon is not used.
#
# Usage:
#   docker_build_test.sh [DOCKERFILE [CONTEXT]]
# Default:
#   DOCKERFILE: Dockerfile
#   CONTEXT:    .

set -eu

# shellcheck disable=SC1007
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dockerfile=${1:-Dockerfile}
context=${2:-.}

if [ -z "${DOCKER_HOST:-}" ]; then
	DOCKER_HOST=unix:///run/docker-builder/docker.sock
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

echo "Building $repo_root/$dockerfile from $context ..."
if docker build -t "$image" -f "$dockerfile" "$context"; then
	echo "ok: docker build succeeded"
	exit 0
fi

echo "error: docker build failed" >&2
exit 1

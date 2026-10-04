#!/bin/sh

# Build the root Dockerfile from the agents service, using the Podman
# API in the podman_builder service, and report whether the build
# succeeds.  The host container engine is not used.

set -eu

# shellcheck disable=SC1007
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

if [ -z "${CONTAINER_HOST:-}" ]; then
	CONTAINER_HOST=tcp://podman_builder:2375
	export CONTAINER_HOST
fi

if ! command -v podman-remote >/dev/null 2>&1; then
	echo "error: podman-remote client not found" >&2
	exit 1
fi

echo "Waiting for Podman service at $CONTAINER_HOST ..."
i=0
while [ "$i" -lt 30 ]; do
	if podman-remote info >/dev/null 2>&1; then
		break
	fi
	i=$((i + 1))
	sleep 1
done

if ! podman-remote info >/dev/null 2>&1; then
	echo "error: cannot reach Podman service at $CONTAINER_HOST" >&2
	exit 1
fi

image=agent-containers-podman-build-test

# shellcheck disable=SC2329
cleanup() {
	podman-remote rmi "$image" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Building $repo_root/Dockerfile ..."
if podman-remote build -t "$image" -f Dockerfile .; then
	echo "ok: podman build succeeded"
	exit 0
fi

echo "error: podman build failed" >&2
exit 1

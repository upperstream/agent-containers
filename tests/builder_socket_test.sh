#!/bin/sh

# Run inside agents to check Unix socket access to both builders and
# confirm that their former TCP API endpoints are unavailable.

set -eu

for client in docker podman-remote curl; do
	if ! command -v "$client" >/dev/null 2>&1; then
		echo "error: $client client not found" >&2
		exit 1
	fi
done

DOCKER_HOST=${DOCKER_HOST:-unix:///run/docker-builder/docker.sock}
CONTAINER_HOST=${CONTAINER_HOST:-unix:///run/podman-builder/podman.sock}
export DOCKER_HOST CONTAINER_HOST

for endpoint in "$DOCKER_HOST" "$CONTAINER_HOST"; do
	case $endpoint in
		unix://*) ;;
		*)
			echo "error: expected a Unix socket endpoint: $endpoint" >&2
			exit 1
			;;
	esac
	socket=${endpoint#unix://}
	if [ ! -S "$socket" ] || [ ! -w "$socket" ]; then
		echo "error: socket missing or inaccessible: $socket" >&2
		exit 1
	fi
done

docker info >/dev/null
podman-remote info >/dev/null

for builder in docker_builder podman_builder; do
	if curl --noproxy '*' --silent --show-error \
			--connect-timeout 2 --max-time 3 \
			"http://$builder:2375/_ping" >/dev/null 2>&1; then
		echo "error: TCP API still reachable at $builder:2375" >&2
		exit 1
	else
		status=$?
		if [ "$status" -ne 7 ]; then
			echo "error: inconclusive TCP check for $builder (curl $status)" >&2
			exit 1
		fi
	fi
done

echo "ok: both builder APIs use accessible Unix sockets, not TCP"

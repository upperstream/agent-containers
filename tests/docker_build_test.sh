#!/bin/sh

# Build a Dockerfile from the agents service, using the Docker
# daemon in the docker_builder service, and report whether the build
# succeeds.  The host Docker daemon is not used.
#
# Usage:
#   docker_build_test.sh [--cloud ORG/BUILDER] [DOCKERFILE [CONTEXT]]
#   docker_build_test.sh [--cloud=ORG/BUILDER] [DOCKERFILE [CONTEXT]]
# Default:
#   DOCKERFILE: Dockerfile
#   CONTEXT:    .

set -eu

usage() {
	echo "Usage: docker_build_test.sh [--cloud ORG/BUILDER] [DOCKERFILE [CONTEXT]]"
	echo "       docker_build_test.sh [--cloud=ORG/BUILDER] [DOCKERFILE [CONTEXT]]"
}

# shellcheck disable=SC1007
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

cloud_builder=
dockerfile=Dockerfile
context=.
positionals=0
while [ "$#" -gt 0 ]; do
	arg=$1
	shift
	case $arg in
		-h|--help)
			usage
			exit 0
			;;
		--cloud)
			if [ "$#" -eq 0 ] || [ -z "$1" ]; then
				echo "error: --cloud requires ORG/BUILDER" >&2
				usage >&2
				exit 2
			fi
			cloud_builder=$1
			shift
			;;
		--cloud=*)
			cloud_builder=${arg#--cloud=}
			if [ -z "$cloud_builder" ]; then
				echo "error: --cloud requires ORG/BUILDER" >&2
				usage >&2
				exit 2
			fi
			;;
		-*)
			echo "error: unknown option: $arg" >&2
			usage >&2
			exit 2
			;;
		*)
			positionals=$((positionals + 1))
			case $positionals in
				1) dockerfile=$arg ;;
				2) context=$arg ;;
				*)
					echo "error: too many positional arguments" >&2
					usage >&2
					exit 2
					;;
			esac
			;;
	esac
done

if [ -n "$cloud_builder" ]; then
	case $cloud_builder in
		*/*)
			cloud_org=${cloud_builder%%/*}
			cloud_name=${cloud_builder#*/}
			case $cloud_name in
				*/*) cloud_org= ;;
				*) ;;
			esac
			;;
		*) cloud_org= ;;
	esac
	if [ -z "$cloud_org" ] || [ -z "$cloud_name" ]; then
		echo "error: --cloud requires ORG/BUILDER" >&2
		usage >&2
		exit 2
	fi
	buildx_cloud_builder="cloud-$cloud_org-$cloud_name"
fi

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
if [ -n "$cloud_builder" ]; then
	if docker buildx build --builder "$buildx_cloud_builder" --load \
			-t "$image" -f "$dockerfile" "$context"; then
		echo "ok: Docker Build Cloud build succeeded"
		exit 0
	fi
elif docker build -t "$image" -f "$dockerfile" "$context"; then
	echo "ok: docker build succeeded"
	exit 0
fi

echo "error: docker build failed" >&2
exit 1

#!/bin/sh

# Share only this builder's socket with agents.  Podman creates its socket
# with mode 0600, so set group access after the daemon creates it.

set -eu

socket=$1
shift
socket_dir=$(dirname -- "$socket")
mkdir -p "$socket_dir"
chown root:builders "$socket_dir"
chmod 0750 "$socket_dir"
rm -f "$socket"

"$@" &
pid=$!
# shellcheck disable=SC2329
cleanup() {
	trap '' INT TERM
	kill -TERM "$pid" 2>/dev/null || true
	# Let the daemon remove its PID file before PID 1 exits.
	wait "$pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

i=0
while [ ! -S "$socket" ]; do
	if ! kill -0 "$pid" 2>/dev/null; then
		wait "$pid"
		echo "error: builder exited without creating $socket" >&2
		exit 1
	fi
	if [ "$i" -ge 60 ]; then
		echo "error: timed out waiting for $socket" >&2
		exit 1
	fi
	i=$((i + 1))
	sleep 1
done

chgrp builders "$socket"
chmod 0660 "$socket"
wait "$pid"

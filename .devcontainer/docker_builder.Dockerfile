FROM alpine:3.24.1

# docker-engine provides dockerd.  The agents service reaches this
# daemon over TCP on the Compose network.  The host Docker daemon is
# not mounted into agents and is not reachable from it.
#
# Docker 29 defaults to the containerd overlayfs snapshotter, which
# does not fall back when /var/lib/docker sits on overlayfs.  Nested
# overlay mounts then fail with EINVAL.  Disable that snapshotter so
# the legacy graph driver can use overlay2 or vfs, and keep engine
# state on a volume that is not the container overlay.
RUN apk add --no-cache docker-engine
RUN mkdir -p /etc/docker && cat >/etc/docker/daemon.json <<'EOF'
{
  "features": {
    "containerd-snapshotter": false
  }
}
EOF

VOLUME /var/lib/docker

EXPOSE 2375

CMD ["dockerd", \
     "--host=unix:///var/run/docker.sock", \
     "--host=tcp://0.0.0.0:2375", \
     "--tls=false"]

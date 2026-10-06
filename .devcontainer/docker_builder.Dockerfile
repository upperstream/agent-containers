FROM alpine:3.24.1

# docker-engine provides dockerd.  The agents service reaches this
# daemon through a Unix socket shared only with agents.  The host
# Docker daemon socket is not mounted into agents.
#
# Docker 29 defaults to the containerd overlayfs snapshotter, which
# does not fall back when /var/lib/docker sits on overlayfs.  Nested
# overlay mounts then fail with EINVAL.  Disable that snapshotter so
# the legacy graph driver can use overlay2 or vfs, and keep engine
# state on a volume that is not the container overlay.
RUN apk add --no-cache curl docker-engine && \
    addgroup -g 2375 builders
COPY .devcontainer/builder_entrypoint.sh /usr/local/bin/builder-entrypoint
RUN chmod 0755 /usr/local/bin/builder-entrypoint
RUN mkdir -p /etc/docker && cat >/etc/docker/daemon.json <<'EOF'
{
  "features": {
    "containerd-snapshotter": false
  }
}
EOF

VOLUME /var/lib/docker

ENTRYPOINT ["builder-entrypoint", "/run/docker-builder/docker.sock"]

CMD ["dockerd", \
     "--host=unix:///run/docker-builder/docker.sock", \
     "--group=builders"]

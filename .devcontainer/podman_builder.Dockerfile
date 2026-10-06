FROM alpine:3.24.1

# podman provides the engine.  The agents service reaches this
# service through a Unix socket shared only with agents.  The host
# container engine socket is not mounted into agents.
#
# Nested overlay mounts fail with EINVAL when graphroot sits on
# overlayfs.  Keep engine state on a volume that is not the
# container overlay so the kernel overlay driver can be used.
# fuse-overlayfs plus crun on LinuxKit fails container exec with
# EINVAL.  There is no systemd here, so cgroupfs is the cgroup
# manager and runc is the OCI runtime.  netavark needs iptables to
# set up networks for build containers.
RUN apk add --no-cache curl iptables iptables-legacy podman runc && \
    addgroup -g 2375 builders
COPY .devcontainer/builder_entrypoint.sh /usr/local/bin/builder-entrypoint
RUN chmod 0755 /usr/local/bin/builder-entrypoint
RUN mkdir -p /etc/containers
RUN cat >/etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
graphroot = "/var/lib/containers/storage"
runroot = "/run/containers/storage"
EOF
RUN cat >/etc/containers/containers.conf <<'EOF'
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"
runtime = "runc"
EOF

VOLUME /var/lib/containers

ENTRYPOINT ["builder-entrypoint", "/run/podman-builder/podman.sock"]

CMD ["podman", "system", "service", "--time=0", \
     "unix:///run/podman-builder/podman.sock"]

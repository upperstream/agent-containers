FROM alpine:3.24.1

# podman provides the engine.  The agents service reaches this
# service over TCP on the Compose network.  The host container
# engine is not mounted into agents and is not reachable from it.
#
# Nested overlay mounts fail with EINVAL when graphroot sits on
# overlayfs.  Keep engine state on a volume that is not the
# container overlay so the kernel overlay driver can be used.
# fuse-overlayfs plus crun on LinuxKit fails container exec with
# EINVAL.  There is no systemd here, so cgroupfs is the cgroup
# manager and runc is the OCI runtime.  netavark needs iptables to
# set up networks for build containers.
RUN apk add --no-cache iptables iptables-legacy podman runc
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

EXPOSE 2375

CMD ["podman", "system", "service", "--time=0", "tcp://0.0.0.0:2375"]

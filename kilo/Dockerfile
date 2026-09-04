ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'
ARG KILO_VERSION=7.4.23         # '7.4.23'

FROM debian:trixie-slim AS builder_base
RUN apt-get update && \
    apt-get install -y ca-certificates curl

FROM debian:trixie-slim AS container_base
ARG CONTAINER_USER              # global default
ARG NANO_CLASSIC_KEYBINDINGS    # global default

RUN apt-get update && \
    apt-get install -y --no-install-recommends emacs-nox fd-find git mg micro nano ripgrep vim-nox && \
    apt-get clean && \
    useradd -m "${CONTAINER_USER}"
RUN <<EOT /bin/sh
    if [ "${NANO_CLASSIC_KEYBINDINGS:-no}" = "yes" ]; then \
        cat <<EOF >"/home/${CONTAINER_USER}/.nanorc"
        bind ^F forward main
        bind ^B back main
        bind M-F formatter main
        bind M-B linter main
EOF
    fi
EOT

FROM builder_base AS kilo_builder
ARG KILO_VERSION                # global default

RUN curl -fsSL https://kilo.ai/cli/install > kilo_installer.sh
RUN bash kilo_installer.sh ${KILO_VERSION:+--version "$KILO_VERSION"}

# To retain Kilo user data and sessions beyond the container lifespan,
# create a host directory with `share/kilo`, `state/kilo`, and
# `state/kilo-sandbox-policy`, then bind-mount it at `/mnt/kilo`.
# The production image links the corresponding XDG paths to those
# mounted directories.
#
# docker run -e TERM="$TERM" \
#    -v /host/path/kilo:/mnt/kilo -v "$PWD":/workspaces/agent-containers \
#    -w /workspaces/agent-containers -it agents bash

FROM container_base AS production
ARG CONTAINER_USER              # global default

COPY --from=kilo_builder /root/.kilo "/home/${CONTAINER_USER}/.kilo"

RUN ln -s "/home/${CONTAINER_USER}/.kilo/bin/kilo" /usr/local/bin/kilo && \
    mkdir -p "/home/${CONTAINER_USER}/.local/share" && \
    ln -s /mnt/kilo/share/kilo "/home/${CONTAINER_USER}/.local/share/" && \
    mkdir -p "/home/${CONTAINER_USER}/.local/state" && \
    for f in kilo kilo-sandbox-policy; do \
      ln -s "/mnt/kilo/state/$f" "/home/${CONTAINER_USER}/.local/state/"; done && \
    chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

FROM production AS development
ARG CONTAINER_USER              # global default

RUN usermod -a -G sudo "${CONTAINER_USER}"
RUN rm -f /etc/dpkg/dpkg.cfg.d/docker && \
    rm -f /etc/dpkg/dpkg.cfg.d/01_nodo
RUN apt-get update && \
    apt-get install -y --no-install-recommends binutils file opendoas tree
RUN echo "permit nopass :sudo" > /etc/doas.conf
RUN doas -C /etc/doas.conf

FROM "${ENVIRONMENT}"
ARG CONTAINER_USER              # global default
ENV EDITOR="${EDITOR}"
ENV GIT_EDITOR="${GIT_EDITOR}"
ENV TERM="${TERM}"

USER "${CONTAINER_USER}"

WORKDIR /workspaces

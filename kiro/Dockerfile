ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'
ARG KIRO_CHANNEL
ARG KIRO_FORCE                  # '--force', defaults to unset

FROM debian:trixie-slim AS builder_base
RUN apt-get update
RUN apt-get install -y ca-certificates curl

FROM builder_base AS bin_stripper
RUN apt-get install -y binutils

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

FROM bin_stripper AS kiro_builder
ARG KIRO_CHANNEL                # global default
ARG KIRO_FORCE                  # global default

RUN apt-get install -y unzip
RUN curl -fsSL https://cli.kiro.dev/install > kiro_installer.sh
RUN bash kiro_installer.sh ${KIRO_FORCE:+--force} ${KIRO_CHANNEL:+--channel "$KIRO_CHANNEL"}
RUN strip /root/.local/bin/kiro-cli

FROM container_base AS production
ARG CONTAINER_USER              # global default

COPY --from=kiro_builder /root/.local/bin/kiro-cli /usr/local/bin/kiro-cli

RUN chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

FROM production AS development
ARG CONTAINER_USER              # global default

RUN usermod -a -G sudo "${CONTAINER_USER}"
RUN rm -f /etc/dpkg/dpkg.cfg.d/docker && \
    rm -f /etc/dpkg/dpkg.cfg.d/01_nodo
RUN apt-get update
RUN apt-get install -y --no-install-recommends binutils file opendoas tree
RUN echo "permit nopass :sudo" > /etc/doas.conf
RUN doas -C /etc/doas.conf

FROM "${ENVIRONMENT}"
ARG CONTAINER_USER              # global default
ENV EDITOR="${EDITOR}"
ENV GIT_EDITOR="${GIT_EDITOR}"
ENV TERM="${TERM}"

USER "${CONTAINER_USER}"

WORKDIR /workspaces

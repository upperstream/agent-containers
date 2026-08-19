ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'
ARG CRUSH_VERSION=v0.87.0       # 'nightly' or 'v0.89.0'

FROM debian:trixie-slim AS builder_base
RUN apt-get update
RUN apt-get install -y --no-install-recommends ca-certificates curl
RUN apt-get clean

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

FROM builder_base AS crush_builder
ARG CRUSH_VERSION   # global default

RUN ARCH=$(uname -m | sed 's/aarch64/arm64/') && \
    if [ -z "$CRUSH_VERSION" ] || [ "$CRUSH_VERSION" = "nightly" ]; then \
        FILENAME=$(curl -fsSL https://github.com/charmbracelet/crush/releases/download/nightly/checksums.txt | grep "Linux_${ARCH}.tar.gz" | head -n1 | awk '{print $2}'); \
        URL="https://github.com/charmbracelet/crush/releases/download/nightly/${FILENAME}"; \
    else \
        TAG="${CRUSH_VERSION}"; \
        TAG_NO_V=$(echo "$TAG" | sed 's/^v//'); \
        URL="https://github.com/charmbracelet/crush/releases/download/${TAG}/crush_${TAG_NO_V}_Linux_${ARCH}.tar.gz"; \
    fi && \
    curl -fsSL "$URL" -o /root/crush.tar.gz && \
    tar -xzf /root/crush.tar.gz -C /root

FROM container_base AS production
ARG CONTAINER_USER  # global default

RUN chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"
RUN mkdir -p /usr/local/share/doc/crush /etc/bash_completion_d /usr/share/fish/vendor_completions.d /usr/share/zsh/site-functions /usr/local/share/man/man1

COPY --from=crush_builder /root/*/LICENSE.md /usr/local/share/doc/crush/LICENSE.md
COPY --from=crush_builder /root/*/README.md /usr/local/share/doc/crush/README.md
COPY --from=crush_builder /root/*/completions/crush.bash /etc/bash_completion_d/crush
COPY --from=crush_builder /root/*/completions/crush.fish /usr/share/fish/vendor_completions.d/crush.fish
COPY --from=crush_builder /root/*/completions/crush.zsh /usr/share/zsh/site-functions/_crush
COPY --from=crush_builder /root/*/manpages/crush.1.gz /usr/local/share/man/man1/crush.1.gz
COPY --from=crush_builder /root/*/crush /usr/local/bin/crush

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

ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG AIDER_VERSION=0.86.2
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'

FROM debian:trixie-slim AS builder_base
RUN apt-get update && \
    apt-get install -y ca-certificates curl

FROM builder_base AS uv_base
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

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

FROM uv_base AS aider_builder
ARG AIDER_VERSION   # global default
ARG CONTAINER_USER

RUN mkdir -p "/home/${CONTAINER_USER}" && \
    HOME="/home/${CONTAINER_USER}" uv tool install --force --python python3.12 --with pip "aider-chat@${AIDER_VERSION}"

FROM container_base AS production
ARG CONTAINER_USER  # global default

COPY --from=aider_builder "/home/${CONTAINER_USER}/.local/share/uv" "/home/${CONTAINER_USER}/.local/share/uv"

RUN ln -s "/home/${CONTAINER_USER}/.local/share/uv/tools/aider-chat/bin/aider" /usr/local/bin/aider && \
    chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

FROM production AS development
ARG CONTAINER_USER  # global default

RUN usermod -a -G sudo "${CONTAINER_USER}"
RUN rm -f /etc/dpkg/dpkg.cfg.d/docker && \
    rm -f /etc/dpkg/dpkg.cfg.d/01_nodo
RUN apt-get update && \
    apt-get install -y --no-install-recommends binutils file opendoas tree
RUN echo "permit nopass :sudo" > /etc/doas.conf
RUN doas -C /etc/doas.conf

FROM "${ENVIRONMENT}"
ARG CONTAINER_USER  # global default
ENV EDITOR="${EDITOR}"
ENV GIT_EDITOR="${GIT_EDITOR}"
ENV TERM="${TERM}"

USER "${CONTAINER_USER}"

WORKDIR /workspaces

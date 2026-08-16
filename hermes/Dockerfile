ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG HERMES_VERSION=v2026.8.13   # branch (main) or tag (v2026.8.13)
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'

FROM debian:trixie-slim AS builder_base
RUN apt-get update
RUN apt-get install -y ca-certificates curl

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

FROM builder_base AS hermes_builder
ARG HERMES_VERSION	# global default

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl ffmpeg git ripgrep xz-utils
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sed 's!npm install --silent!env PYTHON="${PYTHON_PATH:-$(command -v python)}" npm install --silent!' > hermes_installer.sh
RUN git clone --depth 1 --branch ${HERMES_VERSION:=main} https://github.com/NousResearch/hermes-agent.git /usr/local/lib/hermes-agent
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN bash hermes_installer.sh --skip-setup --skip-browser --non-interactive ${HERMES_VERSION:+--commit "$(git -C /usr/local/lib/hermes-agent rev-parse --short "${HERMES_VERSION}"^{commit})"} --force-commit

FROM container_base AS production
ARG CONTAINER_USER  # global default

COPY --from=hermes_builder /usr/local/lib/hermes-agent /usr/local/lib/hermes-agent
COPY --from=hermes_builder /usr/local/bin/hermes* /usr/local/bin/
COPY --from=hermes_builder /usr/local/share/uv /usr/local/share/uv
COPY --from=hermes_builder /root/.cua-driver "/home/${CONTAINER_USER}/.cua-driver"
COPY --from=hermes_builder /root/.hermes "/home/${CONTAINER_USER}/.hermes"
COPY --from=hermes_builder /root/.local "/home/${CONTAINER_USER}/.local"
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl ffmpeg git ripgrep && \
    apt-get clean && \
    mkdir -p "/home/${CONTAINER_USER}/.local/bin" && \
    (cd "/home/${CONTAINER_USER}/.local/bin" && ln -sf ../../.cua-driver/packages/current/cua-driver) && \
    (cd "/home/${CONTAINER_USER}/.hermes/node/bin" && ln -s node npm npx /usr/local/bin/) && \
    chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

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

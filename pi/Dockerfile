ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'
ARG NODE_VERSION=v24.18.1
ARG NPM_VERSION="12.0.0"
ARG PI_VERSION=0.84.4

FROM debian:trixie-slim AS builder_base
RUN apt-get update
RUN apt-get install -y ca-certificates curl

FROM builder_base AS node_base
ARG NODE_VERSION    # global default
ARG NPM_VERSION     # global default
RUN apt-get install -y xz-utils && \
    case "$(uname -s)" in \
    Linux) kernel=linux; machine="$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/')"; format=xz;; \
    Darwin) kernel=darwin; machine="$(uname -m | sed 's/x86_64/x64/')"; format=gz;; \
    esac && \
    file="$(printf "node-%s-%s-%s.tar.%s" "$NODE_VERSION" "$kernel" "$machine" "$format")" && \
    url="$(printf "https://nodejs.org/dist/%s/%s" "$NODE_VERSION" "$file")" && \
    echo "Node.js package: \"$file\"" && \
    echo "Node.js url:     \"$url\"" && \
    curl -fsSL "$url" > "$file"
RUN echo "TARGETARCH=\"$TARGETARCH\""
RUN tar --xz -C /usr/local -xf "$(echo node-${NODE_VERSION}-*-*.tar.* | tail -n1)"
RUN mv "$(echo /usr/local/node-${NODE_VERSION}-*-* | tail -n1)" /usr/local/node-${NODE_VERSION}
RUN printf 'PATH=$PATH:%s\n' "/usr/local/node-${NODE_VERSION}/bin" >> /root/.bashrc
RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g "npm${NPM_VERSION:+@"${NPM_VERSION}"}"

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

FROM node_base AS pi_builder
ARG CONTAINER_USER
ARG NODE_VERSION
ARG PI_VERSION

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION:-latest}
RUN apt-get update

FROM container_base AS production
ARG CONTAINER_USER  # global default
ARG NODE_VERSION

COPY --from=node_base "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"
COPY --from=pi_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent" "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent"

RUN apt-get update && \
    apt-get install -y --no-install-recommends fd-find ripgrep && \
    apt-get clean && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" /usr/local/bin/pi && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/ && \
    chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

FROM production AS development
ARG CONTAINER_USER  # global default

RUN usermod -a -G sudo "${CONTAINER_USER}"
RUN rm -f /etc/dpkg/dpkg.cfg.d/docker && \
    rm -f /etc/dpkg/dpkg.cfg.d/01_nodo
RUN apt-get update
RUN apt-get install -y --no-install-recommends binutils file opendoas tree
RUN echo "permit nopass :sudo" > /etc/doas.conf
RUN doas -C /etc/doas.conf

FROM "${ENVIRONMENT}"
ARG CONTAINER_USER  # global default
ENV EDITOR="${EDITOR}"
ENV GIT_EDITOR="${GIT_EDITOR}"
ENV TERM="${TERM}"

USER "${CONTAINER_USER}"

WORKDIR /workspaces

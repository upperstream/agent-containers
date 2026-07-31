ARG CONTAINER_USER=user         # 'user'
ARG ENVIRONMENT=production      # 'development' or 'production'
ARG NANO_CLASSIC_KEYBINDINGS    # 'yes', default to 'no'
ARG NODE_VERSION=v24.18.1
ARG NPM_VERSION=                # npm version with node distribution
ARG OPENWIKI_VERSION

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

FROM node_base AS openwiki_builder
ARG NODE_VERSION    # global default

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g openwiki@${OPENWIKI_VERSION:-latest}

FROM container_base AS production
ARG NODE_VERSION    # global default

COPY --from=openwiki_builder "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"

RUN ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/ && \
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

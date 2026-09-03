ARG CONTAINER_USER=user             # 'user'
ARG ENVIRONMENT=production          # 'development' or 'production'
ARG AIDER_VERSION=0.86.2
ARG NANO_CLASSIC_KEYBINDINGS        # 'yes', default to 'no'
ARG NODE_VERSION=v24.20.0
ARG NPM_VERSION=
ARG CLAUDE_VERSION=2.1.236          # 'latest', 'stable', or a version
ARG CLINE_RELEASE=3.0.60            # 'nightly' or '3.0.60'
ARG CODEX_RELEASE=0.148.0           # 'latest' or '0.142.5'
ARG COPILOT_VERSION=1.0.80          # 'latest', 'prerelease', or 'v0.0.369'
ARG CRUSH_VERSION=v0.87.0           # 'nightly' or 'v0.89.0'
ARG DROID_VERSION=0.209.0           # 'latest' or '0.209.0'
ARG GEMINI_RELEASE=0.55.1           # 'latest', 'preview', 'nightly', or '0.55.1'
ARG GROK_CHANNEL
ARG GROK_VERSION=1.0.5              # '1.0.5'
ARG HERMES_VERSION=v2026.8.13       # branch (main) or tag (v2026.8.13)
ARG KILO_VERSION=7.4.23             # '7.4.23'
ARG KIRO_CHANNEL
ARG KIRO_FORCE                      # '--force', defaults to unset
ARG OPENCLAW_VERSION=2026.6.34      # 'latest' or '2026.6.34'
ARG OPENCODE_VERSION=1.18.21        # '1.18.21'
ARG PI_VERSION=0.84.4               # 'latest' or '0.84.4'
ARG PROVIDER=all                    # 'pi' or 'all'

FROM debian:trixie-slim AS builder_base
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl

FROM builder_base AS node_base
ARG NODE_VERSION    # global default
ARG NPM_VERSION     # global default

RUN apt-get update
RUN apt-get install -y xz-utils
RUN case "$(uname -s)" in \
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
RUN if [ -n "$NPM_VERSION" ]; then PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g "npm${NPM_VERSION:+@"${NPM_VERSION}"}"; fi

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

FROM builder_base AS uv_base
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

FROM uv_base AS aider_builder
ARG AIDER_VERSION   # global default
ARG CONTAINER_USER

RUN mkdir -p "/home/${CONTAINER_USER}" && \
    HOME="/home/${CONTAINER_USER}" uv tool install --force --python python3.12 --with pip "aider-chat@${AIDER_VERSION}"

FROM container_base AS aider
ARG CONTAINER_USER  # global default

COPY --from=aider_builder "/home/${CONTAINER_USER}/.local/share/uv" "/home/${CONTAINER_USER}/.local/share/uv"

RUN ln -s "/home/${CONTAINER_USER}/.local/share/uv/tools/aider-chat/bin/aider" /usr/local/bin/aider

FROM builder_base AS agy_builder
RUN curl -fsSL https://antigravity.google/cli/install.sh > antigravity_installer.sh
RUN bash antigravity_installer.sh

FROM container_base AS antigravity
ARG CONTAINER_USER  # global default

COPY --from=agy_builder /root/.local/bin/agy /usr/local/bin/agy

FROM builder_base AS claude_builder
ARG CLAUDE_VERSION   # global default

RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_VERSION}"
RUN install -Dm0755 "$(readlink -f /root/.local/bin/claude)" /usr/local/bin/claude

FROM container_base AS claude

COPY --from=claude_builder /usr/local/bin/claude /usr/local/bin/claude

FROM node_base AS cline_builder
ARG CLINE_RELEASE   # global default
ARG NODE_VERSION    # global default

RUN PATH=$PATH:/usr/local/node-${NODE_VERSION}/bin npm install -g cline${CLINE_RELEASE:+@"$CLINE_RELEASE"}

FROM container_base AS cline
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

COPY --from=node_base /usr/local/node-${NODE_VERSION} /usr/local/node-${NODE_VERSION}
COPY --from=cline_builder /usr/local/node-${NODE_VERSION}/lib/node_modules/cline /usr/local/node-${NODE_VERSION}/lib/node_modules/cline

RUN ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/cline/bin/cline" /usr/local/bin/cline && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/

FROM builder_base AS codex_builder
ARG CODEX_RELEASE   # global default

RUN echo "CODEX_RELEASE=\"$CODEX_RELEASE\""
RUN curl -fsSL https://chatgpt.com/codex/install.sh > codex_installer.sh
RUN CODEX_NON_INTERACTIVE=1 sh codex_installer.sh

FROM container_base AS codex
ARG CONTAINER_USER  # global default

COPY --from=codex_builder /root/.codex "/home/${CONTAINER_USER}/.codex"

RUN mkdir -p "/home/${CONTAINER_USER}/.local/bin" && \
    (cd "/home/${CONTAINER_USER}/.codex/packages/standalone" && \
        ln -s $(readlink current | sed 's!/root/.codex/packages/standalone/!!' && rm current) current) && \
    (cd $(echo "/home/${CONTAINER_USER}"/.codex/tmp/arg0/* | head -n1) && \
        for f in *; do echo ">>>> $f <<<<"; ln -sf "$(printf "../../../%s" "$(readlink "$f" | sed 's!/root/.codex/!!' && rm "$f")")" "$f"; done) && \
    ln -sf "/home/${CONTAINER_USER}/.codex/packages/standalone/current/bin/codex" "/home/${CONTAINER_USER}/.local/bin/" && \
    apt-get update && \
    apt-get install -y --no-install-recommends bubblewrap ca-certificates curl && \
    apt-get clean && \
    chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

FROM builder_base AS copilot_builder
ARG COPILOT_VERSION # global default

RUN curl -fsSL https://gh.io/copilot-install > copilot_installer.sh
RUN VERSION="${COPILOT_VERSION:-latest}" bash copilot_installer.sh

FROM container_base AS copilot
ARG CONTAINER_USER  # global default

COPY --from=copilot_builder /usr/local/bin/copilot /usr/local/bin/copilot

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

FROM container_base AS crush
ARG CONTAINER_USER  # global default

RUN chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}" && \
RUN mkdir -p /usr/local/share/doc/crush /etc/bash_completion_d /usr/share/fish/vendor_completions.d /usr/share/zsh/site-functions /usr/local/share/man/man1

COPY --from=crush_builder /root/*/LICENSE.md /usr/local/share/doc/crush/LICENSE.md
COPY --from=crush_builder /root/*/README.md /usr/local/share/doc/crush/README.md
COPY --from=crush_builder /root/*/completions/crush.bash /etc/bash_completion_d/crush
COPY --from=crush_builder /root/*/completions/crush.fish /usr/share/fish/vendor_completions.d/crush.fish
COPY --from=crush_builder /root/*/completions/crush.zsh /usr/share/zsh/site-functions/_crush
COPY --from=crush_builder /root/*/manpages/crush.1.gz /usr/local/share/man/man1/crush.1.gz
COPY --from=crush_builder /root/*/crush /usr/local/bin/crush

FROM builder_base AS cursor_builder
RUN curl https://cursor.com/install -fsS > cursor_installer.sh
RUN bash cursor_installer.sh

FROM container_base AS cursor
ARG CONTAINER_USER  # global default

COPY --from=cursor_builder /root/.local/share/cursor-agent/versions "/home/${CONTAINER_USER}/.local/share/cursor-agent/versions"

RUN ln -s "$(echo /home/${CONTAINER_USER}/.local/share/cursor-agent/versions/*-*/cursor-agent)" /usr/local/bin/cursor-agent

FROM node_base AS droid_builder
ARG DROID_VERSION   # global default
ARG NODE_VERSION    # global default

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g --ignore-scripts "droid@${DROID_VERSION:-latest}"

FROM container_base AS droid
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

COPY --from=node_base "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"
COPY --from=droid_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid" "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid"

RUN ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid/bin/droid" /usr/local/bin/droid && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/

FROM node_base AS gemini_builder
ARG GEMINI_RELEASE  # global default
ARG NODE_VERSION    # global default

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g "@google/gemini-cli@${GEMINI_RELEASE:-latest}"

FROM container_base AS gemini
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

COPY --from=node_base "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"
COPY --from=gemini_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google" "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google"

RUN ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google/gemini-cli/bundle/gemini.js" /usr/local/bin/gemini && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/

FROM builder_base AS grok_builder
ARG GROK_CHANNEL    # global default
ARG GROK_VERSION    # global default

RUN curl -fsSL https://x.ai/cli/install.sh > grok_installer.sh
RUN bash grok_installer.sh "${GROK_VERSION:+"$GROK_VERSION"}"
RUN case "$(uname -s)" in \
    Linux) kernel=linux; machine="$(uname -m)";; \
    Darwin) kernel=darwin; machine="$(uname -m)";; \
    esac && \
    ln -s "/root/.grok/downloads/grok-$kernel-$machine" /root/.grok/downloads/grok

FROM container_base AS grok
ARG CONTAINER_USER  # global default

COPY --from=grok_builder /root/.grok "/home/${CONTAINER_USER}/.local/share/grok"
RUN mkdir -p "/home/${CONTAINER_USER}/.grok/" && \
    for f in active_sessions.json active_sessions.lock config.toml; do \
      mv "/home/${CONTAINER_USER}/.local/share/grok/$f" "/home/${CONTAINER_USER}/.grok/"; done && \
    for f in bin completions docs downloads; do \
      ln -s "/home/${CONTAINER_USER}/.local/share/grok/$f" "/home/${CONTAINER_USER}/.grok/"; done && \
    ln -s "/home/${CONTAINER_USER}/.local/share/grok/bin/grok" /usr/local/bin/grok

FROM bin_stripper AS herdr_builder

RUN apt-get update
RUN apt-get install -y --no-install-recommends ca-certificates curl
RUN curl -fsSL https://herdr.dev/install.sh > herdr_installer.sh
RUN sh herdr_installer.sh
RUN strip /root/.local/bin/herdr

FROM container_base AS herdr
ARG CONTAINER_USER  # global default

COPY --from=herdr_builder /root/.local/bin/herdr /usr/local/bin/herdr

FROM builder_base AS hermes_builder
ARG HERMES_VERSION	# global default

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl ffmpeg git ripgrep xz-utils
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sed 's!npm install --silent!env PYTHON="${PYTHON_PATH:-$(command -v python)}" npm install --silent!' > hermes_installer.sh
RUN git clone --depth 1 --branch ${HERMES_VERSION:=main} https://github.com/NousResearch/hermes-agent.git /usr/local/lib/hermes-agent
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN bash hermes_installer.sh --skip-setup --skip-browser --non-interactive ${HERMES_VERSION:+--commit "$(git -C /usr/local/lib/hermes-agent rev-parse --short "${HERMES_VERSION}"^{commit})"} --force-commit

FROM builder_base AS kilo_builder
ARG KILO_VERSION    # global default

RUN curl -fsSL https://kilo.ai/cli/install > kilo_installer.sh
RUN bash kilo_installer.sh ${KILO_VERSION:+--version "$KILO_VERSION"}

FROM container_base AS kilo
ARG CONTAINER_USER  # global default

COPY --from=kilo_builder /root/.kilo "/home/${CONTAINER_USER}/.kilo"
RUN ln -s "/home/${CONTAINER_USER}/.kilo/bin/kilo" /usr/local/bin/kilo

FROM bin_stripper AS kiro_builder
ARG KIRO_CHANNEL    # global default
ARG KIRO_FORCE      # global default

RUN apt-get install -y unzip
RUN curl -fsSL https://cli.kiro.dev/install > kiro_installer.sh
RUN bash kiro_installer.sh ${KIRO_FORCE:+--force} ${KIRO_CHANNEL:+--channel "$KIRO_CHANNEL"}
RUN strip /root/.local/bin/kiro-cli

FROM container_base AS kiro

COPY --from=kiro_builder /root/.local/bin/kiro-cli /usr/local/bin/kiro-cli

FROM node_base AS openclaw_builder
ARG NODE_VERSION                # global default
ARG OPENCLAW_VERSION=2026.6.34  # 'latest' or '2026.6.34'

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g "openclaw@${OPENCLAW_VERSION:-latest}"

FROM container_base AS openclaw
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw/openclaw.mjs" /usr/local/bin/openclaw && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/ && \
    useradd -m "${CONTAINER_USER}"

COPY --from=openclaw_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw" "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw"

FROM builder_base AS opencode_builder
ARG OPENCODE_VERSION    # global default

RUN curl -fsSL https://opencode.ai/install > opencode_installer.sh
RUN bash opencode_installer.sh --no-modify-path ${OPENCODE_VERSION:+--version "$OPENCODE_VERSION"}

FROM container_base AS opencode

COPY --from=opencode_builder /root/.opencode/bin/opencode /usr/local/bin/opencode

FROM builder_base AS openwiki_builder
ARG NODE_VERSION            # global default
ARG OPENWIKI_VERSION

RUN apt-get update
RUN apt-get install -y xz-utils
RUN case "$(uname -s)" in \
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

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g openwiki@${OPENWIKI_VERSION:-latest}

FROM container_base AS openwiki
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

COPY --from=openwiki_builder "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"

RUN ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/

FROM node_base AS pi_builder
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default
ARG PI_VERSION      # global default

RUN PATH="$PATH:/usr/local/node-${NODE_VERSION}/bin" npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION:-latest}
RUN apt-get update

FROM container_base AS pi
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

COPY --from=pi_builder "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"
COPY --from=pi_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent" "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent"

RUN apt-get update && \
    apt-get install -y --no-install-recommends fd-find ripgrep && \
    apt-get clean && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" /usr/local/bin/pi && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/

FROM container_base AS all
ARG CONTAINER_USER  # global default
ARG NODE_VERSION    # global default

RUN mkdir -p /usr/local/share/doc/crush /etc/bash_completion_d /usr/share/fish/vendor_completions.d /usr/share/zsh/site-functions /usr/local/share/man/man1

COPY --from=node_base "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"

COPY --from=aider_builder "/home/${CONTAINER_USER}/.local/share/uv" "/home/${CONTAINER_USER}/.local/share/uv"

COPY --from=agy_builder /root/.local/bin/agy /usr/local/bin/agy

COPY --from=claude_builder /usr/local/bin/claude /usr/local/bin/claude

COPY --from=cline_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/cline" "/usr/local/node-${NODE_VERSION}/lib/node_modules/cline"

COPY --from=codex_builder /root/.codex "/home/${CONTAINER_USER}/.codex"

COPY --from=copilot_builder /usr/local/bin/copilot /usr/local/bin/copilot

COPY --from=crush_builder /root/*/LICENSE.md /usr/local/share/doc/crush/LICENSE.md
COPY --from=crush_builder /root/*/README.md /usr/local/share/doc/crush/README.md
COPY --from=crush_builder /root/*/completions/crush.bash /etc/bash_completion_d/crush
COPY --from=crush_builder /root/*/completions/crush.fish /usr/share/fish/vendor_completions.d/crush.fish
COPY --from=crush_builder /root/*/completions/crush.zsh /usr/share/zsh/site-functions/_crush
COPY --from=crush_builder /root/*/manpages/crush.1.gz /usr/local/share/man/man1/crush.1.gz
COPY --from=crush_builder /root/*/crush /usr/local/bin/crush

COPY --from=cursor_builder /root/.local/share/cursor-agent/versions "/home/${CONTAINER_USER}/.local/share/cursor-agent/versions"

COPY --from=droid_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid" "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid"

COPY --from=gemini_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google" "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google"

COPY --from=grok_builder /root/.grok "/home/${CONTAINER_USER}/.local/share/grok"

COPY --from=herdr_builder /root/.local/bin/herdr /usr/local/bin/herdr

COPY --from=hermes_builder /usr/local/lib/hermes-agent /usr/local/lib/hermes-agent
COPY --from=hermes_builder /usr/local/bin/hermes* /usr/local/bin/
COPY --from=hermes_builder /usr/local/share/uv /usr/local/share/uv
COPY --from=hermes_builder /root/.cua-driver "/home/${CONTAINER_USER}/.cua-driver"
COPY --from=hermes_builder /root/.hermes "/home/${CONTAINER_USER}/.hermes"
COPY --from=hermes_builder /root/.local "/home/${CONTAINER_USER}/.local"

COPY --from=kilo_builder /root/.kilo "/home/${CONTAINER_USER}/.kilo"

COPY --from=kiro_builder /root/.local/bin/kiro-cli /usr/local/bin/kiro-cli

COPY --from=openclaw_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw" "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw"

COPY --from=opencode_builder /root/.opencode/bin/opencode /usr/local/bin/opencode

COPY --from=openwiki_builder "/usr/local/node-${NODE_VERSION}" "/usr/local/node-${NODE_VERSION}"

COPY --from=pi_builder "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent" "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent"

RUN mkdir -p "/home/${CONTAINER_USER}/.local/bin" && \
    ln -s /usr/local/"node-${NODE_VERSION}"/bin/* /usr/local/bin/ && \
    ln -s "/home/${CONTAINER_USER}/.local/share/uv/tools/aider-chat/bin/aider" /usr/local/bin/aider && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/cline/bin/cline" /usr/local/bin/cline && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/droid/bin/droid" /usr/local/bin/droid && \
    (cd "/home/${CONTAINER_USER}/.codex/packages/standalone" && \
        ln -s $(readlink current | sed 's!/root/.codex/packages/standalone/!!' && rm current) current) && \
    (cd $(echo "/home/${CONTAINER_USER}"/.codex/tmp/arg0/* | head -n1) && \
        for f in *; do echo ">>>> $f <<<<"; ln -sf "$(printf "../../../%s" "$(readlink "$f" | sed 's!/root/.codex/!!' && rm "$f")")" "$f"; done) && \
    ln -sf "/home/${CONTAINER_USER}/.codex/packages/standalone/current/bin/codex" "/home/${CONTAINER_USER}/.local/bin/" && \
    ln -s "$(echo /home/${CONTAINER_USER}/.local/share/cursor-agent/versions/*-*/cursor-agent)" /usr/local/bin/cursor-agent && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/@google/gemini-cli/bundle/gemini.js" /usr/local/bin/gemini && \
    mkdir -p "/home/${CONTAINER_USER}/.grok/" && \
    for f in active_sessions.json active_sessions.lock config.toml; do \
      mv "/home/${CONTAINER_USER}/.local/share/grok/$f" "/home/${CONTAINER_USER}/.grok/"; done && \
    for f in bin completions docs downloads; do \
      ln -s "/home/${CONTAINER_USER}/.local/share/grok/$f" "/home/${CONTAINER_USER}/.grok/"; done && \
    ln -s "/home/${CONTAINER_USER}/.local/share/grok/bin/grok" /usr/local/bin/grok && \
    (cd "/home/${CONTAINER_USER}/.local/bin" && ln -sf ../../.cua-driver/packages/current/cua-driver) && \
    ln -s "/home/${CONTAINER_USER}/.kilo/bin/kilo" /usr/local/bin/kilo && \
    mkdir -p "/home/${CONTAINER_USER}/.local/share" && \
    ln -s /mnt/kilo/share/kilo "/home/${CONTAINER_USER}/.local/share/" && \
    mkdir -p "/home/${CONTAINER_USER}/.local/state" && \
    for f in kilo kilo-sandbox-policy; do \
      ln -s "/mnt/kilo/state/$f" "/home/${CONTAINER_USER}/.local/state/"; done && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/openclaw/openclaw.mjs" /usr/local/bin/openclaw && \
    ln -s "/usr/local/node-${NODE_VERSION}/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" /usr/local/bin/pi && \
    apt-get update && \
    apt-get install -y --no-install-recommends bubblewrap ca-certificates curl ffmpeg git ripgrep && \
    apt-get clean && \
    printf 'PATH=$PATH:%s\n' "/usr/local/node-${NODE_VERSION}/bin" >> "/home/${CONTAINER_USER}/.bashrc"

FROM "${PROVIDER}" AS production
ARG CONTAINER_USER  # global default

RUN chown -R "${CONTAINER_USER}:$(id -g ${CONTAINER_USER})" "/home/${CONTAINER_USER}"

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
ENV PATH="/home/${CONTAINER_USER}/.local/bin:${PATH}"
ENV TERM="${TERM}"

USER "${CONTAINER_USER}"

WORKDIR /workspaces

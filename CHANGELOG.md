# Changelog

## [Unreleased][]

* Added:
  * Add a `docker_builder` service to the Dev Container Compose
    overlay.  It is built from
    `.devcontainer/docker_builder.Dockerfile` on `alpine:3.24.1`
    and runs a Docker daemon that waits for requests from the
    `agents` service.  The host Docker daemon is not mounted into
    `agents`; clients there use `DOCKER_HOST` through a shared Unix
    socket.  Engine data is stored on a named volume at
    `/var/lib/docker`, and the Docker 29 containerd overlayfs
    snapshotter is disabled so nested builds do not fail with
    overlay `EINVAL`.
  * Add `tests/docker_build_test.sh` to build the root Dockerfile from
    inside the `agents` service against that daemon and report whether
    the build succeeds.
  * Add a `podman_builder` service to the Dev Container Compose
    overlay.  It is built from
    `.devcontainer/podman_builder.Dockerfile` on `alpine:3.24.1`
    and runs a Podman API service that waits for requests from the
    `agents` service.  The host container engine is not mounted into
    `agents`; clients there use `CONTAINER_HOST` through a shared Unix
    socket.  Engine data is stored on a named volume at
    `/var/lib/containers` so the kernel overlay driver can be used.
    The image installs iptables so netavark can set up networks for
    build containers.
  * Add `tests/podman_build_test.sh` to build the root Dockerfile from
    inside the `agents` service against that service and report
    whether the build succeeds.
* Changed:
  * Replace the Dev Container builders' TCP API listeners with Unix
    sockets on separate named volumes shared only with `agents`.
    Grant non-root access through supplemental GID 2375, mount socket
    directories read-only into `agents`, and use socket-based health
    checks and build-test defaults.  Add
    `tests/builder_socket_test.sh` to check access and TCP isolation.
  * Require password authentication for `doas` in the `development`
    stages of the root and standalone Dockerfiles.  Document setting or
    replacing the container user's password interactively with
    `docker compose exec` or `docker exec` after the container starts.
  * Install the Docker client (`docker-cli`) and Docker Buildx
    (`docker-buildx`) in the `development` stage of the root
    Dockerfile so that Docker build tests can run inside the `agents`
    service.
  * Install the Podman Remote CLI (`podman-remote`) in the
    `development` stage of the root Dockerfile so that Podman build
    tests can run inside the `agents` service.
  * Allow `tests/docker_build_test.sh` and
    `tests/podman_build_test.sh` to accept optional Dockerfile and
    build-context arguments.  They default to the root `Dockerfile`
    and repository context.
  * [Claude Code][]: Upgrade to version 2.1.283.  Applies to the root
    multi-stage image and the standalone `claude/` build.
  * [Hermes Agent][]:
    * Upgrade to v2026.9.24.
    * Use `scripts/install.sh` from the cloned repository instead of
      fetching the bootstrap script from the web.

## [20261004][]

* Added:
  * Add a build script `build.sh` for image creation and tagging.
  * Add a built-in self-test to `build.sh`, run with `build.sh --test`.
* Changed:
  * [Crush][]: Fix syntax error in multi-stage Dockerfile where `RUN`
    was duplicated after `&&`.
  * [Herdr][]:
    * Add a patch for installer script to accept Herdr version number to
      install.
    * Pin version to 0.8.2.
  * [OpenClaw][]: Fix `useradd` error in multi-stage Dockerfile where
    `useradd` was redundantly called in the `openclaw` stage after
    already being performed in `container_base`.
  * [Pi coding agent][]: Use `ln -sf` when linking `pi` CLI binary into
    `/usr/local/bin` to overwrite the existing symlink created from Node
    package bin.
  * Make apt-get update and apt-get install atomic.
  * Change `build.sh` to accept the `-a`/`--all` option for building
    the full provider set; the `all` argument is no longer a valid
    provider name.
  * Update `.editorconfig` to set shell script indentation style.
  * Update the document standard agent skill to add clarification for
    code span length.
  * Update documentation standards for clarity and consistency.
  * Ignore [Aider][] files matching `.aider.*`, and contents of
    [Hermes Agent][] `.hermes/` and [Droid CLI][] `.factory/`
    directories.
  * Clarify in `README.md` that `Dockerfile` defines the complete
    Docker image configuration, while `docker-compose.yml` provides
    an optional Docker Compose convenience wrapper around it.
  * Update `README.md` to explain the roles of `.devcontainer/devcontainer.json`
    and `.devcontainer/docker-compose.devcontainer.yml` for VS Code Dev
    Container support.

## [20260904][]

* Changed:
  * Aider
    * Pin version to 0.86.2.  Use [uv][] (`uv tool install`) instead of
      the official `aider.chat/install.sh` script.  Default
      `AIDER_VERSION` is `0.86.2`.  Applies to the root multi-stage
      image and the standalone `aider/` build.
    * Document extracting Aider configuration, per-user data, project
      chat history, input history, and optional repo-map cache files
      from the container before removal when state is not bind-mounted.
  * [Claude Code][]:
    * Use the official `claude.ai/install.sh` one-liner install script
      instead of installing the `claude-code` apt package.
    * Pin version to 2.1.236 via the new `CLAUDE_VERSION` build argument
      (accepts a specific version, or `latest`/`stable` to track a
      release channel).  Applies to the root multi-stage image and the
      standalone `claude/` build.
  * [Cline][]: Pin version to 3.0.60.  The `CLINE_RELEASE` build
    argument now defaults to `3.0.60` (it was previously unset,
    installing the latest release).  Applies to the root multi-stage
    image and the standalone `cline/` build.
  * [Droid CLI][]:
    * Install the `droid` npm package via `npm install -g
      --ignore-scripts` instead of the `app.factory.ai/cli` installer
      script.  The CLI now runs on a bundled Node.js runtime.
    * Add `DROID_VERSION` (default `0.209.0`) to select the `droid`
      package version, and `NODE_VERSION`/`NPM_VERSION` to select the
      bundled Node.js/npm.  Applies to the root multi-stage image and
      the standalone `droid/` build.
    * Do not strip the Bun-compiled executable, preserving its
      embedded application payload.
  * [OpenWiki][]:
    * Pin version to 0.5.0.  The `OPENWIKI_VERSION` build argument now
      defaults to `0.5.0` (it was previously unset, installing the
      latest release).  Applies to the root multi-stage image and the
      standalone `openwiki-agent/` build.
    * Remove the `OPENWIKI_NODE_VERSION` build argument so that OpenWiki
      in the root multi-stage image is built on the shared
      `NODE_VERSION` (v24.20.0) like the other agents.  The standalone
      `openwiki-agent/` build now also defaults `NODE_VERSION` to
      v24.20.0.
  * Pi coding agent: Pin version to 0.84.4.  The `PI_VERSION` build
    argument now defaults to `0.84.4` (it was previously unset,
    installing the latest release).  Applies to the root multi-stage
    image and the standalone `pi/` build.
  * Upgrade [Node.js][] to v24.20.0 in the root multi-stage image and
    the standalone `cline/`, `droid/`, `gemini/`, `openclaw/`,
    `openwiki/`, and `pi/` builds.
  * Remove specifying the npm version in the root multi-stage image and
    the standalone `cline/`, `droid/`, `gemini/`, `openclaw/`,
    `openwiki/`, and `pi/` builds.  Now npm bundled with Node.js is kept
    unless `NPM_VERSION` is explicitly set.

## [20260823][]

* Added:
  * Add an agent skill for documentation standards.
* Changed:
  * [Codex CLI][]:
    * Upgrade to version 0.148.0.
    * Install `bubblewrap`, `ca-certificates`, and `curl` in Codex
      images.
    * Add the container user's `~/.local/bin` directory to the
      image-wide `PATH`, allowing `codex` to be run directly.
  * Crush:
    * Upgrade to v0.87.0.
    * Use precompiled package rather than compiling source code.
  * [Gemini CLI][]:
    * Pin release to version 0.55.1.
    * Document preparing and mounting a `.gemini` state directory to
      persist user data and session information.
  * [GitHub Copilot CLI][]:
    * Upgrade to version 1.0.80
  * [Grok Build][]:
    * Pin version to 1.0.5.
    * Keep the install bundle under `~/.local/share/grok`.  Bind-mount
      a host directory onto `~/.grok` with dangling symlinks to `bin`,
      `completions`, `docs`, and `downloads`.
    * By this change online update is discarded one the container
      exists.
  * [Kilo CLI][]:
    * Pin version to 7.4.23.
    * Do not strip the Bun-compiled executable, preserving its embedded
      application payload.
    * Document mounting a host `kilo` directory at `/mnt/kilo` to retain
      user data, sessions, and sandbox-policy state.
  * OpenClaw: Pin version to 2026.6.34.
  * [OpenCode][]:
    * Pin version to 1.18.21.
    * Do not strip the Bun-compiled executable, preserving its embedded
      application payload.
  * Update documentation standards:
    * Allow a line in GFM table to exceeds the line length limit.
    * Make markdownlint configuration consistent with the
      `document-standards` agent skill.
  * Update `README.md` files in accordance to the latest documentation
    standards.

## [20260817][]

* Changed:
  * Codex CLI:
    * Upgrade to v0.147.0.
    * Keep installed bundle inside `$HOME/.codex` directory.
    * Move `codex` executable into `$HOME/.local/bin` directory, which
      is now included in `PATH` environment variable.
    * Update document.
  * Hermes Agent: Suppress verbose output during installation.
* Fixed:
  * Codex CLI: The following bundled executables were not installed:
    * `codex-code-mode-host`
    * `apply_patch`
    * `applypatch`
    * `codex-execve-wrapper`
    * `codex-linux-sandbox`
  * Hermes Agent: `HERMES_VERSION` did not work for tag name.

## [20260815][]

* Changed
  * Upgrade Hermes Agent to v2026.8.13.
    * Replace `HERMES_COMMIT` with `HERMES_VERSION` for selecting the
      Hermes branch or tag.
    * Remove `HERMES_NODE_VERSION` because Node.js is automatically
      installed by the Hermes installer.
    * Install Hermes and its runtime dependencies through the updated
      source-based installation flow, including `uv` and the CUA driver.
    * Document extracting the preinstalled Hermes home directory before
      mounting it for persistent configuration, credentials, and
      sessions.

## [20260807][]

* Changed
  * Upgrade Hermes Agent to v2026.8.3.
    * Introduce `HERMES_COMMIT` to specify commit hash to install Hermes
      Agent with.
    * Introduce `HERMES_NODE_VERSION` to specify [Node.js][] version for
      Hermes Agent.
    * Use Node.js v22.23.2 for Hermes Agent.

## [20260801][]

* Changed
  * Upgrade [Node.js][] for [OpenWiki][] to v24.18.1.

## [20260731][]

* Added
  * Add Hermes Agent.
* Changed
  * Upgrade Node.js to v24.18.1 mitigating vulnerabilities.  See
    [Node.js v24.18.1 release notes](https://nodejs.org/en/blog/release/v24.18.1)
    for details.
  * Change directory name for OpenWiki from `openwiki` to
    `openwiki-agent` because OpenWiki Repository Mode creates files in
    `openwiki` directory by default.
  * Use Node.js v22.14.0 for OpenWiki in order to properly install
    `better-sqlite3`.

[Aider]: https://aider.chat/
  "Aider - AI Pair Programming in Your Terminal"
[Claude Code]: https://claude.com/product/claude-code
  "Claude Code by Anthropic | AI Coding Agent, Terminal, IDE"
[Cline]: https://cline.bot/cli
  "Cline CLI - Coding Agents in Your Terminal and on a Kanban Board"
[Codex CLI]: https://learn.chatgpt.com/docs/codex/cli
  "CLI – Codex | OpenAI Developers"
[Crush]: https://github.com/charmbracelet/crush
  "charmbracelet/crush: Glamourous agentic coding for all 💘"
[Droid CLI]: https://factory.com/product/cli
  "Factory Terminal UI | Interactive AI Agents in Your Terminal"
[Gemini CLI]: https://github.com/google-gemini/gemini-cli
  "Google Gemini CLI"
[GitHub Copilot CLI]: https://github.com/features/copilot/cli
  "GitHub Copilot CLI"
[Grok Build]: https://x.ai/build "Grok Build | SpaceXAI"
[Herdr]: https://herdr.dev/ "Herdr: the runtime coding agents run on"
[Hermes Agent]: https://hermes-agent.nousresearch.com/
  "Hermes Agent | Nous Research"
[Kilo CLI]: https://kilo.ai/cli
  "Kilo CLI – Open Source CLI Coding Agent"
[OpenClaw]: https://openclaw.ai/ "OpenClaw — Personal AI Assistant"
[OpenCode]: https://opencode.ai/
  "OpenCode | The open source AI coding agent"
[Node.js]: https://nodejs.org/ "Node.js — Run JavaScript Everywhere"
[OpenWiki]: https://github.com/langchain-ai/openwiki
  "langchain-ai/openwiki: OpenWiki is a CLI that writes and maintains agent documentation for your codebase."
[Pi coding agent]: https://pi.dev/ "Pi Coding Agent"
[uv]: https://docs.astral.sh/uv/
  "uv - An extremely fast Python package and project manager"

## [20260711][]

* Initial release.

[Unreleased]: https://github.com/upperstream/agent-containers/compare/20261004...HEAD
[20261004]: https://github.com/upperstream/agent-containers/compare/20260823...20261004
[20260904]: https://github.com/upperstream/agent-containers/compare/20260823...20260904
[20260823]: https://github.com/upperstream/agent-containers/compare/20260817...20260823
[20260817]: https://github.com/upperstream/agent-containers/compare/20260815...20260817
[20260815]: https://github.com/upperstream/agent-containers/compare/20260807...20260815
[20260807]: https://github.com/upperstream/agent-containers/compare/20260801...20260807
[20260801]: https://github.com/upperstream/agent-containers/compare/20260731...20260801
[20260731]: https://github.com/upperstream/agent-containers/compare/20260711...20260731
[20260711]: https://github.com/upperstream/agent-containers/releases/tag/20260711

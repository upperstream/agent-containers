# agent-containers

Debian-based Docker images for terminal coding agents and related CLIs.
Each image includes a non-root user, a shared editor/search toolkit, and
one agent (standalone builds) or many agents (root multi-stage `all`
image).

Use this repo in either of two ways:

1. **Standalone image** - build only the agent you need from
   `./<agent>/Dockerfile` (smaller, focused docs next to the install).
2. **Root multi-stage image** - build from the top-level
   [`Dockerfile`](Dockerfile) with `PROVIDER=<stage>` or `PROVIDER=all`.

Agent-specific install details, version pins, auth, and persistence
notes live in each agent's README (linked below).  This document covers
the shared layout and how to build.

## Dockerfile and Docker Compose

The root [`Dockerfile`](Dockerfile) is the complete Docker image
configuration: it defines the build stages, installed tools, and default
runtime settings.  You can build it with `docker build` and run the
resulting image with `docker run`; Docker Compose is not required.

The [`docker-compose.yml`](docker-compose.yml) file configures Docker
Compose as an optional convenience wrapper around that Dockerfile.  It
uses the repository root as the build context and supplies build
arguments, host-directory mounts, and interactive shell settings for the
`agents` service.  It reuses the Dockerfile rather than replacing or
duplicating the image build configuration.

The `.devcontainer/` directory contains configuration for using this
repository as a VS Code Dev Container:

- The `.devcontainer/devcontainer.json` configuration file sets up the
  dev container by loading both the root `docker-compose.yml` and the
  `docker-compose.devcontainer.yml` override.  It targets the `agents`
  service, sets the workspace folder to `/workspaces/agent-containers`,
  mounts the host's Claude and Hermes directories to the `devcontainer`
  user's home, passes through the `TERM` environment variable, runs
  `git config --global --add safe.directory` as a post-create command,
  and configures the terminal to use bash.  The container runs as the
  non-root `devcontainer` user.
- The `.devcontainer/docker-compose.devcontainer.yml` configuration file
  provides Docker Compose overrides for the dev container.  It sets
  build arguments to use `CONTAINER_USER=devcontainer`,
  `ENVIRONMENT=development`, and `NANO_CLASSIC_KEYBINDINGS=yes`.  It
  mounts the host Claude, Grok, and Hermes directories (with
  environment variable fallbacks) to `/home/devcontainer/`, and mounts
  `/dev/null` over the default `/home/user/.claude` and
  `/home/user/.hermes` to prevent conflicts with the standard image
  layout.  It also starts a `docker_builder` service, built from
  `.devcontainer/docker_builder.Dockerfile` on `alpine:3.24.1`, that
  runs a Docker daemon.  The host Docker socket is not mounted into
  `agents`; clients use the sibling engine instead.  The service
  sets `DOCKER_HOST` to `unix:///run/docker-builder/docker.sock`.
  The socket directory is shared through the `docker_builder_socket`
  volume, mounted only into that builder and `agents`.  There is no
  TCP API listener.  Engine state in `docker_builder` is stored
  on the `docker_builder_data` volume at `/var/lib/docker` so image
  layers are not written on the container overlayfs.  The daemon
  disables Docker 29's containerd overlayfs snapshotter, so the
  legacy graph driver can use overlay2 or fall back to vfs.  Run
  `tests/docker_build_test.sh` in `agents` to build the root
  [`Dockerfile`](Dockerfile) against `docker_builder` and check
  whether the build succeeds.  A `podman_builder` service is built
  from `.devcontainer/podman_builder.Dockerfile` on `alpine:3.24.1`
  and runs a Podman API service.  The host container engine is not
  mounted into `agents`.  The `agents` service sets `CONTAINER_HOST`
  to `unix:///run/podman-builder/podman.sock`.  The socket directory
  is shared through the `podman_builder_socket` volume, mounted only
  into that builder and `agents`.  There is no TCP API listener.
  Engine state in `podman_builder` is stored on the
  `podman_builder_data` volume at `/var/lib/containers` so the
  kernel overlay driver can be used.  The image installs iptables so
  netavark can set up networks for build containers.  Run
  `tests/podman_build_test.sh` in
  `agents` to build the root [`Dockerfile`](Dockerfile) against
  `podman_builder` and check whether the build succeeds.
  Both socket volumes are mounted read-only into `agents`; this
  prevents changing socket files but does not restrict API commands.
  The builders set socket permissions to `0660` with group `builders`
  (GID 2375), and `agents` receives that supplemental group so access
  does not depend on its user's UID or primary GID.  Socket-based
  health checks gate startup of `agents`.  Run
  `tests/builder_socket_test.sh` inside `agents` to check API access
  and confirm that the former TCP endpoints are unavailable.
  The builders retain internet access for image pulls and builds.
  This isolates API access from ordinary peer containers, not from
  the host administrator.  Both builders remain privileged, and API
  access grants full control of their engines.  Rebuild the Dev
  Container to apply socket mounts, group membership, and listeners;
  existing engine data volumes can be retained.

---

## Agents

| Agent              | Standalone dir                       | Root `PROVIDER` | Entrypoint        | Docs                               |
|--------------------|--------------------------------------|-----------------|-------------------|------------------------------------|
| Aider              | [`aider/`](aider/)                   | `aider`         | `aider`           | [README](aider/README.md)          |
| Antigravity        | [`antigravity/`](antigravity/)       | `antigravity`   | `agy`             | [README](antigravity/README.md)    |
| Claude Code        | [`claude/`](claude/)                 | `claude`        | `claude`          | [README](claude/README.md)         |
| Cline              | [`cline/`](cline/)                   | `cline`         | `cline`           | [README](cline/README.md)          |
| Codex              | [`codex/`](codex/)                   | `codex`         | `codex`           | [README](codex/README.md)          |
| GitHub Copilot CLI | [`copilot/`](copilot/)               | `copilot`       | `copilot`         | [README](copilot/README.md)        |
| Crush              | [`crush/`](crush/)                   | `crush`         | `crush`           | [README](crush/README.md)          |
| Cursor Agent       | [`cursor/`](cursor/)                 | `cursor`        | `cursor-agent`    | [README](cursor/README.md)         |
| Droid (Factory)    | [`droid/`](droid/)                   | `droid`         | `droid`           | [README](droid/README.md)          |
| Gemini CLI         | [`gemini/`](gemini/)                 | `gemini`        | `gemini`          | [README](gemini/README.md)         |
| Grok Build         | [`grok/`](grok/)                     | `grok`          | `grok`            | [README](grok/README.md)           |
| Herdr              | [`herdr/`](herdr/)                   | `herdr`         | `herdr`           | [README](herdr/README.md)          |
| Hermes Agent       | [`hermes/`](hermes/)                 | `hermes`        | `hermes`          | [README](hermes/README.md)         |
| Kilo               | [`kilo/`](kilo/)                     | `kilo`          | `kilo`            | [README](kilo/README.md)           |
| Kiro CLI           | [`kiro/`](kiro/)                     | `kiro`          | `kiro-cli`        | [README](kiro/README.md)           |
| OpenClaw           | [`openclaw/`](openclaw/)             | `openclaw`      | `openclaw`        | [README](openclaw/README.md)       |
| OpenCode           | [`opencode/`](opencode/)             | `opencode`      | `opencode`        | [README](opencode/README.md)       |
| OpenWiki           | [`openwiki-agent/`](openwiki-agent/) | `openwiki`      | `openwiki`        | [README](openwiki-agent/README.md) |
| Pi coding agent    | [`pi/`](pi/)                         | `pi`            | `pi`              | [README](pi/README.md)             |
| All of the above   |                                      | `all` (default) | (each entrypoint) | This file                          |

## Shared conventions

All images (standalone and root) share the same runtime shape unless an
agent README says otherwise:

| Item                      | Default                                                                                     |
|---------------------------|---------------------------------------------------------------------------------------------|
| Base OS                   | `debian:trixie-slim`                                                                        |
| User                      | `user` (`CONTAINER_USER`)                                                                   |
| Working directory         | `/workspaces`                                                                               |
| Editors / tools           | `bubblewrap`, `git`, `ripgrep` (`rg`), `fd-find`, `vim`, `nano`, `emacs-nox`, `mg`, `micro` |
| Production vs development | `ENVIRONMENT=production` or `development`                                                   |
| Final env passthrough     | `EDITOR`, `GIT_EDITOR`, `TERM` (empty unless set at build/run)                              |

**Development** images (`ENVIRONMENT=development`) add `doas`,
`binutils`, `file`, and `tree`, and add the container user to the
`sudo` group.  The root multi-stage image also adds `docker-buildx`,
`docker-cli`, and `podman-remote`.  Their `doas` configuration
requires the container user's password; the account initially has no
usable password.

Optional build arg `NANO_CLASSIC_KEYBINDINGS=yes` writes classic nano
keybindings into the container user's `~/.nanorc`.

Codex images install `bubblewrap`, `ca-certificates`, and `curl`.  The
Codex executable is linked at `~/.local/bin/codex`, and the final image
adds that directory to its image-wide `PATH`.  It can therefore be run
directly as `codex` (substitute `user` if you set `CONTAINER_USER`).

---

## Build: standalone image

Build a single agent from its directory (recommended when you only need
one tool):

```bash
# From the agent directory
cd grok && docker build -t grok .

# From the repository root
docker build -t grok -f grok/Dockerfile grok
docker build -t claude -f claude/Dockerfile claude
docker build -t codex -f codex/Dockerfile codex
```

Version pins and agent-specific build args are documented in each [agent
README](#agents).

```bash
docker build -t copilot:stable -f copilot/Dockerfile \
  --build-arg COPILOT_VERSION=stable \
  copilot

docker build -t grok:dev -f grok/Dockerfile \
  --build-arg ENVIRONMENT=development \
  grok
```

---

## Build: root multi-stage Dockerfile

The top-level [`Dockerfile`](Dockerfile) defines intermediate stages for
every agent (and `all`), then selects the payload with `PROVIDER` and
the final flavour with `ENVIRONMENT`:

```text
PROVIDER stage  →  production (chown home)
                       ↓
               ENVIRONMENT=production | development
                       ↓
               USER + WORKDIR /workspaces
```

| `PROVIDER`                                  | Result                                                         |
|---------------------------------------------|----------------------------------------------------------------|
| `all` (default)                             | All agents from the `all` stage on one image                   |
| Stage name from the [agents table](#agents) | Single-agent intermediate stage (e.g. `claude`, `pi`, `droid`) |

```bash
# Everything (large image)
docker build -t agents:all .

# One agent via the monorepo graph
docker build -t agents:pi --build-arg PROVIDER=pi .
docker build -t agents:claude --build-arg PROVIDER=claude .
docker build -t agents:droid --build-arg PROVIDER=droid .

# Development variant
docker build -t agents:all-dev \
  --build-arg PROVIDER=all \
  --build-arg ENVIRONMENT=development \
  .
```

### Root build arguments

Declared at the top of the root `Dockerfile` (with current
defaults/comments):

| Argument                   | Default / notes                                                 |
|----------------------------|-----------------------------------------------------------------|
| `CONTAINER_USER`           | `user`                                                          |
| `ENVIRONMENT`              | `production` (`development` adds doas tooling)                  |
| `NANO_CLASSIC_KEYBINDINGS` | unset; set to `yes` for classic nano bindings                   |
| `PROVIDER`                 | `all`                                                           |
| `NODE_VERSION`             | `v24.20.0`; Node.js for all agents, including OpenWiki          |
| `NPM_VERSION`              | unset; npm version to upgrade/downgrade to                      |
| `AIDER_VERSION`            | `0.86.2`; `aider-chat` version installed with uv                |
| `CLAUDE_VERSION`           | `2.1.236`; Claude Code version installed (or `latest`/`stable`) |
| `CLINE_RELEASE`            | `3.0.60` (`nightly` or a version)                               |
| `CODEX_RELEASE`            | `0.148.0` (`latest` or a version)                               |
| `COPILOT_VERSION`          | `1.0.80` (`latest` or a version)                                |
| `CRUSH_VERSION`            | `v0.87.0` (release tag or `nightly`)                            |
| `DROID_VERSION`            | `0.209.0` (version of the `droid` npm package, or `latest`)     |
| `GEMINI_RELEASE`           | `0.55.1` (`latest`, `preview`, or `nightly`)                    |
| `GROK_CHANNEL`             | unset                                                           |
| `GROK_VERSION`             | `1.0.5`                                                         |
| `HERMES_VERSION`           | `v2026.9.24` (Specific Hermes git tag to install)               |
| `HERDR_VERSION`            | `0.8.2`                                                         |
| `KILO_VERSION`             | `7.4.23`                                                        |
| `KIRO_CHANNEL`             | unset                                                           |
| `KIRO_FORCE`               | unset; non-empty passes `--force`                               |
| `OPENCLAW_VERSION`         | `2026.6.34` (`latest` or a version)                             |
| `OPENCODE_VERSION`         | `1.18.21`                                                       |
| `OPENWIKI_VERSION`         | `0.5.0` (`latest` or a version)                                 |
| `PI_VERSION`               | `0.84.4` (`latest` or a version)                                |

Note for npm: When `NPM_VERSION` is set, the npm will be upgraded or
downgraded to the specified version.  Otherwise the npm bundled with
Node.js is kept.

Prefer **standalone** Dockerfiles for a minimal build context and docs
next to one install path.  Prefer the **root** Dockerfile for one image
with many agents on `PATH`, or when iterating on the shared multi-stage
graph.

### What `PROVIDER=all` installs

The `all` stage copies builders into `/usr/local/bin` (or home trees)
and adds symlinks for Node-based CLIs and tools that live under home:

`aider`, `agy`, `claude`, `cline`, `codex`, `copilot`, `crush`,
`cursor-agent`, `droid`, `gemini`, `grok`, `herdr`, `hermes`, `kilo`,
`kiro-cli`, `openclaw`, `opencode`, `openwiki`, `pi`, plus Node/npm on
`PATH`.

It also appends `$HOME/.local/bin` to the container user's `.bashrc`.

Aider is installed with [uv](https://docs.astral.sh/uv/)
(`uv tool install --force --python python3.12 --with pip aider-chat@${AIDER_VERSION}`).

Default `AIDER_VERSION` is `0.86.2` for both the root `aider` / `all`
stages and the standalone `aider/` image.  The `uv` CLI is used only
during the build; the runtime image keeps the UV tools tree under
`~/.local/share/uv` and a `/usr/local/bin/aider` symlink.

---

## Build: build.sh helper

[`build.sh`](build.sh) builds and tags production and development
images based on the current git branch, commit, and working tree state:
a modified tree builds `wip`/`dev-wip` (prefixed with the branch name
on non-master branches), while a clean tree builds `latest`/`dev` or a
git tag such as `20260904`/`dev-20260904`.  It uses podman when
available and docker otherwise.

```bash
# Build and tag the root images (default)
./build.sh

# Build and tag standalone images
./build.sh grok pi openwiki

# Build everything, continuing past failures
./build.sh -k -a

# Show help
./build.sh -h

# Run the built-in self-test
./build.sh --test
```

Providers:

- (no argument) or `root` - the root Dockerfile only (image: `agents`)
- `<directory name>` - standalone build for that provider (image:
  `<directory name>`), e.g. `grok`.  OpenWiki is `openwiki` (directory
  `openwiki-agent`).

Options:

- `-h`, `-H`, `--help` - show the help message and exit.
- `-k`, `--keep-going` - keep building even when a build fails.
  Without it, the first failure stops the build.
- `-a`, `--all` - build the root Dockerfile and all standalone
  providers.
- `--test` - run the built-in self-test (no other arguments).

Environment:

- `DOCKER` - container engine to use (default: podman if available,
  otherwise docker).

---

## Run

Generic pattern (replace image name and command):

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e TERM \
  <image> <agent-command>
```

Examples:

```bash
docker run --rm -it -v "$PWD:/workspaces/project" \
    -w /workspaces/project -e XAI_API_KEY grok grok
docker run --rm -it -v "$PWD:/workspaces/project" \
    -w /workspaces/project -e ANTHROPIC_API_KEY claude claude
docker run --rm -it -v "$PWD:/workspaces/project" \
    -w /workspaces/project -e OPENAI_API_KEY codex codex
```

Auth is tool-specific (API keys, device login, GitHub tokens, and so
on).  See each agent README for environment variables and login flows.

### Development image privileges

Development images require the container user's password for `doas`.
Set or replace that password interactively after the container starts.
For the Dev Container Compose configuration, run this command from the
host:

```bash
docker compose \
  -f docker-compose.yml \
  -f .devcontainer/docker-compose.devcontainer.yml \
  exec --user root agents passwd devcontainer
```

For a container started directly from the root development image, use
`docker exec` instead.  The default container user is `user`:

```bash
docker run -d --name agents-dev agents:all-dev "sleep infinity"
docker exec -it --user root agents-dev passwd user
```

The `passwd` command reads the new password from the terminal without
placing it in the image, container environment, or shell command line.
The password remains across container restarts, but it is lost when the
container is removed and recreated.  Test authenticated escalation from
inside the container with `doas id`.

---

## Persistence

Containers are ephemeral.  Config, credentials, and sessions under the
container home (and some tool-specific trees) disappear unless you mount
storage.

The repository ignores Aider files matching `.aider.*` and contents of
Hermes' `.hermes/` and Droid's `.factory/` directories.  These rules
keep local agent state out of git; they do not persist container state
or protect files already tracked by git.

Common patterns:

- Mount only mutable state (auth, config, sessions) and leave install
  assets in the image.
- Mount a full tool home (e.g. `~/.kilo`) only when the host tree is a
  complete install—or seed it from the image first.  For Grok, prepare
  a host directory with dangling `bin`, `completions`, `docs`, and
  `downloads` symlinks and bind-mount it on `~/.grok`; see
  [grok/README.md](grok/README.md).
- Use a named volume seeded once from the image for full home
  persistence.

**Caution:** Bind-mounting an empty or partial host directory over a
path that also holds the tool's install (binary, docs, bundled skills)
will hide the image contents and can break the CLI.

Session stores are often keyed by the
**container working directory**.  Use a stable `-w` path (this repo
defaults to `/workspaces`) so resumes work
across runs.

Detailed mount recipes for tools that install into a home directory
(especially Grok and Kilo) are in those agents' READMEs.

---

## Repository layout

```text
.
├── Dockerfile                      # Multi-stage: all agents + PROVIDER
├── LICENSE.txt                     # 2-Clause BSD
├── README.md                       # This file
├── .agents/                        # Instructions to the coding agents
├── .devcontainer/                  # VS Code Dev Container configuration
│   ├── devcontainer.json
│   ├── docker-compose.devcontainer.yml
│   ├── docker_builder.Dockerfile   # Docker daemon for build tests
│   └── podman_builder.Dockerfile   # Podman service for build tests
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .markdownlint.json
├── build.sh                        # Build + tag the agents images
├── tests/
│   ├── docker_build_test.sh        # Build root Dockerfile via docker_builder
│   └── podman_build_test.sh        # Build root Dockerfile via podman_builder
├── aider/                          # Standalone Dockerfile + README
├── antigravity/
├── claude/
├── cline/
├── codex/
├── copilot/
├── crush/
├── cursor/
├── droid/
├── gemini/
├── grok/
├── herdr/
├── hermes/
├── kilo/
├── kiro/
├── openclaw/
├── opencode/
├── openwiki-agent/
└── pi/
```

Each standalone directory contains:

- `Dockerfile` - self-contained build for that agent
- `README.md` - build args, run examples, image layout, persistence

---

## License

This project's Dockerfiles, documentation, and other repository content
are licensed under the _2-Clause BSD License_.  See
[`LICENSE.txt`](LICENSE.txt) for the full text.

### Third-party agents

This repository only packages installers and public CLIs.  Each agent
binary, npm package, or tool you install through these images is subject
to its own license and terms of use.  Obtain API keys and accounts from
the respective providers.

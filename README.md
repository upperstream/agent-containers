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

**Development** images (`ENVIRONMENT=development`) add `doas`
(passwordless for group `sudo`), `binutils`, `file`, and `tree`, and add
the container user to the `sudo` group.

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
| `NODE_VERSION`             | `v24.20.0`                                                      |
| `NPM_VERSION`              | `12.0.0`                                                        |
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
| `HERMES_VERSION`           | `v2026.8.13` (Specific Hermes git tag to install)               |
| `KILO_VERSION`             | `7.4.23`                                                        |
| `KIRO_CHANNEL`             | unset                                                           |
| `KIRO_FORCE`               | unset; non-empty passes `--force`                               |
| `OPENCLAW_VERSION`         | `2026.6.34` (`latest` or a version)                             |
| `OPENCODE_VERSION`         | `1.18.21`                                                       |
| `OPENWIKI_NODE_VERSION`    | `v24.18.1`; Node.js version to install for OpenWiki             |
| `PI_VERSION`               | `0.84.4` (`latest` or a version)                                |

Also used by named stages (pass with `--build-arg`; declared on those
stages, not only at file top):

| Argument           | Used by    |
|--------------------|------------|
| `OPENWIKI_VERSION` | `openwiki` |

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

Aider is installed with [uv](https://docs.astral.sh/uv/) (`uv tool
install --force --python python3.12 --with pip
aider-chat@${AIDER_VERSION}`).  Default `AIDER_VERSION` is `0.86.2` for
both the root `aider` / `all` stages and the standalone `aider/` image.
The `uv` CLI is used only during the build; the runtime image keeps the
UV tools tree under `~/.local/share/uv` and a `/usr/local/bin/aider`
symlink.

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

---

## Persistence

Containers are ephemeral.  Config, credentials, and sessions under the
container home (and some tool-specific trees) disappear unless you mount
storage.

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
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .markdownlint.json
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

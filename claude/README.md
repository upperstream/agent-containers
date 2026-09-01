# Claude Code container

Debian-based image with [Claude Code](https://claude.ai/) CLI
preinstalled, plus common editor and search tools (`git`, `ripgrep`,
`fd`, `vim`, `nano`, etc.).

Claude Code is installed with the official one-liner install script
(`curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_VERSION}"`).
Default `CLAUDE_VERSION` is `2.1.236`; override at build time to pin a
different version, or set it to `latest` or `stable` to track a release
channel instead.

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t claude .
```

From the repository root:

```bash
docker build -t claude -f claude/Dockerfile claude
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CLAUDE_VERSION`           | `2.1.236`    | Claude Code version to install (or `latest`/`stable`)    |
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t claude:dev --build-arg ENVIRONMENT=development .
docker build -t claude:latest .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e ANTHROPIC_API_KEY \
  claude claude
```

Authenticate with `ANTHROPIC_API_KEY` or the CLI’s login flow.
Credentials and settings typically land under the user’s home (commonly
`~/.claude`).

---

## Image layout

| Path                    | Description               |
|-------------------------|---------------------------|
| `/usr/local/bin/claude` | Claude Code CLI binary    |
| `/workspaces`           | Default working directory |

### Persistence

Ephemeral containers lose home-directory state.  Mount Claude config and
related paths if you want login and settings to survive:

```bash
docker run --rm -it \
  -v "$HOME/.claude:/home/user/.claude" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e ANTHROPIC_API_KEY \
  claude claude
```

Also consider mounting project-level `.claude/` settings with the
workspace volume (already included when you bind the project root).

---

## Related

The monorepo root `Dockerfile` can also include Claude via multi-stage
targets (`PROVIDER=claude` or `all`).  This directory is a standalone
build so you can image Claude without the multi-agent graph.

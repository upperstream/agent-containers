# OpenCode container

Debian-based image with [OpenCode](https://opencode.ai/) CLI
preinstalled, plus common editor and search tools (`git`, `ripgrep`,
`fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t opencode .
```

From the repository root:

```bash
docker build -t opencode -f opencode/Dockerfile opencode
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |
| `OPENCODE_VERSION`         | `1.18.34`    | OpenCode version to install                              |

Examples:

```bash
docker build -t opencode:dev --build-arg ENVIRONMENT=development .
docker build -t opencode:1.18.34 --build-arg OPENCODE_VERSION=1.18.34 .
```

The installer is invoked with `--no-modify-path`; the binary is copied
to `/usr/local/bin/opencode`.  The builder does not strip the
executable, so the Bun-compiled payload at the tail of the binary is
preserved.

See the root [README](../README.md#development-image-privileges) for
development-image privilege setup.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  opencode opencode
```

Authenticate according to OpenCode’s documentation for your environment.

---

## Image layout

| Path                      | Description               |
|---------------------------|---------------------------|
| `/usr/local/bin/opencode` | OpenCode CLI binary       |
| `/workspaces`             | Default working directory |

### Persistence

The image only copies the binary into `/usr/local/bin`.  Retain the
OpenCode share and state directories, plus its configuration directory,
if you need them beyond the container lifespan.  The provided Docker
Compose configuration expects `$HOME/opencode_home` to contain
`share/opencode` and `state/opencode`, and retains configuration in
`$HOME/.config/opencode`:

```bash
docker run --rm -it \
  -v "$HOME/.config/opencode:/home/user/.config/opencode" \
  -v "$HOME/opencode_home/share/opencode:/home/user/.local/share/opencode" \
  -v "$HOME/opencode_home/state/opencode:/home/user/.local/state/opencode" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  opencode opencode
```

Notice: If you mount a host directory that is meant to hold a full
OpenCode install tree over a path that also contains install assets in
some setups, ensure the host tree is complete--or keep the image binary
in `/usr/local/bin` and only mount mutable config/session data.

---

## Related

The monorepo root `Dockerfile` can also include OpenCode via multi-stage
targets.  This directory is a *standalone* build so you can image
OpenCode without the multi-agent graph.

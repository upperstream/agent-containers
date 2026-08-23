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

| Argument                   | Default               | Description                                              |
|----------------------------|-----------------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`                | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production`          | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)               | Set to `yes` for classic nano keybindings                |
| `OPENCODE_VERSION`         | (installer default)   | Pin version, e.g. `1.17.13`                              |

Examples:

```bash
docker build -t opencode:dev --build-arg ENVIRONMENT=development .
docker build -t opencode:1.17.13 --build-arg OPENCODE_VERSION=1.17.13 .
```

The installer is invoked with `--no-modify-path`; the binary is copied
to `/usr/local/bin/opencode`.  The builder does not strip the
executable, so the Bun-compiled payload at the tail of the binary is
preserved.

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

| Path                      | Description                    |
|---------------------------|--------------------------------|
| `/usr/local/bin/opencode` | OpenCode CLI binary            |
| `/workspaces`             | Default working directory      |

### Persistence

The image only copies the binary into `/usr/local/bin`.  Runtime config
and sessions may still be written under the container user’s home (for
example `~/.opencode` or paths documented by your version).  Mount those
paths if you need state across runs:

```bash
docker run --rm -it \
  -v "$HOME/.opencode:/home/user/.opencode" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  opencode opencode
```

**Notice:** If you mount a host directory that is meant to hold a full
OpenCode install tree over a path that also contains install assets in
some setups, ensure the host tree is complete—or keep the image binary
in `/usr/local/bin` and only mount mutable config/session data.

---

## Related

The monorepo root `Dockerfile` can also include OpenCode via multi-stage
targets.  This directory is a **standalone** build so you can image
OpenCode without the multi-agent graph.

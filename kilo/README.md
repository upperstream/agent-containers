# Kilo container

Debian-based image with [Kilo](https://kilo.ai/) CLI preinstalled under
`/home/user/.kilo`, plus common editor and search tools (`git`,
`ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t kilo .
```

From the repository root:

```bash
docker build -t kilo -f kilo/Dockerfile kilo
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `KILO_VERSION`             | `7.4.23`     | Kilo version to install                                  |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t kilo:dev --build-arg ENVIRONMENT=development .
docker build -t kilo:7.4.23 --build-arg KILO_VERSION=7.4.23 .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  kilo kilo
```

Authenticate according to Kilo’s documentation for your environment.

---

## Image layout

| Path                  | Description                                        |
|-----------------------|----------------------------------------------------|
| `/home/user/.kilo`    | Full Kilo install tree from the official installer |
| `/usr/local/bin/kilo` | Symlink to `/home/user/.kilo/bin/kilo`             |
| `/workspaces`         | Default working directory                          |

### Persistence

The image keeps Kilo's install under `/home/user/.kilo` and links its
mutable XDG directories to `/mnt/kilo`:

| Container path                       | Mounted host subdirectory   |
|--------------------------------------|-----------------------------|
| `~/.local/share/kilo`                | `share/kilo`                |
| `~/.local/state/kilo`                | `state/kilo`                |
| `~/.local/state/kilo-sandbox-policy` | `state/kilo-sandbox-policy` |

To retain Kilo user data, sessions, and sandbox-policy state after the
container is removed, create this layout on the host and bind-mount its
parent directory at `/mnt/kilo`:

```bash
mkdir -p "$HOME/kilo/share/kilo" \
  "$HOME/kilo/state/kilo" \
  "$HOME/kilo/state/kilo-sandbox-policy"

docker run --rm -it \
  -v "$HOME/kilo:/mnt/kilo" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  kilo kilo
```

Do not mount a host directory over `/home/user/.kilo`, as that replaces
the Kilo installation bundled in the image.

---

## Related

The monorepo root `Dockerfile` can also include Kilo via multi-stage
targets.  This directory is a standalone build so you can image Kilo
without the multi-agent graph.

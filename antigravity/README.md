# Antigravity (agy) container

Debian-based image with Google’s [Antigravity
CLI](https://antigravity.google/) (`agy`) preinstalled, plus common
editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t antigravity .
```

From the repository root:

```bash
docker build -t antigravity -f antigravity/Dockerfile antigravity
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t antigravity:dev --build-arg ENVIRONMENT=development .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  antigravity agy
```

Authenticate according to the Antigravity CLI documentation for your
environment.

---

## Image layout

| Path                 | Description               |
|----------------------|---------------------------|
| `/usr/local/bin/agy` | Antigravity CLI binary    |
| `/workspaces`        | Default working directory |

### Persistence

Mount any home-directory config or credential paths the CLI creates if
you need them across container runs (for example under
`/home/user/.config` or a tool-specific directory).  Prefer the
locations documented by the Antigravity installer for your version.

---

## Related

The monorepo root `Dockerfile` can also include Antigravity via
multi-stage targets.  This directory is a standalone build so you can
image `agy` without the multi-agent graph.

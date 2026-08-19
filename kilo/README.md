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

| Argument                   | Default             | Description                                              |
|----------------------------|---------------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`              | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production`        | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)             | Set to `yes` for classic nano keybindings                |
| `KILO_VERSION`             | (installer default) | Pin version, e.g. `7.4.1`                                |

Examples:

```bash
docker build -t kilo:dev --build-arg ENVIRONMENT=development .
docker build -t kilo:7.4.1 --build-arg KILO_VERSION=7.4.1 .
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

Kilo’s install and runtime data both live under `~/.kilo`.  Binding a
host directory over `/home/user/.kilo` **replaces** the image install.

**Notice:** Do not mount an empty or partial host `~/.kilo` over the
container path, or you may lose the binary and install assets.

Options:

1. **Full home mount** — only if the host tree is a complete install
   (seed from the image if needed).
2. **Selective mounts** — leave install assets in the image; mount only
   mutable subpaths the tool documents (config, sessions, auth).
3. **Named volume** — seed once from the image, then reattach the volume
   for full persistence.

```bash
# Seed a named volume from the image
docker run --rm -v kilo-home:/data kilo \
  sh -c 'cp -a /home/user/.kilo/. /data/'

docker run --rm -it \
  -v kilo-home:/home/user/.kilo \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  kilo kilo
```

---

## Related

The monorepo root `Dockerfile` can also include Kilo via multi-stage
targets.  This directory is a **standalone** build so you can image Kilo
without the multi-agent graph.

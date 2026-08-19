# Herdr container

Debian-based image with [Herdr](https://herdr.dev/) CLI preinstalled,
plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`,
`nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t herdr .
```

From the repository root:

```bash
docker build -t herdr -f herdr/Dockerfile herdr
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t herdr:dev --build-arg ENVIRONMENT=development .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  herdr herdr
```

Authenticate according to Herdr’s documentation for your environment.

---

## Image layout

| Path                   | Description                 |
|------------------------|-----------------------------|
| `/usr/local/bin/herdr` | Herdr CLI binary (stripped) |
| `/workspaces`          | Default working directory   |

### Persistence

Mount home-directory config or credential paths Herdr creates if you
need them across container runs.  Prefer the locations documented for
your Herdr release.

---

## Related

The monorepo root `Dockerfile` can also include Herdr via
multi-stage targets.  This directory is a **standalone** build so you
can image Herdr without the multi-agent graph.

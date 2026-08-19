# Droid (Factory) container

Debian-based image with [Factory Droid](https://app.factory.ai/) CLI
(`droid`) preinstalled, plus common editor and search tools (`git`,
`ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t droid .
```

From the repository root:

```bash
docker build -t droid -f droid/Dockerfile droid
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t droid:dev --build-arg ENVIRONMENT=development .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  droid droid
```

Authenticate according to Factory / Droid documentation for your
environment.

---

## Image layout

| Path                   | Description                 |
|------------------------|-----------------------------|
| `/usr/local/bin/droid` | Droid CLI binary (stripped) |
| `/workspaces`          | Default working directory   |

### Persistence

Mount home-directory config or credential paths Droid creates if you
need them across container runs.  Prefer the locations documented for
your Droid release.

---

## Related

The monorepo root `Dockerfile` can also include Droid via multi-stage
targets (`PROVIDER=droid` or `PROVIDER=all`).  This directory is a
standalone build so you can image Droid without the multi-agent graph.

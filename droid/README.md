# Droid (Factory) container

Debian-based image with [Factory Droid](https://app.factory.ai/) CLI
(`droid`) preinstalled on a bundled Node.js runtime, plus common
editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

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
| `NODE_VERSION`             | `v24.18.1`   | Node.js version to install                               |
| `NPM_VERSION`              | `12.0.0`     | Global npm version                                       |
| `DROID_VERSION`            | `0.209.0`    | `latest` or a version of the `droid` npm package         |

Examples:

```bash
docker build -t droid:dev --build-arg ENVIRONMENT=development .
docker build -t droid:pinned --build-arg DROID_VERSION=0.200.0 .
```

The package is installed with `npm install -g --ignore-scripts`.

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

| Path                                               | Description                           |
|----------------------------------------------------|---------------------------------------|
| `/usr/local/node-<version>/`                       | Bundled Node.js runtime               |
| `/usr/local/node-<version>/lib/node_modules/droid` | `droid` launcher shim package         |
| `/usr/local/bin/droid`                             | Symlink to `droid/bin/droid` launcher |
| `/usr/local/bin/*`                                 | Node/npm binaries                     |
| `/workspaces`                                      | Default working directory             |

### Persistence

Mount home-directory config or credential paths Droid creates if you
need them across container runs.  Prefer the locations documented for
your Droid release.

---

## Related

The monorepo root `Dockerfile` can also include Droid via multi-stage
targets (`PROVIDER=droid` or `PROVIDER=all`).  This directory is a
standalone build so you can image Droid without the multi-agent graph.

# Cline container

Debian-based image with [Cline](https://cline.bot/) CLI preinstalled (Node.js + npm package), plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t cline .
```

From the repository root:

```bash
docker build -t cline -f cline/Dockerfile cline
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                |
| `NODE_VERSION`             | `v24.18.0`   | Node.js version to install                               |
| `NPM_VERSION`              | `12.0.0`     | Global npm version                                       |
| `CLINE_RELEASE`            | *(latest)*   | Pin Cline: e.g. `nightly` or `3.0.37`                    |

Examples:

```bash
docker build -t cline:dev --build-arg ENVIRONMENT=development .
docker build -t cline:3.0.37 --build-arg CLINE_RELEASE=3.0.37 .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  cline cline
```

Authenticate according to Cline’s documentation (API keys or provider login as required).

---

## Image layout

| Path                                               | Description               |
|----------------------------------------------------|---------------------------|
| `/usr/local/node-<version>/`                       | Bundled Node.js runtime   |
| `/usr/local/node-<version>/lib/node_modules/cline` | Cline npm package         |
| `/usr/local/bin/cline`                             | Symlink to the Cline CLI  |
| `/usr/local/bin/*`                                 | Node/npm binaries         |
| `/workspaces`                                      | Default working directory |

### Persistence

Mount home-directory config or credential paths Cline creates if you need them across runs. Prefer the locations documented for your Cline release.

---

## Related

The monorepo root `Dockerfile` can also include Cline via multi-stage targets. This directory is a **standalone** build so you can image Cline without the multi-agent graph.

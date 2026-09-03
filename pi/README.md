# Pi coding agent container

Debian-based image with
[@earendil-works/pi-coding-agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
(`pi`) preinstalled on a bundled Node.js runtime, plus common editor and
search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t pi .
```

From the repository root:

```bash
docker build -t pi -f pi/Dockerfile pi
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |
| `NODE_VERSION`             | `v24.20.0`   | Node.js version to install                               |
| `NPM_VERSION`              | `12.0.0`     | Global npm version                                       |
| `PI_VERSION`               | `0.84.4`     | npm version of `@earendil-works/pi-coding-agent`         |

Examples:

```bash
docker build -t pi:dev --build-arg ENVIRONMENT=development .
docker build -t pi:pinned --build-arg PI_VERSION=1.0.0 .
```

The package is installed with `npm install -g --ignore-scripts`.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  pi pi
```

Configure API keys and providers according to Pi’s documentation for
your version.

---

## Image layout

| Path                                                                         | Description               |
|------------------------------------------------------------------------------|---------------------------|
| `/usr/local/node-<version>/`                                                 | Bundled Node.js runtime   |
| `/usr/local/node-<version>/lib/node_modules/@earendil-works/pi-coding-agent` | Pi package                |
| `/usr/local/bin/pi`                                                          | Symlink to `dist/cli.js`  |
| `/usr/local/bin/*`                                                           | Node/npm binaries         |
| `/workspaces`                                                                | Default working directory |

`fd-find` and `ripgrep` are ensured in the production stage in addition
to the shared editor toolkit.

### Persistence

Mount home-directory config or credential paths Pi creates if you need
them across container runs.  Prefer the locations documented for your Pi
release.

---

## Related

The monorepo root `Dockerfile` can also include Pi via multi-stage
targets (`PROVIDER=pi` or `all`).  This directory is a **standalone**
build so you can image Pi without the multi-agent graph.

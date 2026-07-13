# OpenWiki container

Debian-based image with [OpenWiki](https://www.npmjs.com/package/openwiki) preinstalled on a bundled Node.js runtime, plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t openwiki .
```

From the repository root:

```bash
docker build -t openwiki -f openwiki-agent/Dockerfile openwiki-agent
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                |
| `NODE_VERSION`             | `v24.18.0`   | Node.js version to install                               |
| `NPM_VERSION`              | `12.0.0`     | Global npm version                                       |
| `OPENWIKI_VERSION`         | `latest`     | npm version tag or version number                        |

Examples:

```bash
docker build -t openwiki:dev --build-arg ENVIRONMENT=development .
docker build -t openwiki:pinned --build-arg OPENWIKI_VERSION=1.0.0 .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  openwiki openwiki
```

Configure OpenWiki according to its documentation for your version.

---

## Image layout

| Path                                                  | Description               |
|-------------------------------------------------------|---------------------------|
| `/usr/local/node-<version>/`                          | Bundled Node.js runtime   |
| `/usr/local/node-<version>/lib/node_modules/openwiki` | OpenWiki npm package      |
| `/usr/local/bin/openwiki`                             | Symlink to `dist/cli.js`  |
| `/usr/local/bin/*`                                    | Node/npm binaries         |
| `/workspaces`                                         | Default working directory |

### Persistence

Mount home-directory or project data paths OpenWiki uses if you need generated content or config across container runs. Prefer the locations documented for your OpenWiki release.

---

## Related

The monorepo root `Dockerfile` can also include OpenWiki via multi-stage targets. This directory is a **standalone** build so you can image OpenWiki without the multi-agent graph.

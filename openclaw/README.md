# OpenClaw container

Debian-based image with
[OpenClaw](https://www.npmjs.com/package/openclaw) preinstalled on a
bundled Node.js runtime, plus common editor and search tools (`git`,
`ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t openclaw .
```

From the repository root:

```bash
docker build -t openclaw -f openclaw/Dockerfile openclaw
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |
| `NODE_VERSION`             | `v24.20.0`   | Node.js version to install                               |
| `NPM_VERSION`              | (unset)      | npm version to upgrade/downgrade to                      |
| `OPENCLAW_VERSION`         | `2026.6.34`  | npm version tag, e.g. `latest` or `2026.6.34`            |

Note for npm: When `NPM_VERSION` is set, the npm will be upgraded or
downgraded to the specified version.  Otherwise the npm bundled with
Node.js is kept.

Examples:

```bash
docker build -t openclaw:dev --build-arg ENVIRONMENT=development .
docker build -t openclaw:2026.6.34 \
    --build-arg OPENCLAW_VERSION=2026.6.34 .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  openclaw openclaw
```

Configure auth and providers according to OpenClaw’s documentation for
your version.

---

## Image layout

| Path                                                  | Description               |
|-------------------------------------------------------|---------------------------|
| `/usr/local/node-<version>/`                          | Bundled Node.js runtime   |
| `/usr/local/node-<version>/lib/node_modules/openclaw` | OpenClaw npm package      |
| `/usr/local/bin/openclaw`                             | Symlink to `openclaw.mjs` |
| `/usr/local/bin/*`                                    | Node/npm binaries         |
| `/workspaces`                                         | Default working directory |

### Persistence

Mount home-directory config or credential paths OpenClaw creates if you
need them across container runs.  Prefer the locations documented for
your release.

---

## Related

The monorepo root `Dockerfile` can also include OpenClaw via multi-stage
targets.  This directory is a **standalone** build (Node + package +
symlink, no duplicate `useradd`) so you can image OpenClaw without the
multi-agent graph.

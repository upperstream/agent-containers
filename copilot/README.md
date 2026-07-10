# GitHub Copilot CLI container

Debian-based image with [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/use-copilot-extensions/use-copilot-cli) preinstalled, plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t copilot .
```

From the repository root:

```bash
docker build -t copilot -f copilot/Dockerfile copilot
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                |
| `COPILOT_VERSION`          | `latest`     | Pin version: `latest`, `prerelease`, or e.g. `v0.0.369`  |

Examples:

```bash
docker build -t copilot:dev --build-arg ENVIRONMENT=development .
docker build -t copilot:prerelease --build-arg COPILOT_VERSION=prerelease .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  copilot copilot
```

Authenticate with GitHub (device flow or token) as required by the Copilot CLI. You may need to pass a `GH_TOKEN` or mount GitHub credential helpers depending on your setup.

---

## Image layout

| Path                     | Description               |
|--------------------------|---------------------------|
| `/usr/local/bin/copilot` | Copilot CLI binary        |
| `/workspaces`            | Default working directory |

### Persistence

Mount home config/credential directories the CLI uses so login state survives container restarts. Prefer paths documented for your Copilot CLI version (often under `~/.config` or GitHub CLI auth stores).

---

## Related

The monorepo root `Dockerfile` can also include Copilot via multi-stage targets. This directory is a **standalone** build so you can image Copilot without the multi-agent graph.

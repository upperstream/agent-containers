# Cursor Agent container

Debian-based image with [Cursor Agent](https://cursor.com/) CLI
(`cursor-agent`) preinstalled, plus common editor and search tools
(`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t cursor .
```

From the repository root:

```bash
docker build -t cursor -f cursor/Dockerfile cursor
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t cursor:dev --build-arg ENVIRONMENT=development .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  cursor cursor-agent
```

Authenticate according to Cursor Agent documentation for your
environment.

---

## Image layout

| Path                                             | Description                                  |
|--------------------------------------------------|----------------------------------------------|
| `/home/user/.local/share/cursor-agent/versions/` | Installed agent version tree                 |
| `/usr/local/bin/cursor-agent`                    | Symlink into the installed version directory |
| `/workspaces`                                    | Default working directory                    |

### Persistence

Notice: The agent binary tree lives under
`/home/user/.local/share/cursor-agent/`.  If you bind-mount that path
from the host, ensure the host tree contains a valid install (or seed it
from the image).  Otherwise prefer leaving install assets in the image
and only mounting config/auth directories the agent documents.

```bash
# Example: keep host config separate from image install
docker run --rm -it \
  -v "$HOME/.cursor:/home/user/.cursor" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  cursor cursor-agent
```

Adjust mount paths to match the locations your Cursor Agent version
actually uses.

---

## Related

The monorepo root `Dockerfile` can also include Cursor Agent via
multi-stage targets.  This directory is a standalone build so you can
image `cursor-agent` without the multi-agent graph.

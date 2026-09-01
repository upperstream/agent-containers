# Aider container

Debian-based image with [Aider](https://aider.chat/) preinstalled, plus
common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`,
etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t aider .
```

From the repository root:

```bash
docker build -t aider -f aider/Dockerfile aider
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `AIDER_VERSION`            | `0.86.2`     | `aider-chat` version installed with uv                   |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                |

Examples:

```bash
docker build -t aider:dev --build-arg ENVIRONMENT=development .
docker build -t aider:0.86.2 --build-arg AIDER_VERSION=0.86.2 .
```

The builder installs [uv](https://docs.astral.sh/uv/) from Astral, then
runs `uv tool install --force --python python3.12 --with pip
aider-chat@${AIDER_VERSION}`.  The final image copies that UV tools tree
and symlinks `aider` to `/usr/local/bin/aider`.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  -e ANTHROPIC_API_KEY \
  aider aider
```

Pass the API keys your model provider requires.  See [Aider
docs](https://aider.chat/docs/) for model selection and auth options.

---

## Image layout

| Path                                              | Description                                         |
|---------------------------------------------------|-----------------------------------------------------|
| `/home/user/.local/share/uv`                      | UV tools tree (Aider + Python 3.12 environment)     |
| `/home/user/.local/share/uv/tools/aider-chat/bin` | Aider binary and its tool environment               |
| `/usr/local/bin/aider`                            | Symlink to the Aider binary under the UV tools tree |
| `/workspaces`                                     | Default working directory                           |

The `uv` CLI itself is used only during the build and is not copied
into the runtime image.

### Persistence

Ephemeral containers lose home-directory state.  Mount host paths if you
want history, config, or caches to survive:

```bash
docker run --rm -it \
  -v "$HOME/.aider:/home/user/.aider" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  aider aider
```

Exact config locations depend on your Aider version; prefer mounting the
paths Aider documents for your release.

---

## Related

The monorepo root `Dockerfile` can also include Aider via multi-stage
targets (`PROVIDER=aider` or `all`).  This directory is a standalone
build so you can image Aider without the multi-agent graph.

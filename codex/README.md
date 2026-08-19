# Codex container

Debian-based image with OpenAI [Codex CLI](https://chatgpt.com/codex)
preinstalled, plus common editor and search tools (`git`, `ripgrep`,
`fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t codex .
```

From the repository root:

```bash
docker build -t codex -f codex/Dockerfile codex
```

### Build arguments

| Argument                   | Default             | Description                                              |
|----------------------------|---------------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`              | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production`        | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)             | Set to `yes` for classic nano keybindings                |
| `CODEX_RELEASE`            | (installer default) | Pin release, e.g. `latest` or `0.142.5`                  |

Examples:

```bash
docker build -t codex:dev --build-arg ENVIRONMENT=development .
docker build -t codex:0.142.5 --build-arg CODEX_RELEASE=0.142.5 .
```

The installer is run with `CODEX_NON_INTERACTIVE=1`.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  codex /home/user/.local/bin/codex
```

Authenticate with `OPENAI_API_KEY` or the CLI’s login flow.  Config and
session data often live under `~/.codex`.

---

## Image layout

| Path                          | Description                 |
|-------------------------------|-----------------------------|
| `/home/user/.codex`           | Codex installation and data |
| `/home/user/.local/bin/codex` | Symlink to the Codex CLI    |
| `/workspaces`                 | Default working directory   |

### Persistence

The Codex installation and its user data, including configuration and
session information, live in `/home/user/.codex` inside the container.
Before mounting that path, copy its initial contents out of the image.
An empty bind mount would hide the installed files and leave the Codex
symlink unusable.

```bash
docker create --name codex-extract codex
docker cp codex-extract:/home/user/.codex ./.codex
docker rm codex-extract
```

Then mount the extracted directory when starting Codex:

```bash
docker run --rm -it \
  -v "$PWD/.codex:/home/user/.codex" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  codex /home/user/.local/bin/codex
```

The host-side `.codex` directory then retains the data when the
container is removed and makes it available to later containers started
with the same mount.  Add `.codex/` to the project's `.gitignore`; it
can contain credentials and private session data and should not be
committed.

If the image was built with a different `CONTAINER_USER`, replace `user`
in `/home/user/.codex` with that user's name.  Mount additional paths if
your Codex version documents other state locations.

---

## Related

The monorepo root `Dockerfile` can also include Codex via multi-stage
targets.  This directory is a standalone build so you can image Codex
without the multi-agent graph.

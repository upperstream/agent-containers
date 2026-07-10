# Codex container

Debian-based image with OpenAI [Codex CLI](https://chatgpt.com/codex) preinstalled, plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

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

| Argument                   | Default               | Description                                              |
|----------------------------|-----------------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`                | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production`          | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*             | Set to `yes` for classic nano keybindings                |
| `CODEX_RELEASE`            | *(installer default)* | Pin release, e.g. `latest` or `0.142.5`                  |

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
  codex codex
```

Authenticate with `OPENAI_API_KEY` or the CLI’s login flow. Config and session data often live under `~/.codex`.

---

## Image layout

| Path                   | Description               |
|------------------------|---------------------------|
| `/usr/local/bin/codex` | Codex CLI binary          |
| `/workspaces`          | Default working directory |

### Persistence

```bash
docker run --rm -it \
  -v "$HOME/.codex:/home/user/.codex" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  codex codex
```

Mount additional paths if your Codex version documents other state locations.

---

## Related

The monorepo root `Dockerfile` can also include Codex via multi-stage targets. This directory is a **standalone** build so you can image Codex without the multi-agent graph.

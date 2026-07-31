# Hermes Agent container

Debian-based image with [Hermes Agent](https://hermes-agent.nousresearch.com/)
(Nous Research's terminal AI agent) preinstalled, plus common editor and
search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).  The image
also includes Node.js and `ffmpeg`, which are used by Hermes and its
optional tool integrations.

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t hermes .
```

From the repository root:

```bash
docker build -t hermes -f hermes/Dockerfile hermes
```

### Build arguments

| Argument                   | Default      | Description                                       |
|----------------------------|--------------|---------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas` tools) |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings         |
| `NODE_VERSION`             | `v24.18.1`   | Node.js runtime version                           |
| `NPM_VERSION`              | `12.0.0`     | npm version installed in the image                |

Examples:

```bash
# Development image (extra packages, passwordless doas for the user)
docker build -t hermes:dev --build-arg ENVIRONMENT=development .

# Use a different container username
docker build -t hermes:custom --build-arg CONTAINER_USER=developer .
```

The Dockerfile downloads the official Hermes installer and runs it with
`--skip-setup --skip-browser --non-interactive`.  Provider configuration
and authentication are therefore completed when the container is run,
rather than during the image build.

---

## Run

Interactive terminal chat (TTY required):

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  hermes hermes
```

Single query:

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  hermes hermes chat -q "Summarize this repository"
```

You can pass the API key for the provider you use, or configure a
provider interactively inside the container with `hermes setup` / `hermes model`.
For example, replace `OPENAI_API_KEY` with `ANTHROPIC_API_KEY`,
`OPENROUTER_API_KEY`, `GEMINI_API_KEY`, or another provider-specific
credential supported by Hermes.

For a first-time setup with persistent state, run:

```bash
docker run --rm -it \
  -v "$HOME/.hermes-docker:/home/user/.hermes" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  hermes hermes setup
```

---

## What lives in `~/.hermes`

Hermes stores configuration, credentials, sessions, skills, and other
runtime data under `HERMES_HOME` (default `~/.hermes`).  When the image
runs as its default user, this is `/home/user/.hermes`; set `HERMES_HOME`
to use a different location.

| Kind               | Paths                                                            | Purpose                                      |
|--------------------|------------------------------------------------------------------|----------------------------------------------|
| **Configuration**  | `config.yaml`, `.env`                                            | Settings in `config.yaml`; secrets in `.env` |
| **Authentication** | `auth.json`                                                      | OAuth tokens and credential pools            |
| **Sessions**       | `state.db`, `sessions/`                                          | Session history, FTS index, gateway records  |
| **User content**   | `skills/`, `skins/`, `desktop-plugins/`, `tui-widgets/`, `pets/` | Extensions, themes, widgets, and mascots     |
| **Diagnostics**    | `logs/`                                                          | Gateway and error logs                       |
| **Source**         | `hermes-agent/`                                                  | Source checkout when installed in home       |

`state.db` is the canonical SQLite session store.  Gateway routing
indexes, request dumps, and JSONL transcripts may also be written below
`~/.hermes/sessions/`.

Profiles are isolated below `~/.hermes/profiles/<name>/`.  When a
profile or custom `HERMES_HOME` is in use, persist that effective home
instead of assuming the default path.

The installer uses an FHS-style system install for the root Docker build:
Hermes code is under `/usr/local/lib/hermes-agent` and the `hermes`
command is available at `/usr/local/bin/hermes`.  Runtime data remains
in the container user's `HERMES_HOME`.

---

## Persistence beyond the container

Containers are ephemeral.  Without a volume, Hermes configuration,
credentials, sessions, memory, and user-installed skills disappear when
the container exits.

### Option 1 - Mount the complete Hermes home (recommended)

Persist the whole runtime home while keeping the executable and
installed code in the image:

```bash
mkdir -p "$HOME/.hermes-docker"

touch "$HOME/.hermes-docker/.env"

docker run --rm -it \
  -v "$HOME/.hermes-docker:/home/user/.hermes" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  hermes hermes
```

This preserves `config.yaml`, `.env`, `auth.json`, `state.db`, sessions,
logs, profiles, and user extensions.  Keep the directory private because
it may contain credentials and conversation history.  The `/usr/local/bin/hermes`
command and system installation are not inside this mount.

### Option 2 - Use a named volume

```bash
docker run --rm -it \
  -v hermes-home:/home/user/.hermes \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e OPENAI_API_KEY \
  hermes hermes
```

The named volume is initialized automatically on first use.  It persists
Hermes state across containers, but rebuilding the image does not update
the system-installed Hermes code until the image is rebuilt and the
container is recreated.

### Option 3 - Mount selected state paths

Leave the image-owned installation in place and persist only selected
files or directories:

```bash
mkdir -p "$HOME/.hermes-docker"/{profiles,sessions,skills,logs}
touch "$HOME/.hermes-docker/.env" "$HOME/.hermes-docker/config.yaml"

docker run --rm -it \
  -v "$HOME/.hermes-docker/.env:/home/user/.hermes/.env" \
  -v "$HOME/.hermes-docker/config.yaml:/home/user/.hermes/config.yaml" \
  -v "$HOME/.hermes-docker/state.db:/home/user/.hermes/state.db" \
  -v "$HOME/.hermes-docker/sessions:/home/user/.hermes/sessions" \
  -v "$HOME/.hermes-docker/profiles:/home/user/.hermes/profiles" \
  -v "$HOME/.hermes-docker/skills:/home/user/.hermes/skills" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  hermes hermes
```

Add `auth.json`, `memory/`, `skins/`, `desktop-plugins/`, or other paths
as needed.  Mounting the whole home (Option 1) is less error-prone and
also preserves newly added Hermes state directories.

### Notice: secrets and profiles

Keep API keys and OAuth credentials in `.env` or `auth.json` as
appropriate; keep non-secret settings in `config.yaml`.  Do not commit
the mounted Hermes home to a repository.  For named profiles, mount the
parent home so `profiles/<name>/` remains available.

### Notice: session keys use the container working directory

Sessions can be associated with the absolute working directory inside
the container.  For reliable resume behaviour across runs:

- Use a stable `-w` path such as `/workspaces/project`.
- Mount each project at the same container path on every run.
- Persist `state.db` and the `sessions/` directory together.

### What to persist (minimum vs full)

| Goal                  | Persist at least                              |
|-----------------------|-----------------------------------------------|
| Resume conversations  | `state.db` and `sessions/`                    |
| Stay logged in        | `auth.json` or provider `.env` credentials    |
| Keep settings         | `config.yaml`                                 |
| Keep profiles         | `profiles/`                                   |
| Preserve custom tools | `skills/`, `desktop-plugins/`, `tui-widgets/` |
| Full Hermes state     | Entire `HERMES_HOME` (Option 1 or 2)          |

---

## Image layout (reference)

| Path                          | Description                                     |
|-------------------------------|-------------------------------------------------|
| `/usr/local/bin/hermes`       | Hermes command installed by the official script |
| `/usr/local/lib/hermes-agent` | System Hermes installation and runtime code     |
| `/home/user/.hermes`          | Default runtime data directory                  |
| `/workspaces`                 | Default working directory                       |

---

## Related

The monorepo root `Dockerfile` can also build a Hermes-only image via
the multi-stage target `PROVIDER=hermes`:

```bash
docker build -t agents:hermes --build-arg PROVIDER=hermes .
```

This directory is a standalone Dockerfile so you can build and document
Hermes without the multi-agent graph.

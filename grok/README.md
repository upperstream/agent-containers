# Grok Build container

Debian-based image with [Grok Build](https://x.ai/) (xAI’s terminal
coding agent) preinstalled under `/home/user/.grok`, plus common editor
and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t grok .
```

From the repository root:

```bash
docker build -t grok -f grok/Dockerfile grok
```

### Build arguments

| Argument                   | Default      | Description                                                              |
|----------------------------|--------------|--------------------------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling)                 |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                                |
| `GROK_VERSION`             | (latest)     | Pin a Grok CLI version for the installer                                 |
| `GROK_CHANNEL`             | (unset)      | Reserved for channel selection (passed through like the root Dockerfile) |

Examples:

```bash
# Development image (extra packages, passwordless doas for the user)
docker build -t grok:dev --build-arg ENVIRONMENT=development .

# Pin a specific Grok version
docker build -t grok:0.1.42 --build-arg GROK_VERSION=0.1.42 .
```

---

## Run

Interactive TUI (TTY required):

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

Headless / one-shot:

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok -p "Summarize this repository"
```

Authenticate with an xAI API key (`XAI_API_KEY`) or complete
browser/device login so credentials land in `~/.grok/auth.json` (see
persistence below).

---

## What lives in `~/.grok`

Grok uses a **single home directory** (`GROK_HOME`, default `~/.grok`)
for both install assets and runtime state.  This image copies a full
install into `/home/user/.grok`.

| Kind               | Paths                                                                                                                | Purpose                                                        |
|--------------------|----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| **Install assets** | `bin/`, `downloads/`, `docs/` (user guide), `bundled/`, shipped `skills/`, `vendor/`, `completions/`, `version.json` | Binary, online/local documentation, built-in skills and agents |
| **Mutable state**  | `sessions/`, `auth.json`, `config.toml`, `pager.toml`, `memory/`, `logs/`, user `skills/`, hooks, plugins            | Auth, config, conversation history, cross-session memory       |

Sessions are stored as:

```text
~/.grok/sessions/<url-encoded-cwd>/<session-id>/
```

Override the home directory with `GROK_HOME` if needed.

---

## Persistence beyond the container

Ephemeral containers lose everything under `/home/user/.grok` unless
you mount storage.  You need more than sessions: auth, config, and
(depending on strategy) install assets such as the user guide under
`docs/`.

### Do not mount an empty or session-only host `~/.grok`

Bind-mounting host `~/.grok` onto `/home/user/.grok` **replaces** the
image’s full install with the host tree.  If the host directory is empty
or only contains `sessions/`, you lose:

- the Grok binary layout under `bin/` / `downloads/`
- user-guide docs under `docs/`
- bundled skills, agents, and other install assets

Either mount a **complete** `GROK_HOME`, or leave install assets in the
image and mount **only mutable paths**.

### Option 1: mount a full host `~/.grok`

```bash
docker run --rm -it \
  -v "$HOME/.grok:/home/user/.grok" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

**Requirements:**

1. Host `~/.grok` must be a **complete** install (binary, docs, skills,
   etc.), not sessions alone.
2. Seed once if the host tree is incomplete, for example:

   ```bash
   # Copy install assets out of this image onto the host
   docker run --rm grok tar -C /home/user -cf - .grok | \
       tar -C "$HOME" -xf -
   ```

   Or install Grok on the host with the official installer (match
   OS/arch if you rely on the host binary).
3. Keep **versions aligned** between host and image (`grok update` /
   rebuild) so binary, docs, and bundled assets do not drift.

### Option 2: keep install; mount mutable state (recommended)

Leave `/home/user/.grok` from the image (docs, `bin`, `bundled`, shipped
skills).  Persist user state only:

```bash
mkdir -p "$HOME/.grok-docker"/{sessions,memory,logs,skills,hooks}
# Ensure auth/config are files
# (Docker creates a directory if the host path is missing)
touch "$HOME/.grok-docker/auth.json" "$HOME/.grok-docker/config.toml"

docker run --rm -it \
  -v "$HOME/.grok-docker/sessions:/home/user/.grok/sessions" \
  -v "$HOME/.grok-docker/auth.json:/home/user/.grok/auth.json" \
  -v "$HOME/.grok-docker/config.toml:/home/user/.grok/config.toml" \
  -v "$HOME/.grok-docker/memory:/home/user/.grok/memory" \
  -v "$HOME/.grok-docker/logs:/home/user/.grok/logs" \
  -v "$HOME/.grok-docker/skills:/home/user/.grok/skills" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

**Pros:** Image owns install assets and refreshes on rebuild; host only
          keeps durable state.  
**Cons:** More volume mounts; user-defined skills live on the host mount
          while shipped/bundled skills stay in the image.

### Option 3 - Named volume for the entire home

```bash
# First run: seed the volume from the image if empty
docker run --rm -v grok-home:/data grok \
  sh -c 'cp -a /home/user/.grok/. /data/'

docker run --rm -it \
  -v grok-home:/home/user/.grok \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

Persists **everything** (sessions, auth, docs, binary tree).  Rebuilds
do not refresh install assets until you re-seed or run `grok update`
inside the container with the volume attached.

### Notice: session keys use container working directory

Sessions are grouped by the **encoded absolute cwd** inside the
container (for example `/workspaces/project`), not by the host path.
Host Grok at `/home/you/proj` and container Grok at
`/workspaces/project` are different session buckets.

For reliable `/resume` across container runs:

- Use a **stable** `-w` / `WORKDIR` path (this image defaults to
  `/workspaces`).
- Prefer a consistent project mountpoint such as `/workspaces/project`.

### What to persist (minimum vs full)

| Goal                           | Persist at least                                          |
|--------------------------------|-----------------------------------------------------------|
| Resume conversations           | `sessions/`                                               |
| Stay logged in                 | `auth.json`                                               |
| Keep settings                  | `config.toml` (and `pager.toml` if customised)            |
| Cross-session memory           | `memory/`                                                 |
| Custom skills/hooks            | user `skills/`, `hooks/`, plugins                         |
| Docs + binary + bundled skills | full `GROK_HOME` or leave them in the image (options 2/3) |

Mounting **only** `sessions/` is not enough for a usable long-lived
setup.

---

## Image layout (reference)

| Path                  | Description                                    |
|-----------------------|------------------------------------------------|
| `/home/user/.grok`    | Full Grok home (install + default empty state) |
| `/usr/local/bin/grok` | Symlink to `/home/user/.grok/bin/grok`         |
| `/workspaces`         | Default working directory                      |

---

## Related

The monorepo root `Dockerfile` can also build a Grok-only image via
multi-stage targets (`PROVIDER=grok`).  This directory is a
**standalone** Dockerfile so you can build and document Grok without the
multi-agent graph.

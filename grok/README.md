# Grok Build container

Debian-based image with [Grok Build](https://x.ai/) (xAI’s terminal
coding agent) preinstalled under `/home/user/.local/share/grok`, plus
common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`,
etc.).  User state lives in `/home/user/.grok`.

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
| `GROK_VERSION`             | `1.0.5`      | Pin a Grok CLI version for the installer                                 |
| `GROK_CHANNEL`             | (unset)      | Reserved for channel selection (passed through like the root Dockerfile) |

Examples:

```bash
# Development image (extra packages, passwordless doas for the user)
docker build -t grok:dev --build-arg ENVIRONMENT=development .

# Pin a specific Grok version
docker build -t grok:1.0.5 --build-arg GROK_VERSION=1.0.5 .
```

---

## Run

Interactive TUI (TTY required):

```bash
docker run --rm -it \
  -v "$HOME/grok_home:/home/user/.grok" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

Headless / one-shot:

```bash
docker run --rm -it \
  -v "$HOME/grok_home:/home/user/.grok" \
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

Grok’s default `GROK_HOME` is `~/.grok`.  This image splits that tree:

| Kind               | Location                                                                                           | Purpose                                                    |
|--------------------|----------------------------------------------------------------------------------------------------|------------------------------------------------------------|
| **Install assets** | `~/.local/share/grok` (`bin/`, `completions/`, `docs/`, `downloads/`)                              | Binary and user-guide docs; refreshed when you rebuild     |
| **Mutable state**  | `~/.grok` (`sessions/`, `auth.json`, `config.toml`, `pager.toml`, `memory/`, `logs/`, user skills) | Auth, settings, conversation history, cross-session memory |

The image’s `~/.grok` contains dangling-from-the-host, valid-in-the-
container symlinks:

```text
~/.grok/bin          -> ~/.local/share/grok/bin
~/.grok/completions  -> ~/.local/share/grok/completions
~/.grok/docs         -> ~/.local/share/grok/docs
~/.grok/downloads    -> ~/.local/share/grok/downloads
```

`/usr/local/bin/grok` points at `~/.local/share/grok/bin/grok`, so the
CLI works even if `~/.grok/bin` is missing.

Sessions are stored as:

```text
~/.grok/sessions/<url-encoded-cwd>/<session-id>/
```

Override the home directory with `GROK_HOME` if needed.

---

## Persistence beyond the container

Bind-mount a host directory onto `/home/user/.grok`.  Prepare that
directory with the same four symlinks; they are dangling on the host
and resolve inside the container.

```bash
mkdir -p "$HOME/grok_home"
ln -s /home/user/.local/share/grok/bin \
    "$HOME/grok_home/bin"
ln -s /home/user/.local/share/grok/completions \
    "$HOME/grok_home/completions"
ln -s /home/user/.local/share/grok/docs \
    "$HOME/grok_home/docs"
ln -s /home/user/.local/share/grok/downloads \
    "$HOME/grok_home/downloads"

docker run --rm -it \
  -v "$HOME/grok_home:/home/user/.grok" \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  -e XAI_API_KEY \
  grok grok
```

Substitute `user` if you set `CONTAINER_USER`.  Grok then creates
`config.toml`, `auth.json`, `sessions/`, and the rest on the volume.
`/settings` can save, because `config.toml` is a real file in the
mounted directory.

Do not mount an empty host directory.  Without those four symlinks,
`~/.grok/bin` and `docs/` do not resolve.

Online updates (`grok update` and the auto-updater) write into the
install bundle in the container.  Those writes are discarded when the
container exits.  Ship a new version by rebuilding the image with
`GROK_VERSION`; sessions and settings on the host volume survive.

To disable the auto-updater, write `$GROK_HOME/config.toml` (default
`~/.grok/config.toml`, the bind-mounted host directory) with:

```toml
[cli]
auto_update = false
```

### Notice: session keys use container working directory

Sessions are grouped by the encoded absolute cwd inside the container
(for example `/workspaces/project`), not by the host path.  Host Grok at
`/home/you/proj` and container Grok at `/workspaces/project` are
different session buckets.

For reliable `/resume` across container runs:

- Use a stable `-w` / `WORKDIR` path (this image defaults to
  `/workspaces`).
- Prefer a consistent project mountpoint such as `/workspaces/project`.

---

## Image layout (reference)

| Path                           | Description                                                |
|--------------------------------|------------------------------------------------------------|
| `/home/user/.local/share/grok` | Install bundle (`bin`, `completions`, `docs`, `downloads`) |
| `/home/user/.grok`             | User home; four install dirs are symlinks into the bundle  |
| `/usr/local/bin/grok`          | Symlink to `~/.local/share/grok/bin/grok`                  |
| `/workspaces`                  | Default working directory                                  |

---

## Related

The monorepo root `Dockerfile` can also build a Grok-only image via
multi-stage targets (`PROVIDER=grok`).  This directory is a
standalone Dockerfile so you can build and document Grok without the
multi-agent graph.

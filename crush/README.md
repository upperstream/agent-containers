# Crush container

Debian-based image with [Crush][] (Charmbracelet) preinstalled from
official GitHub release tarballs, plus common editor and search tools
(`git`, `ripgrep`, `fd`, `vim`, `nano`, `emacs`, `mg`, `micro`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t crush .
```

From the repository root:

```bash
docker build -t crush -f crush/Dockerfile crush
```

### Build arguments

| Argument                   | Default      | Description                                              |
|----------------------------|--------------|----------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                       |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling) |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                |
| `CRUSH_VERSION`            | `v0.87.0`    | Git tag, e.g. `v0.89.0`, or `nightly`                    |

Examples:

```bash
docker build -t crush:dev --build-arg ENVIRONMENT=development .
docker build -t crush:v0.89.0 --build-arg CRUSH_VERSION=v0.89.0 .
docker build -t crush:nightly --build-arg CRUSH_VERSION=nightly .
```

The builder stage uses `debian:trixie-slim` and downloads the prebuilt
release tarball (`crush_<version>_Linux_<arch>.tar.gz`) for the current
architecture (`amd64`/`arm64`); for `nightly` it resolves the file name
from the nightly `checksums.txt`.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  crush crush
```

Configure API keys and providers according to Crush's documentation for
your version.

---

## Image layout

| Path                                              | Description               |
|---------------------------------------------------|---------------------------|
| `/usr/local/bin/crush`                            | Crush binary              |
| `/usr/local/share/doc/crush`                      | `LICENSE.md`, `README.md` |
| `/etc/bash_completion_d/crush`                    | Bash completions          |
| `/usr/share/fish/vendor_completions.d/crush.fish` | Fish completions          |
| `/usr/share/zsh/site-functions/_crush`            | Zsh completions           |
| `/usr/local/share/man/man1/crush.1.gz`            | Man page                  |
| `/workspaces`                                     | Default working directory |

### Persistence

Mount config and data directories Crush creates under the container
user's home if you need state across runs.  Prefer the paths documented
by Crush for your release.

---

## Related

The monorepo root `Dockerfile` can also include Crush via multi-stage
targets.  This directory is a standalone build so you can image Crush
without the multi-agent graph.

[Crush]: https://github.com/charmbracelet/crush
  "charmbracelet/crush: Glamourous agentic coding for all 💘"

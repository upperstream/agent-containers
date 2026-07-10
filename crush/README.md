# Crush container

Debian-based image with [Crush](https://github.com/charmbracelet/crush) (Charmbracelet) preinstalled from source via Go, plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

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
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                |
| `CRUSH_VERSION`            | `latest`     | Go module version, e.g. `latest` or `v0.81.0`            |

Examples:

```bash
docker build -t crush:dev --build-arg ENVIRONMENT=development .
docker build -t crush:v0.81.0 --build-arg CRUSH_VERSION=v0.81.0 .
```

The builder stage uses `golang:1.26-trixie`, runs `go install github.com/charmbracelet/crush@…`, and strips the binary.

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  crush crush
```

Configure API keys and providers according to Crush’s documentation for your version.

---

## Image layout

| Path                   | Description               |
|------------------------|---------------------------|
| `/usr/local/bin/crush` | Crush binary (stripped)   |
| `/workspaces`          | Default working directory |

### Persistence

Mount config and data directories Crush creates under the container user’s home if you need state across runs. Prefer the paths documented by Crush for your release.

---

## Related

The monorepo root `Dockerfile` can also include Crush via multi-stage targets. This directory is a **standalone** build so you can image Crush without the multi-agent graph.

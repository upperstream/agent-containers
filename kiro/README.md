# Kiro CLI container

Debian-based image with [Kiro CLI](https://cli.kiro.dev/) (`kiro-cli`) preinstalled, plus common editor and search tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with `CONTAINER_USER`). Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t kiro .
```

From the repository root:

```bash
docker build -t kiro -f kiro/Dockerfile kiro
```

### Build arguments

| Argument                   | Default      | Description                                                   |
|----------------------------|--------------|---------------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                            |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling)      |
| `NANO_CLASSIC_KEYBINDINGS` | *(unset)*    | Set to `yes` for classic nano keybindings                     |
| `KIRO_CHANNEL`             | *(unset)*    | Installer channel (`--channel …` when set)                    |
| `KIRO_FORCE`               | *(unset)*    | Set to any non-empty value to pass `--force` to the installer |

Examples:

```bash
docker build -t kiro:dev --build-arg ENVIRONMENT=development .
docker build -t kiro:channel --build-arg KIRO_CHANNEL=stable .
docker build -t kiro:force --build-arg KIRO_FORCE=1 .
```

---

## Run

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -w /workspaces/project \
  kiro kiro-cli
```

Authenticate according to Kiro CLI documentation for your environment.

---

## Image layout

| Path                      | Description                |
|---------------------------|----------------------------|
| `/usr/local/bin/kiro-cli` | Kiro CLI binary (stripped) |
| `/workspaces`             | Default working directory  |

### Persistence

Mount home-directory config or credential paths `kiro-cli` creates if you need them across container runs. Prefer the locations documented for your Kiro release.

---

## Related

The monorepo root `Dockerfile` can also include Kiro via multi-stage targets. This directory is a **standalone** build so you can image Kiro without the multi-agent graph.

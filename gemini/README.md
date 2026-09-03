# Gemini CLI container

Debian-based image with [Google Gemini
CLI](https://github.com/google-gemini/gemini-cli) (`@google/gemini-cli`)
preinstalled on a bundled Node.js runtime, plus common editor and search
tools (`git`, `ripgrep`, `fd`, `vim`, `nano`, etc.).

The default container user is `user` (override at build time with
`CONTAINER_USER`).  Working directory is `/workspaces`.

---

## Build

From this directory:

```bash
docker build -t gemini .
```

From the repository root:

```bash
docker build -t gemini -f gemini/Dockerfile gemini
```

### Build arguments

| Argument                   | Default      | Description                                                   |
|----------------------------|--------------|---------------------------------------------------------------|
| `CONTAINER_USER`           | `user`       | Non-root user created in the image                            |
| `ENVIRONMENT`              | `production` | `production` or `development` (adds `doas`/sudo tooling)      |
| `GEMINI_RELEASE`           | `0.55.1`     | npm tag/version: `latest`, `preview`, `nightly`, or a version |
| `NANO_CLASSIC_KEYBINDINGS` | (unset)      | Set to `yes` for classic nano keybindings                     |
| `NODE_VERSION`             | `v24.20.0`   | Node.js version to install                                    |
| `NPM_VERSION`              | `12.0.0`     | Global npm version                                            |

Examples:

```bash
docker build -t gemini:dev --build-arg ENVIRONMENT=development .
docker build -t gemini:preview --build-arg GEMINI_RELEASE=preview .
```

---

## Run

To retain Gemini user data and session information after the container
is removed, create an empty state directory on the host:

```bash
mkdir -p .gemini
```

Mount it at the default container user's Gemini data path when running
the image:

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -v "$PWD/.gemini:/home/user/.gemini" \
  -w /workspaces/project \
  -e GEMINI_API_KEY \
  gemini gemini
```

Authenticate with a Gemini API key or the CLI's login flow as
documented for your release.  Gemini writes its configuration and
session data to the mounted `.gemini` directory.  Adjust
`/home/user` if you build the image with a different `CONTAINER_USER`.

---

## Image layout

| Path                                                 | Description                              |
|------------------------------------------------------|------------------------------------------|
| `/usr/local/node-<version>/`                         | Bundled Node.js runtime                  |
| `/usr/local/node-<version>/lib/node_modules/@google` | Gemini CLI and related packages          |
| `/usr/local/bin/gemini`                              | Symlink to `gemini-cli/bundle/gemini.js` |
| `/usr/local/bin/*`                                   | Node/npm binaries                        |
| `/workspaces`                                        | Default working directory                |

### Persistence

Prepare and mount a `.gemini` directory on the host as shown in the
preceding run instruction to persist configuration, credentials, and
session history across container runs.

---

## Related

The monorepo root `Dockerfile` can also include Gemini via multi-stage
targets.  This directory is a standalone build so you can image Gemini
without the multi-agent graph.  Unlike the incomplete root `gemini`
intermediate stage alone, this image copies both Node and the `@google`
modules so the CLI is self-contained.

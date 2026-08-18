# GitHub Copilot CLI container

Debian Trixie Slim image with [GitHub Copilot CLI][] and common
editor, search, and development tools preinstalled.

The default container user is `user`.  Override it at build time with
`CONTAINER_USER`.  The working directory is `/workspaces`.

[GitHub Copilot CLI]:
https://docs.github.com/en/copilot/how-tos/use-copilot-extensions/use-copilot-cli

---

## Build

Build from this directory:

```bash
docker build -t copilot .
```

Or build from the repository root:

```bash
docker build -t copilot -f copilot/Dockerfile copilot
```

### Build arguments

- `CONTAINER_USER` defaults to `user`, the non-root user created in the
  image.
- `ENVIRONMENT` defaults to `production`.  It selects either the
  `production` or `development` final image.
- `NANO_CLASSIC_KEYBINDINGS` defaults to `no`.  Set it to `yes` for
  classic nano keybindings.
- `COPILOT_VERSION` defaults to `1.0.80`.  It is passed to the Copilot
  installer.

Examples:

```bash
docker build -t copilot:dev --build-arg ENVIRONMENT=development .
docker build -t copilot:prerelease --build-arg COPILOT_VERSION=prerelease .
```

The development image adds `binutils`, `file`, `opendoas`, and `tree`.
It permits members of the `sudo` group to run `doas` without a password.

---

## Run

To retain Copilot user data and session information after the container
is removed, create an empty state directory on the host:

```bash
mkdir -p .copilot
```

Mount it at the default container user's Copilot data path when running
the image:

```bash
docker run --rm -it \
  -v "$PWD:/workspaces/project" \
  -v "$PWD/.copilot:/home/user/.copilot" \
  -w /workspaces/project \
  copilot copilot
```

Authenticate with GitHub, using device flow or a token, as required by
the Copilot CLI.  Copilot writes its authentication and session data to
the mounted `.copilot` directory.  Adjust `/home/user` if you build the
image with a different `CONTAINER_USER`.

---

## Included software

The production image includes:

- GitHub Copilot CLI at `/usr/local/bin/copilot`
- `emacs-nox`, `mg`, `micro`, `nano`, and `vim-nox`
- `fd-find`, `git`, and `ripgrep`

The image has no entrypoint or default command.  Run `copilot`
explicitly, as in the preceding example.

---

## Related

The monorepo root `Dockerfile` can also include Copilot through
multi-stage targets.  This directory is a standalone build for an
image that contains only the Copilot environment.

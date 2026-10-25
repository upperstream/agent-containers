# AGENTS.md

Guidance for coding agents working in this repository.  The user-facing
overview is in `README.md`; this file covers only what is not obvious
from reading one or two files.

## What this repository is

The repository contains Dockerfiles, shell scripts, and Markdown only.
There is no application source code, package manager, or compiler.
The "product" is a set of Debian (`debian:trixie-slim`) images that
package third-party coding-agent CLIs.

There are two parallel build definitions for every agent:

- The root `Dockerfile` is a multi-stage graph with a `<agent>_builder`
  stage and a runtime `<agent>` stage per agent, plus an `all` stage.
  `PROVIDER` (default `all`) selects the stage that becomes
  `production`, and `ENVIRONMENT` selects `production` or
  `development` as the final stage.
- Each `<agent>/Dockerfile` is a self-contained copy of the same logic
  (it duplicates `builder_base`, `container_base`, and the agent's
  builder) and ends in its own `production`/`development`/final
  stages.  OpenWiki lives in `openwiki-agent/` but its provider and
  stage name is `openwiki`.

The two definitions are not generated from each other.  Every change
to an agent's install logic or version pin must be made by hand in both
places, and the `all` stage in the root `Dockerfile` needs its own
`COPY --from=...` lines and symlinks as well.

## Keeping things in sync

A version bump or install change usually touches all of these:

1. The `ARG <AGENT>_VERSION`/`_RELEASE` default at the top of the root
   `Dockerfile`.
2. The same `ARG` in `<agent>/Dockerfile`.
3. The root build arguments table in `README.md`.
4. The version mentioned in `<agent>/README.md`.
5. An entry under `## [Unreleased][]` in `CHANGELOG.md`.

For example, the Cline 3.0.65 commit (`75d7570`) touched exactly
`CHANGELOG.md`, `Dockerfile`, `README.md`, `cline/Dockerfile`, and
`cline/README.md`.  Drift does happen (a Codex bump once touched only
`codex/Dockerfile`), so check both copies before assuming a version.

The `standalone_providers` list in `build.sh` must be updated when an
agent directory is added or removed.  The self-test hard-codes build
counts derived from that list (for example `t_expect_lines P5 40`,
which is (1 root + 19 standalone) x 2 environments), so update those
numbers too.

## Commands

```sh
# build.sh self-test (no container engine needed; uses a stub engine)
./build.sh --test

# Build and tag images (podman preferred, docker fallback; override
# with DOCKER=/path/to/engine)
./build.sh                 # root Dockerfile only (image: agents)
./build.sh grok pi         # standalone images
./build.sh -k -a           # root + all standalone, keep going on error

# Build tests, run from inside the Dev Container `agents` service
tests/docker_build_test.sh [DOCKERFILE [CONTEXT]]
tests/podman_build_test.sh [DOCKERFILE [CONTEXT]]
# e.g. tests/docker_build_test.sh cline/Dockerfile cline

# Check builder socket access and TCP isolation, from inside `agents`
tests/builder_socket_test.sh
```

Plain `docker build` works too; see `README.md` for examples.  Note
that `build.sh` always passes `NANO_CLASSIC_KEYBINDINGS=yes` and builds
each provider twice (production then development).

The build tests do not use the host engine.  They talk to sibling
Compose services defined in
`.devcontainer/docker-compose.devcontainer.yml` through Unix sockets,
not TCP:

- The `docker_builder` service runs `dockerd`, and clients use
  `DOCKER_HOST=unix:///run/docker-builder/docker.sock`.
- The `podman_builder` service runs `podman system service`, and the
  `podman-remote` client uses
  `CONTAINER_HOST=unix:///run/podman-builder/podman.sock`.

The Compose overlay sets both variables for `agents`, and the scripts
fall back to the same paths when they are unset.  Outside that Dev
Container the sockets do not exist, so the scripts time out after 30
seconds waiting for the daemon.  The `docker` and `podman-remote`
clients exist only in the root image's `development` stage.
`tests/builder_socket_test.sh` also requires `curl`, and fails if
either builder still answers on its former `http://<builder>:2375`
endpoint.

Upgrade commits have been verified by running both build test scripts
against both the root and the standalone Dockerfile.  Full builds
download installers from the internet and can be slow; the root `all`
build is large.

There is no configured linter runner, but the shell scripts carry
`# shellcheck disable=...` directives and `.markdownlint.json` exists,
so keep scripts ShellCheck-clean and Markdown markdownlint-clean.

## Dockerfile conventions and gotchas

- All `ARG` defaults are declared once at the top of each Dockerfile,
  aligned, with a trailing comment listing accepted values (for
  example `# 'latest' or '0.142.5'`).  Stages re-declare the bare `ARG`
  with the comment `# global default`.  Trailing comments on `ARG`
  lines are part of the style; keep the column alignment when editing.
- Version args are expanded with `${VAR:-latest}` or `${VAR:+...}` so
  that an empty value means "latest/unpinned" or "omit the flag".
- A stage-level `ARG` is also visible as an environment variable to
  that stage's `RUN` steps, and some upstream installers read it from
  there.  For example, the Codex installer reads `CODEX_RELEASE`
  (defaulting to `latest`) from its environment, so the pin works
  even though the Dockerfile never passes it explicitly.  Check the
  installer script before concluding a version argument is unused.
- Builders run as root and install into `/root/...`; runtime stages
  `COPY --from=` the result into `/usr/local/bin` or
  `/home/${CONTAINER_USER}/...`.  The `production` stage then
  `chown -R`s the home directory.  Tools that embed absolute
  `/root/...` symlinks (Codex, Grok, Cursor) are re-linked with
  `readlink`/`sed` in the runtime stage; copy that logic exactly when
  touching it.
- Node-based agents (cline, droid, gemini, openclaw, pi, openwiki) get
  Node.js from a tarball under `/usr/local/node-${NODE_VERSION}` built
  in `node_base`, and are symlinked into `/usr/local/bin`.  The
  `openwiki_builder` stage duplicates the Node download instead of
  using `node_base`.
- Do not `strip` Bun-compiled executables (droid, kilo, opencode); it
  destroys the embedded payload.  Only herdr and kiro-cli are stripped
  (via the `bin_stripper` stage).
- Herdr's upstream installer cannot select a version, so
  `herdr/herdr_installer.sh.diff` is applied with `patch` at build
  time.  The root `Dockerfile` copies it from `herdr/`, so the root
  build context must be the repository root.  If upstream changes the
  installer, the patch may stop applying.
- Hermes is built by cloning the repository at `HERMES_VERSION` and
  running its `scripts/install.sh` (with a `sed` tweak), not a web
  bootstrap script.
- The root `Dockerfile` has a `hermes_builder` stage but no `hermes`
  runtime stage; Hermes is only reachable there through `PROVIDER=all`.
- `apt-get update` and `apt-get install` must stay in the same `RUN`
  (an explicit past change).
- The `development` stage removes Debian's `dpkg.cfg.d` exclusion
  files, installs extra tools (`opendoas`, `binutils`, `file`, `tree`,
  and in the root image `docker-cli`, `docker-buildx`,
  `podman-remote`), and grants `doas` to group `sudo` with password
  authentication (`permit :sudo`).
- The final stage is `FROM "${ENVIRONMENT}"` and sets `EDITOR`,
  `GIT_EDITOR`, `TERM` from build-time values, `WORKDIR /workspaces`,
  and `USER ${CONTAINER_USER}`.  Only the root image sets
  `ENTRYPOINT ["/bin/sh", "-c"]` and `CMD ["bash"]`.
- `.gitattributes` has a typo (`Dockerfile tet eol=lf`), so the LF rule
  is not actually applied to Dockerfiles.

## build.sh

POSIX `sh`, tab-indented.  Tags are derived from git state (branch,
clean or modified tree, whether HEAD is the tip of `origin/<branch>`,
and any tag on HEAD); the full rule table is in the header comment.
`master` is treated as the main branch name.  A detached HEAD uses the
short commit hash as the branch name.

The self-test is embedded in the same file (`run_tests`, helpers
prefixed `t_`).  It sources nothing; it runs `main` in subshells inside
a scratch git repository with a stub `docker` script (selected via the
`DOCKER` variable) that logs `build`/`tag` calls, then asserts on log
lines and output.  Add new cases in the same style (`t_repo_init`,
`t_run`, `t_logline`, `t_expect_lines`).

## Dev Container and Compose

- `docker-compose.yml` builds the root image as service `agents` with
  user `user` and bind-mounts agent state directories from the host
  (`CLAUDE_HOME`, `CODEX_HOME`, and so on).  `CLINE_HOME` falls back to
  `$HOME/.claude`, not `$HOME/.cline`.
- `.devcontainer/devcontainer.json` layers
  `docker-compose.devcontainer.yml` on top, switching to
  `CONTAINER_USER=devcontainer` and `ENVIRONMENT=development`, and
  mounting `/dev/null` over the `/home/user/...` paths inherited from
  the base Compose file.
- The same overlay defines the `docker_builder` and `podman_builder`
  sidecars.  Both are built on `alpine:3.24.1` from
  `.devcontainer/<builder>.Dockerfile`, run `privileged` with
  `cgroup: host` (Podman also gets `/dev/fuse`), and use
  `.devcontainer/builder_entrypoint.sh` as their entrypoint.  The
  entrypoint starts the engine, waits up to 60 seconds for its
  socket, and then sets the socket to mode 0660 with group
  `builders` (GID 2375).  The socket directory is mode 0750.
- Each sidecar's socket lives on its own named volume
  (`docker_builder_socket`, `podman_builder_socket`), which is
  mounted read-only into `agents` at `/run/docker-builder` and
  `/run/podman-builder`.  The `agents` service gets access through
  `group_add: "2375"`, which still works after Dev Container UID/GID
  remapping.  Keep the GID consistent across the Compose file, both
  builder Dockerfiles, and the health checks.
- Engine data lives on the named volumes `docker_builder_data`
  (`/var/lib/docker`) and `podman_builder_data`
  (`/var/lib/containers`), not on the container overlay.  Nested
  overlay mounts fail with `EINVAL` otherwise.  Docker has the
  containerd snapshotter disabled in `/etc/docker/daemon.json`.
  Podman uses the `overlay` driver, `runc`, and `cgroupfs`, and
  needs `iptables` for netavark.
- The health checks verify the socket mode and group (`660:2375`)
  and ping the API with `curl --unix-socket`.  The `agents` service
  waits for both builders through `depends_on` with
  `condition: service_healthy`.
- The host engine socket is never mounted into any service.
- `docker-compose.tagged.yml` (untracked at the time of writing) runs
  a prebuilt image,
  `${AGENT_CONTAINERS_IMAGE:-agents}:${AGENT_CONTAINERS_TAG:-dev}`,
  instead of building.
- `.hermes/`, `.crush/`, and `.aider.*` in the working tree are runtime
  state of agents run in the container, not project files.

## Documentation standards

All Markdown in this repository follows the `document-standards` skill
in `.agents/skills/document-standards/SKILL.md`.  Load it before
editing any documentation.  Key points:

- Two spaces after a full stop.
- Wrap at 72 columns (enforced by `.markdownlint.json` MD013, tables
  exempt).
- British spelling (for example "flavour", "italicisation").
- Sentences begin with a capital letter; rephrase rather than start
  with a lower-case identifier.
- Avoid unnecessary bold or italics.

`.editorconfig`: 2-space indentation by default, tabs for `*.sh`, LF
line endings, and trailing whitespace preserved in Markdown.

## CHANGELOG and commits

- `CHANGELOG.md` uses `* Added:` / `* Changed:` / `* Fixed:` bullets
  under `## [Unreleased][]`, with agent names as reference links
  (for example `[Cline][]`) defined in a block near the bottom.
  Releases are date-named (`20260904`) and tagged; compare links are
  at the end of the file.  Entries usually say whether a change
  "applies to the root multi-stage image and the standalone `<agent>/`
  build".
- Commit subjects for agent changes are prefixed with the agent name:
  `Cline: Upgrade to version 3.0.65`, `Herdr: Pin version to 0.8.2`.
  Some history uses `fixup!` commits intended for later autosquash.
- `.vscode/settings.json` holds a cSpell word list; add new technical
  terms there if they are flagged.

## Before committing

Before making any commit, review the intended changes and update
relevant documentation so that it is in line with those changes.  Leave
unaffected documentation unchanged.

If the project has a changelog, update it automatically for every commit
to describe the changes, following its existing format and conventions.
If no changelog exists, do not create one unless explicitly instructed.

Verify that relevant documentation updates and the update to any
existing changelog are included in the commit, and that unrelated
changes are not.  Keep commit-message attribution separate.

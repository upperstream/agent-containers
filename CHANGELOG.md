# Changelog

## [Unreleased][]

* Added:
  * Add an agent skill for documentation standards.
* Changed:
  * [Codex CLI][]:
    * Upgrade to version 0.148.0.
    * Install `bubblewrap`, `ca-certificates`, and `curl` in Codex
      images.
    * Add the container user's `~/.local/bin` directory to the
      image-wide `PATH`, allowing `codex` to be run directly.
  * [GitHub Copilot CLI][]:
    * Upgrade to version 1.0.80
  * [Crush][]:
    * Upgrade to v0.87.0.
    * Use precompiled package rather than compiling source code.
  * Update documentation standards:
    * Allow a line in GFM table to exceeds the line length limit.
    * Make markdownlint configuration consistent with the
      `document-standards` agent skill.
  * Update `README.md` files in accordance to the latest documentation
    standards.

## [20260817][]

* Changed:
  * Codex CLI:
    * Upgrade to v0.147.0.
    * Keep installed bundle inside `$HOME/.codex` directory.
    * Move `codex` executable into `$HOME/.local/bin` directory, which
      is now included in `PATH` environment variable.
    * Update document.
  * [Hermes Agent][]: Suppress verbose output during installation.
* Fixed:
  * Codex CLI: The following bundled executables were not installed:
    * `codex-code-mode-host`
    * `apply_patch`
    * `applypatch`
    * `codex-execve-wrapper`
    * `codex-linux-sandbox`
  * Hermes Agent: `HERMES_VERSION` did not work for tag name.

## [20260815][]

* Changed
  * Upgrade Hermes Agent to v2026.8.13.
    * Replace `HERMES_COMMIT` with `HERMES_VERSION` for selecting the
      Hermes branch or tag.
    * Remove `HERMES_NODE_VERSION` because Node.js is automatically
      installed by the Hermes installer.
    * Install Hermes and its runtime dependencies through the updated
      source-based installation flow, including `uv` and the CUA driver.
    * Document extracting the preinstalled Hermes home directory before
      mounting it for persistent configuration, credentials, and
      sessions.

## [20260807][]

* Changed
  * Upgrade Hermes Agent to v2026.8.3.
    * Introduce `HERMES_COMMIT` to specify commit hash to install Hermes
      Agent with.
    * Introduce `HERMES_NODE_VERSION` to specify [Node.js][] version for
      Hermes Agent.
    * Use Node.js v22.23.2 for Hermes Agent.

## [20260801][]

* Changed
  * Upgrade [Node.js][] for [OpenWiki][] to v24.18.1.

## [20260731][]

* Added
  * Add Hermes Agent.
* Changed
  * Upgrade Node.js to v24.18.1 mitigating vulnerabilities.  See
    [Node.js v24.18.1 release notes](https://nodejs.org/en/blog/release/v24.18.1)
    for details.
  * Change directory name for OpenWiki from `openwiki` to
    `openwiki-agent` because OpenWiki Repository Mode creates files in
    `openwiki` directory by default.
  * Use Node.js v22.14.0 for OpenWiki in order to properly install
    `better-sqlite3`.

[Codex CLI]: https://learn.chatgpt.com/docs/codex/cli
  "CLI – Codex | OpenAI Developers"
[Crush]: https://github.com/charmbracelet/crush
  "charmbracelet/crush: Glamourous agentic coding for all 💘"
[GitHub Copilot CLI]: https://github.com/features/copilot/cli
  "GitHub Copilot CLI"
[Hermes Agent]: https://hermes-agent.nousresearch.com/
  "Hermes Agent | Nous Research"
[Node.js]: https://nodejs.org/ "Node.js — Run JavaScript Everywhere"
[OpenWiki]: https://github.com/langchain-ai/openwiki
  "langchain-ai/openwiki: OpenWiki is a CLI that writes and maintains agent documentation for your codebase."

## [20260711][]

* Initial release.

[Unreleased]: https://github.com/upperstream/agent-containers/compare/20260815...HEAD
[20260817]: https://github.com/upperstream/agent-containers/compare/20260815...20260817
[20260815]: https://github.com/upperstream/agent-containers/compare/20260807...20260815
[20260807]: https://github.com/upperstream/agent-containers/compare/20260801...20260807
[20260801]: https://github.com/upperstream/agent-containers/compare/20260731...20260801
[20260731]: https://github.com/upperstream/agent-containers/compare/20260711...20260731
[20260711]: https://github.com/upperstream/agent-containers/releases/tag/20260711

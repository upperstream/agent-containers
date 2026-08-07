# Changelog

## [20260807][]

* Changed
  * Upgrade [Hermes Agent][] to v2026.8.3.
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

[Hermes Agent]: https://hermes-agent.nousresearch.com/
  "Hermes Agent | Nous Research"
[Node.js]: https://nodejs.org/ "Node.js — Run JavaScript Everywhere"
[OpenWiki]: https://github.com/langchain-ai/openwiki
  "langchain-ai/openwiki: OpenWiki is a CLI that writes and maintains agent documentation for your codebase."

## [20260711][]

* Initial release.

[20260807]: https://github.com/upperstream/agent-containers/compare/20260801...20260807
[20260801]: https://github.com/upperstream/agent-containers/compare/20260731...20260801
[20260731]: https://github.com/upperstream/agent-containers/compare/20260711...20260731
[20260711]: https://github.com/upperstream/agent-containers/releases/tag/20260711

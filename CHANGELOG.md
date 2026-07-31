# Changelog

## [20260731][]

* Added
  * Add [Hermes Agent][].
* Changed
  * Upgrade [Node.js][] to v24.18.1 mitigating vulnerabilities.  See
    [Node.js v24.18.1 release notes](https://nodejs.org/en/blog/release/v24.18.1)
    for details.
  * Change directory name for [OpenWiki][] from `openwiki` to
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

[20260731]: https://github.com/upperstream/agent-containers/compare/20260711...20260731
[20260711]: https://github.com/upperstream/agent-containers/releases/tag/20260711

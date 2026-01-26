# Data Tool Suite (DTS)

A web-based development environment for dbt projects with Claude AI integration.

## Installation

```bash
# Add the tap
brew tap Big-Time-Data/dts

# Install DTS (as a cask)
brew install --cask Big-Time-Data/dts/dts
```

## What's Included

- **dts_server** (aliased as `dts`): Web IDE server with embedded React frontend
- **dts_mcp**: MCP server for Claude Code integration

## Quick Start

### Start the Web IDE

```bash
dts
```

Then open http://localhost:8080 in your browser.

### Claude Plugin Setup

After installing DTS, set up the Claude Code plugin:

```bash
claude plugin install "$(brew --caskroom)/dts/latest/"
```

This enables Claude Code to interact with your dbt projects through MCP tools.

## Legacy CLI (v0.18.x)

If you need the legacy command-line interface for diff/clone operations:

```bash
brew install Big-Time-Data/dts/dts-legacy
```

The legacy CLI is installed as `dts-legacy` to avoid conflicts with the new DTS.

## Upgrading

```bash
brew update && brew upgrade --cask dts
```

## Uninstalling

```bash
brew uninstall --cask dts
```

## More Information

- [Big Time Data](https://bigtimedata.io/)

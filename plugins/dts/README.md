# DTS Query Workflow Plugin

Claude Code plugin for LLM-observable data exploration workflows. Orchestrates reasoning, query execution, interpretation, and annotation handling through the DTS MCP server.

## Features

- **Commands**: `/query`, `/explore-data`, `/validate`, `/annotations`, `/dts-prime`
- **Auto-initialization**: `dts-prime` runs at session start to establish schema context
- **LLM Observability**: All queries tracked with intent, reasoning recorded via observer
- **Cross-environment**: Compare dev vs prod with fully-qualified table names

## Local Development Setup

### 1. Build dts_mcp

```bash
cd dts-backend/
go build -o dts_mcp ./cmd/dts_mcp
```

### 2. Add dts_mcp to PATH

Either add to your shell profile:
```bash
export PATH="$PATH:/path/to/dts-backend"
```

Or symlink to a directory already on PATH:
```bash
ln -s /path/to/dts-backend/dts_mcp /usr/local/bin/dts_mcp
```

### 3. Install Plugin Globally

```bash
ln -s /path/to/dts-backend/claude-plugin ~/.claude/plugins/query-workflow
```

This makes the plugin available in all projects. Alternatively, for project-specific installation:
```bash
cd /path/to/your/dbt/project
mkdir -p .claude/plugins
ln -s /path/to/dts-backend/claude-plugin .claude/plugins/query-workflow
```

### 4. Verify Setup

Start a new Claude Code session in your dbt project. You should see:
- `dts-prime` auto-run at session start
- Schema context displayed (dev and prod database.schema)

## Testing Auto-Invocation

Try these prompts WITHOUT using `/query`:

```
"Why are orders down this week?"
"Tell me about the customers table"
"How does my dev model compare to prod?"
"Check if there are any nulls in order_id"
```

The LLM should proactively use the query workflow based on the activation triggers in SKILL.md.

## Commands

| Command | Description |
|---------|-------------|
| `/query <model>` | Start a query workflow against a model or topic |
| `/explore-data <model>` | Rich exploration with data quality checks |
| `/validate <model> against <source>` | Validate data against expectations/CSV/prod |
| `/annotations` | Check for pending human annotations |
| `/dts-prime` | Re-initialize schema context |

## Production Installation

```bash
brew tap btd/dts
brew install dts
```

Then install the plugin from the Claude Code marketplace (coming soon).

## Requirements

- dts_mcp binary on PATH
- dbt project with `dbt_project.yml` and accessible `profiles.yml`
- Database credentials configured in dbt profiles

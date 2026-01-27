# DTS Query Workflow Plugin

Claude Code plugin for LLM-observable data exploration workflows. Orchestrates reasoning, query execution, interpretation, and annotation handling through the DTS MCP server.

## Features

- **Commands**: `/query`, `/explore-data`, `/validate`, `/annotations`, `/dts-prime`
- **Auto-initialization**: `dts-prime` runs at session start to establish schema context
- **LLM Observability**: All queries tracked with intent, reasoning recorded via observer
- **Cross-environment**: Compare dev vs prod with fully-qualified table names

## Commands

| Command | Description |
|---------|-------------|
| `/query <model>` | Start a query workflow against a model or topic |
| `/explore-data <model>` | Rich exploration with data quality checks |
| `/validate <model> against <source>` | Validate data against expectations/CSV/prod |
| `/annotations` | Check for pending human annotations |
| `/dts-prime` | Re-initialize schema context |

## Requirements

- dbt project with `dbt_project.yml` and accessible `profiles.yml`
- Database credentials configured in dbt profiles

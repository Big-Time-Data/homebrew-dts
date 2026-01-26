---
description: Initialize database/schema context at session start for fully-qualified table names
argument-hint: [--force]
---

# DTS Prime Command

Establishes database and schema context at session start by auto-detecting dev and prod targets from dbt configuration. This context is referenced by other commands like `/query` and `/explore-data` for fully-qualified table names.

## Arguments

- **--force**: Skip auto-detection and prompt for manual input

## Examples

```
/dts-prime                # Auto-detect from dbt config
/dts-prime --force        # Manually specify database.schema pairs
```

---

## Detection Workflow

### Step 1: Find dbt Project Configuration

Look for `dbt_project.yml` in the current directory or parent directories:

```
1. Search for dbt_project.yml starting from current directory
2. Extract the `profile` name from the file
3. If not found, proceed to Step 4 (manual input)
```

**Example dbt_project.yml:**
```yaml
name: analytics
profile: 'analytics'
...
```

### Step 2: Locate profiles.yml

The profiles.yml location varies. Use `dbt debug --config-dir` to find it:

```bash
dbt debug --config-dir
# Output: To view your profiles.yml file, run:
# open /Users/alice/.dbt
```

**Common locations (in order of precedence):**
1. `DBT_PROFILES_DIR` environment variable
2. Current directory (`./profiles.yml`)
3. Default: `~/.dbt/profiles.yml`

**Detection steps:**
```
1. Run: dbt debug --config-dir (parse output for profiles directory)
2. If dbt not available, check $DBT_PROFILES_DIR
3. Check current directory for profiles.yml
4. Fall back to ~/.dbt/profiles.yml
5. If none found, proceed to manual input
```

### Step 3: Parse Target Configuration

Read profiles.yml and extract database/schema for each target:

**Example profiles.yml structure:**
```yaml
analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      database: ANALYTICS_DEV
      schema: DEV_{{ env_var('USER') | upper }}
      ...
    prod:
      type: snowflake
      database: ANALYTICS
      schema: MARTS
      ...
```

**Dev Target:**
- Extract `database` and `schema` fields
- Resolve Jinja templates (e.g., `{{ env_var('USER') }}` -> actual username)
- Result: `DATABASE.SCHEMA` (e.g., `ANALYTICS_DEV.DEV_ADOVEN`)

**Prod Target:**
- Extract `database` and `schema` fields
- Note: Prod may use a different database entirely, not just a different schema
- Result: `DATABASE.SCHEMA` (e.g., `ANALYTICS.MARTS`)

**Multi-Schema Projects:**
Some projects use multiple schemas in prod (e.g., by domain). To detect:
1. Check dbt_project.yml for custom schema configurations
2. Look for `+schema:` overrides in model configs
3. Scan models/ directory structure for schema hints
4. Common patterns: `ANALYTICS.MARTS`, `ANALYTICS.STAGING`, `ANALYTICS.FINANCE`

### Step 4: Handle Detection Failure

If auto-detection fails at any step, prompt the user ONCE:

```
AskUserQuestion:
  questions:
    - question: "What's your dev database.schema? (e.g., ANALYTICS_DEV.DEV_ADOVEN)"
      header: "Dev Target"
      options:
        - label: "Enter manually"
          description: "Provide in DATABASE.SCHEMA format"

    - question: "What are your prod database.schema(s)? (comma-separated if multiple)"
      header: "Prod Target(s)"
      options:
        - label: "Enter manually"
          description: "e.g., ANALYTICS.MARTS or ANALYTICS.MARTS, ANALYTICS.FINANCE"
```

### Step 5: Store and Output Context

Store the detected/entered context for the session and output a summary:

```markdown
## Schema Context Loaded

**Dev**: `ANALYTICS_DEV.DEV_ADOVEN`
**Prod**:
- `ANALYTICS.MARTS`
- `ANALYTICS.FINANCE`

This context will be used for:
- Fully-qualified table names in queries
- Environment-aware data comparisons
- Source-to-target validation
```

---

## Context Usage by Other Commands

Other commands should reference this schema context:

| Command | Usage |
|---------|-------|
| `/query` | Use prod schemas for data exploration queries |
| `/explore-data` | Default to prod; support `--dev` flag for dev schema |
| Data comparisons | Compare dev vs prod using respective schemas |

**Example fully-qualified reference:**
```sql
-- Instead of:
SELECT * FROM orders

-- Use:
SELECT * FROM ANALYTICS.MARTS.orders
-- or for dev:
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
```

---

## Output Format

On successful completion, return:

```markdown
## DTS Prime: Context Initialized

| Environment | Database.Schema |
|-------------|-----------------|
| Dev | `ANALYTICS_DEV.DEV_ADOVEN` |
| Prod | `ANALYTICS.MARTS` |
| Prod | `ANALYTICS.FINANCE` |

**Profile**: analytics
**Profiles Location**: ~/.dbt/profiles.yml
**Detection**: auto-detected | manual

Ready for queries. Use `/query` or `/explore-data` to begin.
```

---

## Error Scenarios

| Scenario | Response |
|----------|----------|
| No dbt_project.yml found | Proceed to manual input |
| `dbt debug --config-dir` fails | Check env var, then common locations |
| Profile not found in profiles.yml | Proceed to manual input |
| profiles.yml not found anywhere | Proceed to manual input |
| Invalid format entered | Re-prompt with DATABASE.SCHEMA format hint |

---

## Session Persistence

The schema context is session-scoped:
- Stored in memory for the duration of the session
- Other commands can reference it without re-detection
- Use `--force` to re-initialize if schemas change during session

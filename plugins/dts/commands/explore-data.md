---
description: Explore data with rich context, visualizations, and data quality analysis
argument-hint: <model_or_topic> [--deep] [--quality] [--issue <issue-id>]
---

# Explore Data Command

A richer version of `/query` designed for open-ended data exploration. Automatically includes data quality checks and visualization suggestions.

## Arguments

- **$ARGUMENTS**: The model name, topic, or question to explore
- **--deep**: Include full lineage analysis and related models
- **--quality**: Run comprehensive data quality checks
- **--issue**: Link this workflow to an issue tracker ID (e.g., `data-tools-123`).
  When provided, all observer calls include this reference for traceability.

## Environment

The agent determines which environment(s) to query based on the task:
- **Exploration** → dev (default)
- **Production analysis** → prod
- **Validation/comparison** → both dev and prod

Schema context is established by `dts-prime` at session start. Always use fully-qualified table names (e.g., `ANALYTICS.MARTS.orders`).

## Examples

```
/explore-data orders                    # Basic exploration of orders model
/explore-data orders --deep             # Include upstream/downstream analysis
/explore-data "customer behavior"       # Explore a topic across models
/explore-data inventory --quality       # Focus on data quality
/explore-data orders --issue data-tools-456  # Link to issue tracker
```

---

## Exploration Framework

This command follows a structured exploration approach:

### 1. Model Discovery

Understand what data is available:

```
# Find relevant models
dbt_list(selector: "<topic>")

# Get lineage context
dbt_lineage(node: "<model>", direction: "both")

# Get schema details
db_get_schemata(level: "columns", table: "<model>")
```

Record your initial understanding:
```
observer_context(
  context_type: "reasoning",
  content: "Exploring $ARGUMENTS. Available models: [...]. Starting with [model] because [reason].",
  tags: ["exploration", "<topic>"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

### 2. Overview Analysis

Always start with high-level metrics:

**Volume and Recency:**
```sql
SELECT
  COUNT(*) as total_rows,
  MIN(created_at) as earliest_record,
  MAX(created_at) as latest_record,
  MAX(updated_at) as last_update
FROM <model>
```

**Key Distributions:**
```sql
SELECT
  <categorical_column>,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as pct
FROM <model>
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10
```

### 3. Data Quality Scan (Default)

Always include basic quality checks:

**Null Analysis:**
```sql
SELECT
  COUNT(*) as total,
  COUNT(<column_1>) as has_col1,
  COUNT(<column_2>) as has_col2,
  -- etc for key columns
FROM <model>
```

**Recency Check:**
```sql
SELECT
  CASE
    WHEN MAX(created_at) < CURRENT_DATE - INTERVAL '7 days' THEN 'stale'
    WHEN MAX(created_at) < CURRENT_DATE - INTERVAL '1 day' THEN 'delayed'
    ELSE 'current'
  END as freshness_status
FROM <model>
```

### 4. Deep Analysis (if --deep)

When deep exploration is requested:

**Upstream Dependencies:**
```
dbt_lineage(node: "<model>", direction: "upstream")
# Then explore each upstream model for data quality issues
```

**Downstream Impact:**
```
dbt_lineage(node: "<model>", direction: "downstream")
# Identify which downstream models would be affected by issues
```

**Cross-Model Joins:**
```sql
-- Check join integrity with parent tables
SELECT
  COUNT(*) as total,
  COUNT(b.id) as matched,
  COUNT(*) - COUNT(b.id) as orphaned
FROM <model> a
LEFT JOIN <parent_model> b ON a.<fk_column> = b.id
```

### 5. Data Quality Focus (if --quality)

When quality focus is requested:

**Duplicate Detection:**
```sql
SELECT
  <natural_key_columns>,
  COUNT(*) as occurrences
FROM <model>
GROUP BY <natural_key_columns>
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20
```

**Value Range Validation:**
```sql
SELECT
  '<column>' as column_name,
  MIN(<column>) as min_val,
  MAX(<column>) as max_val,
  AVG(<column>) as avg_val,
  COUNT(CASE WHEN <column> < 0 THEN 1 END) as negative_count,
  COUNT(CASE WHEN <column> IS NULL THEN 1 END) as null_count
FROM <model>
```

**Referential Integrity:**
```sql
SELECT
  '<foreign_key>' as fk_column,
  COUNT(*) as total,
  COUNT(CASE WHEN <foreign_key> IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM <ref_table> WHERE id = <foreign_key>)
             THEN 1 END) as orphaned
FROM <model>
```

---

## Output Structure

Exploration results should be comprehensive:

```markdown
## Data Exploration: $ARGUMENTS

**Issue**: `<issue-id>` (if --issue provided)

### Model Overview
- **Table**: <schema.table>
- **Rows**: <count>
- **Date Range**: <earliest> to <latest>
- **Freshness**: <status>

### Key Metrics
| Metric | Value |
|--------|-------|
| Total records | X |
| Unique <entity> | Y |
| Date range | A to B |

### Data Quality Summary
| Check | Status | Details |
|-------|--------|---------|
| Completeness | <status> | <X>% of records have all required fields |
| Freshness | <status> | Last update: <date> |
| Duplicates | <status> | <N> potential duplicates found |
| Orphans | <status> | <N> records missing foreign keys |

### Distribution Analysis
<key categorical breakdowns>

### Visualizations
- [Chart 1]: <description>
- [Chart 2]: <description>

### Lineage Context (if --deep)
- **Upstream**: <models>
- **Downstream**: <models>

### Issues Found
- <issue 1>
- <issue 2>

### Recommendations
- <recommendation 1>
- <recommendation 2>
```

---

## Visualization Suggestions

Always suggest visualizations for:

1. **Time trends** (if date columns exist):
```json
{"chart_type": "line", "x_column": "date", "y_column": "count", "title": "Volume Over Time"}
```

2. **Category distributions**:
```json
{"chart_type": "bar", "x_column": "category", "y_column": "count", "title": "Distribution by Category"}
```

3. **Quality metrics**:
```json
{"chart_type": "table", "columns": ["check", "status", "value"], "title": "Data Quality Summary"}
```

---

## Comparison to /query

| Aspect | /query | /explore-data |
|--------|--------|---------------|
| Focus | Answer specific question | Open-ended exploration |
| Quality checks | Only if relevant | Always included |
| Visualizations | When helpful | Always suggested |
| Lineage | If needed | Included with --deep |
| Output | Targeted findings | Comprehensive overview |

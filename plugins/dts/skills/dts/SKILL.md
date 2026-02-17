---
name: dts
description: Data Tool Suite - LLM-observable workflows for dbt project data exploration
version: 1.1.0
tags: [dbt, observability, data-analysis, dts]
activation:
  - when: "user asks about data, models, or tables"
  - when: "user wants to explore or analyze data"
  - when: "user asks 'why' questions about metrics"
  - when: "user requests validation or comparison between environments"
  - when: "user mentions dbt model names or database tables"
---

# DTS Query Workflow

This skill provides a structured workflow for executing and interpreting database queries with full LLM observability. All reasoning, queries, and interpretations are tracked via the DTS observer system for later review and human annotation.

## Quick Start

When exploring data or answering questions about dbt models:

1. **Think first** - Record your reasoning with `observer_context`
2. **Query with intent** - Execute queries with `db_exec` including why you're running them
3. **ALWAYS interpret** - Record what you learned with `db_interpret` **(REQUIRED)**
4. **Check for feedback** - Look for human annotations with `observer_get_annotations`

## Environment Context

The `dts-prime` command (auto-runs at session start) establishes schema context from dbt configuration. This context is critical for writing correct queries.

### Available Variables

After `dts-prime` runs, you have access to:

| Variable | Description | Example |
|----------|-------------|---------|
| `dev_schema` | Your development database.schema | `ANALYTICS_DEV.DEV_ADOVEN` |
| `prod_schemas` | Production database.schema(s) | `ANALYTICS.MARTS`, `ANALYTICS.FINANCE` |

### Query Patterns by Environment

**Dev Only** (testing your changes):
```sql
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders LIMIT 100
```

**Prod Only** (production analysis):
```sql
SELECT * FROM ANALYTICS.MARTS.orders LIMIT 100
```

**Cross-Environment** (comparing dev to prod):
```sql
SELECT 'dev' as env, COUNT(*) as row_count
FROM ANALYTICS_DEV.DEV_ADOVEN.orders
UNION ALL
SELECT 'prod' as env, COUNT(*) as row_count
FROM ANALYTICS.MARTS.orders
```

### Always Use Fully-Qualified Names

**Do this:**
```sql
SELECT * FROM ANALYTICS.MARTS.orders
```

**Not this:**
```sql
SELECT * FROM orders  -- Relies on session context, will fail
```

See [references/ENVIRONMENTS.md](references/ENVIRONMENTS.md) for detailed patterns.

## Issue Context

When working on a tracked issue (GitHub, Linear, Jira, etc.), include the issue reference for traceability.

### Detecting Issue Reference

At workflow start, check for issue references in the conversation:
- Look for patterns: `data-tools-xxx`, `PROJ-123`, `#456`, or explicit issue mentions
- Store the issue reference for the session
- If no issue is mentioned, omit `issue_ref` - it's optional

### Passing Issue Reference

When an issue is active, include `issue_ref` in observer calls:

```
db_exec(
  sql: "SELECT ...",
  intent: "...",
  issue_ref: "data-tools-yf9"  # Link query to issue
)

observer_context(
  context_type: "reasoning",
  content: "...",
  issue_ref: "data-tools-yf9"  # Link reasoning to issue
)
```

### Return Summary

When returning results, include the issue reference:

```markdown
## Query Workflow Summary

**Issue**: `data-tools-yf9` - Update SKILL.md with env, issue, activation triggers
**Session ID**: abc-123
...
```

## When to Use This Workflow

This workflow should be used **proactively** when data exploration is needed. Don't wait for explicit `/query` commands.

### Activate When

- User asks about data, models, or tables
- User wants to explore or analyze data
- User asks "why" questions about metrics (e.g., "why did orders drop?")
- User requests validation or comparison between environments
- User mentions dbt model names or database tables
- User asks about data quality or discrepancies

### How to Activate

When you recognize these patterns, proactively engage:

```
"I'll investigate this using the query workflow. Let me first understand the data model..."
```

Then proceed with the phases: Context Loading → Reasoning → Query → Interpret → Iterate → Return.

### Don't Wait For

- Explicit `/query` command
- User asking you to "use the query workflow"
- Permission to explore data

If the user's question involves data, start the workflow.

## Available MCP Tools

The DTS MCP server provides these tools for the workflow:

### Context & Reasoning Tools

| Tool | Purpose |
|------|---------|
| (auto-init) | Database connection auto-initializes on first query |
| `dbt_list` | List dbt nodes with selection criteria |
| `dbt_lineage` | Get upstream/downstream lineage for a model |
| `db_get_schemata` | Get schema, table, and column information |

### Query Execution Tools

| Tool | Purpose |
|------|---------|
| `db_exec` | Execute SQL with intent tracking |
| `db_interpret` | Record interpretation of query results |
| `observer_context` | Record reasoning, plans, or observations |
| `observer_get_annotations` | Retrieve human feedback |

---

## Workflow Phases

### Phase 1: Context Loading

Before querying, gather context about the data environment:

```
# Database connection auto-initializes on first query - no explicit load needed!

# Get lineage for relevant models
dbt_lineage(node: "model_name", direction: "both")

# Get schema details
db_get_schemata(level: "columns", schema: "schema_name", table: "table_name")

# Check for pending annotations from previous sessions
observer_get_annotations()
```

### Phase 2: Reasoning (Recorded)

Before generating SQL, document your reasoning:

```
observer_context(
  context_type: "reasoning",
  content: "To understand why orders decreased, I need to:
    1. Compare this week to last week
    2. Check by product category
    3. Look for any data quality issues",
  tags: ["domain:orders", "analysis:trend"]
)
```

**Context Types:**
- `reasoning` - Your thought process and decision logic
- `plan` - Intended sequence of actions
- `observation` - Insights or findings without immediate action

### Phase 3: Query Execution

Execute queries with full context tracking:

```
db_exec(
  sql: "SELECT date, COUNT(*) as order_count FROM orders WHERE date >= '2024-01-01' GROUP BY date",
  intent: "Get daily order counts to identify when the decrease started",
  tags: ["domain:orders", "analysis:trend"]
)
```

**Returns:**
```json
{
  "query_id": "abc-123-def",
  "columns": ["date", "order_count"],
  "rows": [...],
  "status": "success",
  "_hint": "Record your analysis with db_interpret(query_id: \"abc-123-def\")"
}
```

The `query_id` links all subsequent operations (interpretation, annotations) to this query.

> **IMPORTANT**: After analyzing query results, you MUST call `db_interpret` to record your interpretation. This is required for observability - skipping this step means your analysis cannot be reviewed or annotated by humans.

### Phase 4: Interpretation (Recorded)

After receiving results, record your interpretation:

```
db_interpret(
  query_id: "abc-123-def",
  interpretation: "Orders dropped 23% starting January 15th, coinciding with the website redesign launch. The decrease is concentrated in mobile orders.",
  visualization_hints: [
    {
      "chart_type": "line",
      "x_column": "date",
      "y_column": "order_count",
      "title": "Daily Order Trend"
    }
  ],
  tags: ["orders:trend", "viz:line"],
  issue_ref: "data-tools-yf9"  # Include if working on a tracked issue (GitHub, Linear, etc.)
)
```

**Visualization Hint Types:**
- `line` - Time series, trends
- `bar` - Comparisons, categories
- `pie` - Proportions, distributions
- `table` - Detailed breakdowns

**Tag Guidelines:**

Use namespaced tags to keep interpretations organized and searchable. Limit to **2-3 tags** per interpretation.

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `domain:` | Data domain being analyzed | `domain:orders`, `domain:users`, `domain:billing` |
| `analysis:` | Type of analysis | `analysis:trend`, `analysis:comparison`, `analysis:anomaly` |
| `viz:` | Visualization type | `viz:line`, `viz:bar`, `viz:table` |
| `quality:` | Data quality focus | `quality:nulls`, `quality:duplicates` |
| `period:` | Time period focus | `period:weekly`, `period:nov-2024` |

**Good tags:**
- `domain:teamwork`, `analysis:trend`, `period:nov-2024`
- `domain:orders`, `analysis:comparison`, `viz:bar`

**Avoid:**
- Redundant tags: `november-analysis`, `feature-breakdown`, `engagement-analysis`
- Over-specific: `dashboard-requirements`, `weekly-engagement`
- Too many tags: more than 3 per interpretation

### Phase 5: Iteration Decision

Decide whether to continue investigating or return results:

**Continue when:**
- Results are incomplete or raise new questions
- Data quality issues need investigation
- User's question isn't fully answered

**Stop when:**
- Question is fully answered
- Maximum query depth reached (default: 5 queries)
- Blocking feedback received (e.g., reviewer says to stop)

Document your decision:

```
observer_context(
  context_type: "observation",
  content: "Initial analysis shows mobile orders down 23%. Need to investigate:
    1. Mobile vs desktop breakdown
    2. Whether specific pages are affected
    Proceeding with follow-up queries.",
  tags: ["domain:orders", "analysis:comparison"]
)
```

### Phase 6: Return to Main Thread

When returning results, provide a structured summary:

```markdown
## Query Workflow Summary

### Session Context
- Session ID: [from observer]
- Queries Executed: 3
- Models Analyzed: orders, customers, products

### Key Findings
- Orders dropped 23% starting January 15th
- Mobile orders most affected (-31%)
- Desktop orders relatively stable (-8%)

### Data Quality Notes
- 47 orders missing customer_id (0.3% of total)

### Suggested Follow-ups
- Investigate mobile checkout conversion rates
- Check for correlating support tickets

### Pending Actions
- [ ] Review findings with product team
- [ ] Check mobile analytics data
```

---

## Annotation Handling

Human annotations (comments) can arrive at any time. Check for them:

1. **At workflow start** - Previous session feedback
2. **Before major decisions** - Recent feedback
3. **At workflow end** - Final review

```
observer_get_annotations(pending_only: true)
```

Read the comment content to determine the appropriate response:
- If it suggests a correction → re-evaluate approach, possibly re-run queries
- If it provides context → acknowledge and incorporate
- If it validates findings → note increased confidence
- If it says to stop → halt current approach, ask for guidance

Example handling:

```
# Check for annotations
annotations = observer_get_annotations(pending_only: true)

for annotation in annotations:
    observer_context(
      context_type: "reasoning",
      content: f"Received feedback: {annotation.content}. Evaluating response.",
      tags: ["feedback-received"]
    )
    # Determine response based on comment content
```

---

## Best Practices

### Query Design
- Start broad, then narrow down
- Include relevant filters in WHERE clause
- Use appropriate aggregations for the question
- Limit result sets for exploration (LIMIT 100)

### Interpretation
- State findings clearly and quantitatively
- Note any assumptions or limitations
- Suggest visualizations that highlight key patterns
- Flag data quality concerns

### Context Recording
- Be specific about reasoning
- Link related queries through tags
- Document decision points
- Include enough context for human reviewers

### Error Handling
- If query fails, log with `observer_context` type "observation"
- Try alternative approaches
- Return partial results with clear error description
- Don't silently ignore failures

---

## Reference Files

For detailed guidance on specific topics:

- [references/QUERY_PATTERNS.md](references/QUERY_PATTERNS.md) - SQL patterns for data exploration
- [references/INTERPRETATION.md](references/INTERPRETATION.md) - How to interpret query results
- [references/VISUALIZATION.md](references/VISUALIZATION.md) - Chart selection guidelines
- [references/ANNOTATION_TYPES.md](references/ANNOTATION_TYPES.md) - Handling different feedback types

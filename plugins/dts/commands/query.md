---
description: Start a query workflow against a dbt model or data topic
argument-hint: <model_or_topic> [question...] [--issue <issue-id>]
---

# Query Command

Execute a complete query workflow with LLM observability. This command orchestrates context loading, reasoning, query execution, interpretation, and annotation checking.

## Arguments

- **$ARGUMENTS**: The model name, topic, or question to investigate
- **--issue**: Link this workflow to a beads/issue tracker ID (e.g., `data-tools-123`).
  When provided, all observer calls include this reference for traceability.

## Environment

The agent determines which environment(s) to query based on the task:
- **Exploration** → dev (default)
- **Production analysis** → prod
- **Validation/comparison** → both dev and prod

Schema context is established by `dts-prime` at session start. Always use fully-qualified table names (e.g., `ANALYTICS.MARTS.orders`).

## Examples

```
/query orders                          # Explore the orders model
/query "why are orders down this week" # Answer a specific question
/query customers churn                 # Investigate customer churn
/query orders --issue data-tools-123   # Link queries to issue tracker
```

---

## Workflow Execution

### Step 1: Check for Previous Feedback

The database connection auto-initializes on first query - no explicit load needed.

```
1. Call observer_get_annotations to check for pending feedback from previous sessions
2. If annotations exist, acknowledge them before proceeding
```

### Step 2: Gather Model Context

Based on the target argument:

**If model name:**
```
1. Call dbt_lineage(node: "<model>", direction: "both") to understand relationships
2. Call db_get_schemata(level: "columns", table: "<model>") for column details
```

**If question or topic:**
```
1. Call dbt_list to find relevant models
2. Call db_get_schemata for schema overview
3. Identify which models are most relevant to the question
```

### Step 3: Document Your Plan

Before any queries, record your investigation plan:

```
observer_context(
  context_type: "plan",
  content: "Investigation plan for: $ARGUMENTS

  1. [First query purpose]
  2. [Second query purpose]
  3. [Expected outcome]",
  tags: ["<topic>", "query-plan"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

### Step 4: Execute Query Loop

For each query needed:

**4a. Record reasoning:**
```
observer_context(
  context_type: "reasoning",
  content: "Running this query because...",
  tags: ["<topic>"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

**4b. Execute query:**
```
db_exec(
  sql: "<your SQL>",
  intent: "<brief description of why>",
  tags: ["<topic>", "<query-type>"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

**4c. Interpret results:**
```
db_interpret(
  query_id: "<from db_exec result>",
  interpretation: "<what you learned>",
  visualization_hints: [
    {"chart_type": "<type>", "x_column": "<col>", "y_column": "<col>", "title": "<title>"}
  ],
  tags: ["<insight-type>"]
)
```

**4d. Decide: continue or return**
- If question not fully answered: continue to next query
- If max queries reached (5): return with partial results
- If blocking annotation received: stop and address

### Step 5: Check for Annotations

Before returning, check if any annotations arrived during execution:

```
observer_get_annotations(pending_only: true)
```

Handle any feedback before finalizing.

### Step 6: Return Summary

Provide a structured summary to the main thread:

```markdown
## Query Workflow Complete

**Issue**: `<issue-id>` (if --issue provided)
**Session**: <session-id>
**Topic**: $ARGUMENTS

### Results Summary
- <key finding 1>
- <key finding 2>
- <key finding 3>

### Queries Executed
1. **<intent-1>**: <brief result>
2. **<intent-2>**: <brief result>

### Visualizations Suggested
- <chart-1>: <what it shows>

### Data Quality Notes
- <any issues found>

### Recommended Follow-ups
- <suggestion-1>
- <suggestion-2>

### Human Review Requested
- [ ] <item needing review>
```

---

## Error Handling

**If query fails:**
1. Log error with `observer_context(context_type: "observation", content: "Query failed: <error>")`
2. Attempt alternative approach if possible
3. Return partial results with clear error description

**If no relevant data found:**
1. Document what was searched
2. Suggest alternative approaches
3. Ask user for clarification if needed

**If rate limited or timeout:**
1. Return what was gathered so far
2. Note where to resume

---

## Annotation Response

If annotations (comments) are received during workflow, read the content and determine the appropriate response:

- If it suggests a correction → acknowledge, adjust approach, re-run affected queries
- If it provides context → incorporate into interpretation
- If it asks a question → address before continuing

---

## Output Format

The workflow should return enough context for the main thread to:
1. Understand what was investigated
2. Know what queries were run and why
3. See the key findings and interpretations
4. Know what follow-up actions are suggested
5. Identify if any human review is needed

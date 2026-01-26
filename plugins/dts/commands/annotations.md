---
description: Check for and handle pending human annotations from the observer
argument-hint: [--all] [--session <id>] [--query <id>]
---

# Annotations Command

Retrieve and process human feedback (comments) from the observer system.

## Arguments

- **--all**: Show all annotations, not just pending
- **--session <id>**: Filter to specific session
- **--query <id>**: Filter to specific query

## Examples

```
/annotations                           # Check pending annotations
/annotations --all                     # Show all annotations
/annotations --query abc-123           # Annotations for specific query
/annotations --session current         # Current session only
```

---

## Workflow

### Step 1: Retrieve Annotations

Fetch pending annotations from the observer:

```
observer_get_annotations(pending_only: true)
```

If specific filters requested:
```
observer_get_annotations(
  session_id: "<session_id>",  # if --session provided
  query_id: "<query_id>"       # if --query provided
)
```

### Step 2: Process Comments

For each annotation, acknowledge and incorporate the feedback:

```
observer_context(
  context_type: "observation",
  content: "Reviewer feedback: <annotation_content>",
  tags: ["feedback-received"]
)
```

Determine appropriate response based on comment content:
- If it suggests a correction → offer to re-run affected queries
- If it provides context → note for future analysis
- If it asks a question → respond directly

### Step 3: Return Summary

Provide a summary of all annotations processed:

```markdown
## Annotation Summary

### Pending Annotations: <count>

### Comments

#### Comment #1
- **Query**: abc-123 ("Check weekly orders")
- **Reviewer**: Alex
- **Content**: "Should exclude test orders"
- **Suggested Action**: Re-run with filter `WHERE is_test = false`

#### Comment #2
- **Query**: def-456 ("Revenue breakdown")
- **Reviewer**: Sarah
- **Content**: "Good analysis, matches finance report"

### Recommended Actions
1. Re-run query abc-123 with test order filter
2. No other action required
```

---

## Handling No Annotations

If no pending annotations exist:

```markdown
## Annotation Check Complete

No pending annotations found.

**Session**: <current_session_id>
**Queries in session**: <count>
**Last check**: <timestamp>

All previous analyses are awaiting review. To request feedback, share the observer dashboard with reviewers.
```

---

## Annotation Lifecycle

```
Query executed
    │
    ▼
Results viewed in Observer UI
    │
    ▼
Human adds comment
    │
    ▼
Annotation stored (pending)
    │
    ▼
/annotations retrieves it ◄─── You are here
    │
    ▼
Process and respond
    │
    ▼
Mark as delivered
```

---

## Integration with Other Commands

After processing annotations:

- **If correction suggested**: Run `/query` again with adjustments
- **If context provided**: Note for `/explore-data` or next `/query`

Example flow:

```
User: /annotations
Assistant: Found 1 comment - "Exclude test accounts from analysis"

User: /query customers
Assistant: Running analysis with test accounts excluded based on previous feedback...
```

---

## Error Handling

**If observer not initialized:**
> Observer not available. Please ensure DTS is configured with observer enabled.

**If session not found:**
> Session <id> not found. Use `/annotations --all` to see all annotations or start a new query workflow.

**If no annotations table:**
> No annotations have been recorded yet. Annotations are created when reviewers add feedback through the Observer UI.

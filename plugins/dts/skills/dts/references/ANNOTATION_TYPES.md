# Handling Annotations

How to respond to human feedback (comments) from the observer.

## Overview

Annotations are comments left by human reviewers on your queries and interpretations. All annotations are of type `comment` - read the content to understand what response is needed.

---

## Common Feedback Patterns

### Corrections

**Example comments:**
- "The orders table doesn't include returns - need to join with returns table"
- "Customer count is wrong - should filter out test accounts"
- "Date filter should be fiscal year, not calendar year"

**How to respond:**

1. **Acknowledge** the feedback:
```
observer_context(
  context_type: "observation",
  content: "Received feedback: Need to exclude test accounts from customer count. Adjusting approach.",
  tags: ["feedback-response"]
)
```

2. **Re-run** affected queries with corrected approach:
```
db_exec(
  sql: "SELECT COUNT(*) FROM customers WHERE is_test = false",
  intent: "Re-count customers excluding test accounts (per feedback)",
  tags: ["feedback-rerun"]
)
```

3. **Update interpretation** with corrected findings

---

### Additional Context

**Example comments:**
- "FYI: We had a marketing campaign on Jan 15 that might explain the spike"
- "The EMEA region uses a different order system"
- "These numbers look consistent with what finance reported"

**How to respond:**

1. **Acknowledge** in your reasoning:
```
observer_context(
  context_type: "observation",
  content: "Note from reviewer: Marketing campaign on Jan 15 may explain the order spike. Incorporating this context.",
  tags: ["context-added"]
)
```

2. **Incorporate** into interpretation:
> The spike in orders on January 15th (+47%) aligns with the marketing campaign noted by the reviewer.

3. **No need to re-run queries** unless the comment reveals data gaps

---

### Validations

**Example comments:**
- "Confirmed - these numbers match our internal dashboard"
- "Good analysis, this aligns with what we expected"
- "Verified the SQL logic is correct"

**How to respond:**

1. **Note increased confidence**:
```
observer_context(
  context_type: "observation",
  content: "Analysis validated by reviewer. Confidence level: high.",
  tags: ["validated"]
)
```

2. **Note in summary:**
> **Validation:** Key findings have been reviewed and confirmed by reviewer.

---

### Stop Requests

**Example comments:**
- "This analysis is using the wrong data source entirely"
- "Stop - we can't share this data externally"
- "The question is about something different"

**How to respond:**

1. **Stop** current analysis:
```
observer_context(
  context_type: "observation",
  content: "Received feedback to stop. Requesting guidance.",
  tags: ["stopped", "needs-guidance"]
)
```

2. **Document** what was attempted and why it was stopped

3. **Request clarification** from user before proceeding

---

## Checking for Annotations

### When to Check

1. **At workflow start** - Previous session feedback
2. **After long-running queries** - Feedback may have arrived
3. **Before returning results** - Final review

### How to Check

```
# Get all pending annotations
observer_get_annotations(pending_only: true)

# Get annotations for specific query
observer_get_annotations(query_id: "abc-123")

# Get all session annotations
observer_get_annotations(session_id: "<current_session>")
```

---

## Example Annotation Handling Flow

```
# Check for annotations
annotations = observer_get_annotations(pending_only: true)

for annotation in annotations:
    # Read the comment content to determine response
    content = annotation.content.lower()

    if "stop" in content or "wrong" in content:
        # May need to stop and ask for guidance
        observer_context(
          context_type: "observation",
          content: f"Feedback received: {annotation.content}"
        )
        # Consider stopping if the feedback indicates serious issues

    elif "should" in content or "need to" in content:
        # Likely a correction - re-run affected queries
        observer_context(
          context_type: "reasoning",
          content: f"Adjusting for feedback: {annotation.content}"
        )
        # Identify and re-run affected queries

    else:
        # General context or validation
        observer_context(
          context_type: "observation",
          content: f"Reviewer feedback: {annotation.content}"
        )
```

---
description: Validate data against expectations, CSV file, or another table
argument-hint: <model> against <source> [--issue <issue-id>]
---

# Validate Command

Validate data against expectations, a reference CSV file, or another table (typically prod). Returns a structured validation report with pass/fail status for each check.

## Arguments

- **\<model\>**: The model or table to validate (e.g., `orders`, `dev.customers`)
- **against \<source\>**: What to validate against (see Validation Types below)
- **--issue**: Link this workflow to an issue tracker ID (e.g., `data-tools-123`).
  When provided, all observer calls include this reference for traceability.

## Environment

Schema context is established by `dts-prime` at session start. Always use fully-qualified table names.

For cross-environment validation, the command automatically queries both environments using the dev and prod schemas from context.

## Examples

```
/validate orders against "no nulls in order_id, >1M rows"
/validate orders against /path/to/expected.csv
/validate orders against prod
/validate dev.customers against prod.customers
/validate orders against prod --issue data-tools-123
```

---

## Validation Types

### 1. Description-Based Validation

When the source is a quoted string with expectations:

```
/validate orders against "no nulls in order_id, >1M rows, unique customer_id"
```

**Parsing expectations:**
- `no nulls in <column>` → NULL count check
- `>N rows` or `<N rows` → Row count threshold
- `unique <column>` → Uniqueness check
- `<column> between X and Y` → Range check
- `<column> in (a, b, c)` → Value set check

**Generated SQL pattern:**
```sql
SELECT
  COUNT(*) as total_rows,
  COUNT(order_id) as non_null_order_id,
  COUNT(DISTINCT customer_id) as unique_customers
FROM ANALYTICS.MARTS.orders
```

### 2. CSV File Validation

When the source is a file path:

```
/validate orders against /path/to/expected.csv
```

**Workflow:**
1. Use the Read tool to load the CSV file
2. Parse expected values (typically aggregates or sample rows)
3. Generate queries to compute actual values
4. Compare actual vs expected

**CSV formats supported:**

*Aggregate expectations:*
```csv
metric,expected
total_rows,1500000
unique_customers,45000
avg_order_value,125.50
```

*Sample row validation:*
```csv
order_id,customer_id,status,amount
12345,C001,completed,99.99
12346,C002,pending,150.00
```

### 3. Cross-Table/Environment Validation

When the source references another table or `prod`:

```
/validate orders against prod
/validate dev.customers against prod.customers
```

**Comparison queries:**

*Row count comparison:*
```sql
SELECT 'dev' as env, COUNT(*) as row_count
FROM ANALYTICS_DEV.DEV_ADOVEN.orders
UNION ALL
SELECT 'prod' as env, COUNT(*) as row_count
FROM ANALYTICS.MARTS.orders
```

*Schema comparison:*
- Column names and types match
- No missing columns in dev

*Value distribution comparison:*
```sql
WITH dev_dist AS (
  SELECT status, COUNT(*) as cnt
  FROM ANALYTICS_DEV.DEV_ADOVEN.orders
  GROUP BY status
),
prod_dist AS (
  SELECT status, COUNT(*) as cnt
  FROM ANALYTICS.MARTS.orders
  GROUP BY status
)
SELECT
  COALESCE(d.status, p.status) as status,
  d.cnt as dev_count,
  p.cnt as prod_count,
  ABS(COALESCE(d.cnt, 0) - COALESCE(p.cnt, 0)) as diff
FROM dev_dist d
FULL OUTER JOIN prod_dist p ON d.status = p.status
ORDER BY diff DESC
```

---

## Workflow Execution

### Step 1: Parse Validation Request

Determine validation type from arguments:

```
observer_context(
  context_type: "plan",
  content: "Validation plan for: <model> against <source>

  Validation type: <description|csv|cross-table>
  Checks to perform:
  1. <check-1>
  2. <check-2>
  3. <check-3>",
  tags: ["validation", "<model>"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

### Step 2: Gather Schema Context

```
1. Call db_get_schemata(level: "columns", table: "<model>") for column details
2. For cross-table: also get schema of comparison table
3. Identify key columns, data types, and constraints
```

### Step 3: Generate Validation Queries

Based on validation type, generate appropriate checks:

**Standard checks (always include):**
- Row count
- Null counts for key columns
- Primary key uniqueness

**Type-specific checks:**
- Description: Parse and generate per expectation
- CSV: Generate queries matching expected metrics
- Cross-table: Generate comparison queries

### Step 4: Execute Validation Queries

For each validation check:

```
db_exec(
  sql: "<validation SQL>",
  intent: "validate: <check description>",
  tags: ["validation", "<check-type>"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

### Step 5: Interpret Results

For each check, determine pass/fail:

```
db_interpret(
  query_id: "<from db_exec>",
  interpretation: "CHECK <PASSED|FAILED>: <details>",
  tags: ["validation-result"],
  issue_ref: "<issue-id>"  # If --issue provided
)
```

### Step 6: Return Validation Report

```markdown
## Validation Report

**Issue**: `<issue-id>` (if --issue provided)
**Model**: <model>
**Validated Against**: <source>
**Timestamp**: <datetime>

### Summary
- **Total Checks**: N
- **Passed**: X
- **Failed**: Y
- **Status**: <PASSED|FAILED>

### Check Results

| Check | Status | Expected | Actual | Details |
|-------|--------|----------|--------|---------|
| Row count | PASS | >1M | 1,523,456 | |
| No nulls in order_id | PASS | 0 | 0 | |
| Unique customer_id | FAIL | unique | 47 duplicates | See details below |

### Failed Check Details

#### Unique customer_id
**Expected**: All customer_id values unique
**Actual**: 47 duplicate customer_id values found

Sample duplicates:
| customer_id | count |
|-------------|-------|
| C12345 | 3 |
| C67890 | 2 |

**Suggested action**: Investigate duplicate customer records

### Data Quality Notes
- <any additional observations>

### Recommended Follow-ups
- [ ] <action item if checks failed>
```

---

## Validation Check Reference

### Row Count Checks

| Expectation | SQL Pattern |
|-------------|-------------|
| `>N rows` | `SELECT COUNT(*) > N as passed FROM ...` |
| `<N rows` | `SELECT COUNT(*) < N as passed FROM ...` |
| `=N rows` | `SELECT COUNT(*) = N as passed FROM ...` |
| `between N and M rows` | `SELECT COUNT(*) BETWEEN N AND M as passed FROM ...` |

### Null Checks

| Expectation | SQL Pattern |
|-------------|-------------|
| `no nulls in <col>` | `SELECT COUNT(*) - COUNT(<col>) = 0 as passed FROM ...` |
| `<X% nulls in <col>` | `SELECT 100.0 * (COUNT(*) - COUNT(<col>)) / COUNT(*) < X as passed FROM ...` |

### Uniqueness Checks

| Expectation | SQL Pattern |
|-------------|-------------|
| `unique <col>` | `SELECT COUNT(*) = COUNT(DISTINCT <col>) as passed FROM ...` |
| `unique (<col1>, <col2>)` | `SELECT COUNT(*) = COUNT(DISTINCT <col1> || <col2>) as passed FROM ...` |

### Range Checks

| Expectation | SQL Pattern |
|-------------|-------------|
| `<col> >= N` | `SELECT MIN(<col>) >= N as passed FROM ...` |
| `<col> between X and Y` | `SELECT MIN(<col>) >= X AND MAX(<col>) <= Y as passed FROM ...` |

### Referential Integrity

| Expectation | SQL Pattern |
|-------------|-------------|
| `<fk> references <table>` | `SELECT COUNT(*) = 0 as passed FROM <model> WHERE <fk> NOT IN (SELECT id FROM <table>)` |

---

## Error Handling

**If validation query fails:**
1. Log error with `observer_context(context_type: "observation", content: "Validation query failed: <error>")`
2. Mark check as ERROR (not FAIL)
3. Continue with remaining checks
4. Include error in report

**If CSV file not found:**
1. Return error asking user to verify path
2. Suggest using description-based validation instead

**If comparison table doesn't exist:**
1. Return error with available tables
2. Suggest correct table name if similar one exists

---

## Output Format

The validation report should clearly communicate:
1. Overall pass/fail status (prominent)
2. Individual check results (table format)
3. Details for any failures (actionable)
4. Suggested remediation steps

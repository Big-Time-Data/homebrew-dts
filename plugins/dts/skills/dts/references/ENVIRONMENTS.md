# Working with Environments

Understanding dev vs prod environments and how to query them effectively.

## How dts-prime Detects Schemas

The `/dts-prime` command auto-detects database and schema context from dbt configuration files.

### Detection Chain

```
dbt_project.yml → profile name → profiles.yml → target configs
```

**Step 1: Find dbt_project.yml**
```yaml
# dbt_project.yml
name: analytics
profile: 'analytics'  # ← This is the profile name
```

**Step 2: Locate profiles.yml**

Search order (first match wins):
1. `DBT_PROFILES_DIR` environment variable
2. Current directory (`./profiles.yml`)
3. Default: `~/.dbt/profiles.yml`

Use `dbt debug --config-dir` to find the active profiles directory.

**Step 3: Extract Target Configurations**
```yaml
# profiles.yml
analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      database: ANALYTICS_DEV
      schema: DEV_{{ env_var('USER') | upper }}
    prod:
      type: snowflake
      database: ANALYTICS
      schema: MARTS
```

**Result:**
- Dev: `ANALYTICS_DEV.DEV_ADOVEN`
- Prod: `ANALYTICS.MARTS`

---

## Table Naming Patterns

### Snowflake

Snowflake uses three-part fully-qualified names:

```
DATABASE.SCHEMA.TABLE
```

**Examples:**
```sql
SELECT * FROM ANALYTICS.MARTS.orders
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
```

### Other Warehouses

| Warehouse | Pattern | Example |
|-----------|---------|---------|
| Snowflake | `DATABASE.SCHEMA.TABLE` | `ANALYTICS.MARTS.orders` |
| BigQuery | `PROJECT.DATASET.TABLE` | `my-project.analytics.orders` |
| Postgres | `SCHEMA.TABLE` | `public.orders` |
| Redshift | `SCHEMA.TABLE` | `analytics.orders` |
| Databricks | `CATALOG.SCHEMA.TABLE` | `main.analytics.orders` |

---

## Environment Structure

### Typical Setup

Dev and prod often live in different databases, not just different schemas:

```
PROD                          DEV
├── ANALYTICS                 ├── ANALYTICS_DEV
│   ├── MARTS                 │   └── DEV_ADOVEN
│   │   └── orders            │       └── orders
│   ├── STAGING               │
│   │   └── stg_orders        │
│   └── FINANCE               │
│       └── fct_revenue       │
```

### Multi-Schema Prod

Production often has multiple schemas organized by domain:

| Schema | Purpose | Example Models |
|--------|---------|----------------|
| `MARTS` | Business-facing models | `orders`, `customers` |
| `STAGING` | Intermediate transforms | `stg_orders`, `stg_customers` |
| `FINANCE` | Finance-specific models | `fct_revenue`, `dim_accounts` |
| `MARKETING` | Marketing models | `fct_campaigns`, `dim_channels` |

Dev typically consolidates everything into a single schema per user.

---

## When to Query Which Environment

### Dev Only

Use dev for:
- Testing changes you're developing
- Exploring your modified models
- Debugging transformations
- Verifying your dbt runs

```sql
-- Check if your changes work
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders LIMIT 10
```

### Prod Only

Use prod for:
- Production analysis and reporting
- Understanding current state of data
- Answering business questions
- Baseline comparisons

```sql
-- Production analysis
SELECT status, COUNT(*)
FROM ANALYTICS.MARTS.orders
GROUP BY status
```

### Both Environments

Use both for:
- Validating dev changes against prod baseline
- Comparing row counts before/after changes
- Finding differences introduced by your changes
- Ensuring data consistency

---

## Cross-Environment Query Patterns

### Compare Row Counts

```sql
SELECT 'dev' as env, COUNT(*) as row_count
FROM ANALYTICS_DEV.DEV_ADOVEN.orders
UNION ALL
SELECT 'prod' as env, COUNT(*) as row_count
FROM ANALYTICS.MARTS.orders
```

### Find Rows Only in Dev (Additions)

```sql
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
EXCEPT
SELECT * FROM ANALYTICS.MARTS.orders
LIMIT 100
```

### Find Rows Only in Prod (Deletions)

```sql
SELECT * FROM ANALYTICS.MARTS.orders
EXCEPT
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
LIMIT 100
```

### Compare Aggregates

```sql
SELECT
  'dev' as env,
  COUNT(*) as total_orders,
  COUNT(DISTINCT customer_id) as unique_customers,
  SUM(amount) as total_revenue
FROM ANALYTICS_DEV.DEV_ADOVEN.orders

UNION ALL

SELECT
  'prod' as env,
  COUNT(*) as total_orders,
  COUNT(DISTINCT customer_id) as unique_customers,
  SUM(amount) as total_revenue
FROM ANALYTICS.MARTS.orders
```

### Side-by-Side Comparison

```sql
WITH dev_stats AS (
  SELECT
    status,
    COUNT(*) as count,
    SUM(amount) as revenue
  FROM ANALYTICS_DEV.DEV_ADOVEN.orders
  GROUP BY status
),
prod_stats AS (
  SELECT
    status,
    COUNT(*) as count,
    SUM(amount) as revenue
  FROM ANALYTICS.MARTS.orders
  GROUP BY status
)
SELECT
  COALESCE(d.status, p.status) as status,
  d.count as dev_count,
  p.count as prod_count,
  d.count - p.count as count_diff,
  d.revenue as dev_revenue,
  p.revenue as prod_revenue,
  d.revenue - p.revenue as revenue_diff
FROM dev_stats d
FULL OUTER JOIN prod_stats p ON d.status = p.status
ORDER BY ABS(COALESCE(d.count, 0) - COALESCE(p.count, 0)) DESC
```

---

## Common Gotchas

### Always Use Fully-Qualified Names

```sql
-- Bad: Relies on session context
SELECT * FROM orders

-- Good: Explicit and portable
SELECT * FROM ANALYTICS.MARTS.orders
```

### Dev Can Usually See Prod (Read-Only)

Most warehouse configurations grant dev users read access to prod:
- Your dev connection can query prod tables
- This enables cross-environment comparisons
- Writes are restricted to your dev schema

### Schema Case Sensitivity

| Warehouse | Case Behavior |
|-----------|---------------|
| Snowflake | Case-insensitive (stored uppercase) |
| BigQuery | Case-sensitive |
| Postgres | Case-insensitive (stored lowercase) |

```sql
-- Snowflake: These are equivalent
SELECT * FROM ANALYTICS.MARTS.orders
SELECT * FROM analytics.marts.orders

-- BigQuery: Case matters
SELECT * FROM `my-project.Analytics.Orders`  -- May fail if actual case differs
```

### Different Databases = Different Connections

If dev and prod are in separate databases, verify your connection can reach both:

```sql
-- Test prod access from dev connection
SELECT 1 FROM ANALYTICS.INFORMATION_SCHEMA.TABLES LIMIT 1
```

### Prod May Have Stale Data

Development data is refreshed by your dbt runs. Production data follows a schedule:
- Check when prod was last refreshed
- Account for data lag in comparisons
- Filter to comparable time windows

```sql
-- Filter to avoid comparing today's dev data to yesterday's prod
WHERE order_date < CURRENT_DATE
```

---

## Quick Reference

| Task | Environment | Example |
|------|-------------|---------|
| Test my changes | Dev | `ANALYTICS_DEV.DEV_ADOVEN.orders` |
| Production analysis | Prod | `ANALYTICS.MARTS.orders` |
| Validate changes | Both | UNION ALL or EXCEPT queries |
| Debug transformation | Dev | Query staging tables |
| Business reporting | Prod | Query marts tables |

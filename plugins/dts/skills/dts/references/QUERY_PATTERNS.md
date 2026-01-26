# Query Patterns for Data Exploration

Common SQL patterns for exploring data models effectively.

## Exploration Patterns

### Overview Query
Get a quick sense of the data:
```sql
SELECT
  COUNT(*) as total_rows,
  COUNT(DISTINCT customer_id) as unique_customers,
  MIN(created_at) as earliest,
  MAX(created_at) as latest
FROM orders
```

### Distribution Analysis
Understand value distributions:
```sql
SELECT
  status,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as pct
FROM orders
GROUP BY status
ORDER BY count DESC
```

### Time Series Trend
Analyze trends over time:
```sql
SELECT
  DATE_TRUNC('day', created_at) as date,
  COUNT(*) as count,
  SUM(amount) as total
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 1
ORDER BY 1
```

### Period Comparison
Compare this period to last:
```sql
SELECT
  CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 'this_week' ELSE 'last_week' END as period,
  COUNT(*) as orders,
  SUM(amount) as revenue
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '14 days'
GROUP BY 1
```

---

## Data Quality Patterns

### NULL Analysis
Find columns with missing values:
```sql
SELECT
  COUNT(*) as total,
  COUNT(customer_id) as has_customer,
  COUNT(*) - COUNT(customer_id) as missing_customer,
  ROUND(100.0 * (COUNT(*) - COUNT(customer_id)) / COUNT(*), 2) as pct_missing
FROM orders
```

### Duplicate Detection
Find potential duplicates:
```sql
SELECT
  customer_id,
  order_date,
  COUNT(*) as occurrences
FROM orders
GROUP BY customer_id, order_date
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20
```

### Orphaned Records
Find records without required relationships:
```sql
SELECT o.id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL
LIMIT 20
```

### Value Range Check
Validate expected ranges:
```sql
SELECT
  MIN(amount) as min_amount,
  MAX(amount) as max_amount,
  AVG(amount) as avg_amount,
  COUNT(CASE WHEN amount < 0 THEN 1 END) as negative_amounts,
  COUNT(CASE WHEN amount > 10000 THEN 1 END) as large_amounts
FROM orders
```

---

## Diagnostic Patterns

### Recent Changes
See most recent activity:
```sql
SELECT *
FROM orders
ORDER BY updated_at DESC
LIMIT 10
```

### Cohort Analysis
Group by acquisition cohort:
```sql
SELECT
  DATE_TRUNC('month', c.created_at) as cohort_month,
  COUNT(DISTINCT o.customer_id) as customers,
  COUNT(o.id) as orders,
  SUM(o.amount) as revenue
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY 1
ORDER BY 1
```

### Funnel Analysis
Track conversion through stages:
```sql
SELECT
  COUNT(*) as total,
  COUNT(CASE WHEN status IN ('pending', 'confirmed', 'shipped', 'delivered') THEN 1 END) as confirmed,
  COUNT(CASE WHEN status IN ('shipped', 'delivered') THEN 1 END) as shipped,
  COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
```

---

## Validation Patterns

Patterns for validating data against expectations. Use with `/validate` command.

### Row Count Validation
Verify expected row counts:
```sql
-- Validate minimum row count
SELECT
  COUNT(*) as actual_rows,
  COUNT(*) >= 1000000 as passed
FROM ANALYTICS.MARTS.orders

-- Validate row count in range
SELECT
  COUNT(*) as actual_rows,
  COUNT(*) BETWEEN 900000 AND 1100000 as passed
FROM ANALYTICS.MARTS.orders
```

### Null Check Validation
Verify no nulls in required columns:
```sql
-- Single column null check
SELECT
  COUNT(*) as total_rows,
  COUNT(*) - COUNT(order_id) as null_count,
  COUNT(*) = COUNT(order_id) as passed
FROM ANALYTICS.MARTS.orders

-- Multi-column null check
SELECT
  'order_id' as column_name,
  COUNT(*) - COUNT(order_id) as null_count
FROM ANALYTICS.MARTS.orders
UNION ALL
SELECT
  'customer_id' as column_name,
  COUNT(*) - COUNT(customer_id) as null_count
FROM ANALYTICS.MARTS.orders
```

### Uniqueness Validation
Verify primary key or unique constraints:
```sql
-- Single column uniqueness
SELECT
  COUNT(*) as total_rows,
  COUNT(DISTINCT order_id) as unique_values,
  COUNT(*) = COUNT(DISTINCT order_id) as passed
FROM ANALYTICS.MARTS.orders

-- Composite key uniqueness
SELECT
  COUNT(*) as total_rows,
  COUNT(DISTINCT customer_id || '-' || order_date) as unique_combinations,
  COUNT(*) = COUNT(DISTINCT customer_id || '-' || order_date) as passed
FROM ANALYTICS.MARTS.orders

-- Find duplicates if validation fails
SELECT
  order_id,
  COUNT(*) as occurrences
FROM ANALYTICS.MARTS.orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20
```

### Value Range Validation
Verify values fall within expected bounds:
```sql
-- Numeric range validation
SELECT
  MIN(amount) as min_value,
  MAX(amount) as max_value,
  MIN(amount) >= 0 AND MAX(amount) <= 100000 as passed
FROM ANALYTICS.MARTS.orders

-- Date range validation (no future dates)
SELECT
  MAX(created_at) as max_date,
  MAX(created_at) <= CURRENT_TIMESTAMP as passed
FROM ANALYTICS.MARTS.orders

-- Enum/allowed values validation
SELECT
  COUNT(*) as total,
  COUNT(CASE WHEN status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') THEN 1 END) as valid,
  COUNT(*) = COUNT(CASE WHEN status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') THEN 1 END) as passed
FROM ANALYTICS.MARTS.orders
```

### Referential Integrity Validation
Verify foreign key relationships:
```sql
-- All orders have valid customers
SELECT
  COUNT(*) as total_orders,
  COUNT(CASE WHEN c.id IS NULL THEN 1 END) as orphaned_orders,
  COUNT(CASE WHEN c.id IS NULL THEN 1 END) = 0 as passed
FROM ANALYTICS.MARTS.orders o
LEFT JOIN ANALYTICS.MARTS.customers c ON o.customer_id = c.id

-- Find orphaned records if validation fails
SELECT o.id, o.customer_id
FROM ANALYTICS.MARTS.orders o
LEFT JOIN ANALYTICS.MARTS.customers c ON o.customer_id = c.id
WHERE c.id IS NULL
LIMIT 20
```

---

## Cross-Environment Comparison

Patterns for comparing dev to prod. Use with `/validate against prod`.

### Row Count Comparison
Compare row counts between environments:
```sql
SELECT 'dev' as env, COUNT(*) as row_count
FROM ANALYTICS_DEV.DEV_ADOVEN.orders
UNION ALL
SELECT 'prod' as env, COUNT(*) as row_count
FROM ANALYTICS.MARTS.orders
```

### Schema Comparison
Compare column structure (Snowflake example):
```sql
SELECT
  d.column_name,
  d.data_type as dev_type,
  p.data_type as prod_type,
  CASE WHEN d.data_type = p.data_type THEN 'MATCH' ELSE 'MISMATCH' END as status
FROM ANALYTICS_DEV.INFORMATION_SCHEMA.COLUMNS d
FULL OUTER JOIN ANALYTICS.INFORMATION_SCHEMA.COLUMNS p
  ON d.column_name = p.column_name
WHERE d.table_name = 'ORDERS' AND p.table_name = 'ORDERS'
  AND d.table_schema = 'DEV_ADOVEN' AND p.table_schema = 'MARTS'
ORDER BY d.ordinal_position
```

### Data Diff - Rows Only in Dev (Additions)
Find new rows in dev not present in prod:
```sql
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
EXCEPT
SELECT * FROM ANALYTICS.MARTS.orders
LIMIT 100
```

### Data Diff - Rows Only in Prod (Deletions)
Find rows in prod missing from dev:
```sql
SELECT * FROM ANALYTICS.MARTS.orders
EXCEPT
SELECT * FROM ANALYTICS_DEV.DEV_ADOVEN.orders
LIMIT 100
```

### Data Diff - By Primary Key
More efficient comparison using keys:
```sql
-- Rows in dev but not prod
SELECT d.*
FROM ANALYTICS_DEV.DEV_ADOVEN.orders d
WHERE NOT EXISTS (
  SELECT 1 FROM ANALYTICS.MARTS.orders p
  WHERE p.order_id = d.order_id
)
LIMIT 100

-- Rows in prod but not dev
SELECT p.*
FROM ANALYTICS.MARTS.orders p
WHERE NOT EXISTS (
  SELECT 1 FROM ANALYTICS_DEV.DEV_ADOVEN.orders d
  WHERE d.order_id = p.order_id
)
LIMIT 100
```

### Aggregate Comparison
Compare summary statistics:
```sql
SELECT
  'dev' as env,
  COUNT(*) as total_orders,
  COUNT(DISTINCT customer_id) as unique_customers,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM ANALYTICS_DEV.DEV_ADOVEN.orders

UNION ALL

SELECT
  'prod' as env,
  COUNT(*) as total_orders,
  COUNT(DISTINCT customer_id) as unique_customers,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM ANALYTICS.MARTS.orders
```

### Distribution Comparison
Compare value distributions side-by-side:
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
  d.cnt - p.cnt as diff,
  ROUND(100.0 * (d.cnt - p.cnt) / NULLIF(p.cnt, 0), 2) as pct_change
FROM dev_dist d
FULL OUTER JOIN prod_dist p ON d.status = p.status
ORDER BY ABS(COALESCE(d.cnt, 0) - COALESCE(p.cnt, 0)) DESC
```

### Time-Bounded Comparison
Compare only overlapping time periods:
```sql
-- Get overlapping date range
WITH date_bounds AS (
  SELECT
    GREATEST(
      (SELECT MIN(created_at) FROM ANALYTICS_DEV.DEV_ADOVEN.orders),
      (SELECT MIN(created_at) FROM ANALYTICS.MARTS.orders)
    ) as start_date,
    LEAST(
      (SELECT MAX(created_at) FROM ANALYTICS_DEV.DEV_ADOVEN.orders),
      (SELECT MAX(created_at) FROM ANALYTICS.MARTS.orders)
    ) as end_date
)
SELECT
  'dev' as env,
  COUNT(*) as row_count
FROM ANALYTICS_DEV.DEV_ADOVEN.orders, date_bounds
WHERE created_at BETWEEN start_date AND end_date

UNION ALL

SELECT
  'prod' as env,
  COUNT(*) as row_count
FROM ANALYTICS.MARTS.orders, date_bounds
WHERE created_at BETWEEN start_date AND end_date
```

---

## Best Practices

### Always Include
- `LIMIT` clause for exploration queries (start with 100)
- Date filters to bound the query scope
- `ORDER BY` for meaningful result ordering

### Avoid
- `SELECT *` without LIMIT
- Cross joins without conditions
- Unbounded date ranges on large tables

### Query Comments
Include intent in your queries:
```sql
-- Check: Are mobile orders declining faster than desktop?
SELECT
  device_type,
  DATE_TRUNC('week', created_at) as week,
  COUNT(*) as orders
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '8 weeks'
GROUP BY 1, 2
ORDER BY 2, 1
```

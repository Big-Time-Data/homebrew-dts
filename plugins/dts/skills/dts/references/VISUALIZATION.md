# Visualization Selection Guidelines

Choose the right chart type for your data and message.

## Chart Selection Matrix

| Data Type | Purpose | Recommended Chart |
|-----------|---------|-------------------|
| Time series | Show trend | `line` |
| Categories | Compare values | `bar` |
| Parts of whole | Show composition | `pie` (if <7 categories) |
| Detailed breakdown | Exact values | `table` |
| Distribution | Show spread | `bar` (histogram) |
| Correlation | Show relationship | `line` (scatter) |

---

## Chart Type Details

### Line Chart

**Best for:** Time series, trends, continuous data

**When to use:**
- Showing change over time
- Comparing multiple series over same time period
- Highlighting trend direction

**Visualization hint format:**
```json
{
  "chart_type": "line",
  "x_column": "date",
  "y_column": "order_count",
  "title": "Daily Orders - Last 30 Days"
}
```

**Tips:**
- Use for 7+ data points
- Consider dual y-axis for different scales
- Highlight key inflection points

---

### Bar Chart

**Best for:** Categorical comparisons, discrete values

**When to use:**
- Comparing values across categories
- Showing rankings
- Period-over-period comparisons

**Visualization hint format:**
```json
{
  "chart_type": "bar",
  "x_column": "product_category",
  "y_column": "revenue",
  "title": "Revenue by Product Category"
}
```

**Tips:**
- Sort by value (largest first) unless there's natural ordering
- Limit to 10-12 bars maximum
- Use horizontal bars for long category names

---

### Pie Chart

**Best for:** Parts of a whole, proportions

**When to use:**
- Showing percentage breakdown
- When parts sum to 100%
- 6 or fewer categories

**Visualization hint format:**
```json
{
  "chart_type": "pie",
  "label_column": "status",
  "value_column": "count",
  "title": "Order Status Distribution"
}
```

**Tips:**
- Avoid if more than 6 categories
- Order slices by size
- Consider bar chart as alternative (often clearer)

---

### Table

**Best for:** Detailed data, exact values

**When to use:**
- Multiple metrics per category
- Precise values matter
- Detailed breakdown needed

**Visualization hint format:**
```json
{
  "chart_type": "table",
  "columns": ["product", "orders", "revenue", "avg_order_value"],
  "title": "Product Performance Summary"
}
```

**Tips:**
- Limit rows to keep scannable
- Right-align numbers
- Include totals row if appropriate

---

## Multiple Visualizations

For complex analyses, suggest multiple complementary charts:

```json
{
  "visualizations": [
    {
      "chart_type": "line",
      "x_column": "date",
      "y_column": "orders",
      "title": "Order Trend"
    },
    {
      "chart_type": "bar",
      "x_column": "channel",
      "y_column": "orders",
      "title": "Orders by Channel"
    }
  ]
}
```

---

## Visualization Principles

### Do
- Choose chart type based on the question being answered
- Title charts to highlight the key insight
- Label axes clearly
- Use consistent colors for same categories across charts

### Don't
- Use pie charts for more than 6 categories
- Start y-axis at non-zero without noting it
- Use 3D effects (they distort perception)
- Overcrowd with too many data series

---

## Examples by Question Type

**"What's the trend?"** → Line chart
```json
{"chart_type": "line", "x_column": "week", "y_column": "revenue", "title": "Weekly Revenue Trend"}
```

**"How do segments compare?"** → Bar chart
```json
{"chart_type": "bar", "x_column": "region", "y_column": "sales", "title": "Sales by Region"}
```

**"What's the breakdown?"** → Pie or bar
```json
{"chart_type": "pie", "label_column": "category", "value_column": "pct", "title": "Revenue Mix"}
```

**"What are the details?"** → Table
```json
{"chart_type": "table", "columns": ["product", "qty", "revenue", "margin"], "title": "Product Details"}
```

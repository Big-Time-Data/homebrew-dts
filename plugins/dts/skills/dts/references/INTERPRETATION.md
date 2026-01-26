# Interpreting Query Results

Guidelines for analyzing and explaining query results effectively.

## Interpretation Framework

### 1. State the Finding Clearly

Start with the key takeaway:

**Good:**
> Orders decreased 23% week-over-week, from 1,247 to 961.

**Avoid:**
> The data shows some changes in the orders table.

### 2. Provide Context

Compare to baselines or expectations:

> This 23% decrease is significant - the typical week-over-week variance is under 5%. The last time we saw a decrease this large was during the holiday shutdown in December.

### 3. Quantify Impact

Use specific numbers:

| Metric | Value |
|--------|-------|
| Absolute change | -286 orders |
| Percentage change | -23% |
| Revenue impact | -$28,600 (estimated) |

### 4. Note Limitations

Be explicit about data constraints:

> Note: This analysis only includes orders with status 'completed'. Pending orders (currently 47) are excluded and may affect final numbers.

---

## Common Interpretation Scenarios

### Trends

When interpreting time series:
- Identify the direction (increasing, decreasing, stable)
- Note the magnitude (slight, moderate, significant)
- Compare to historical patterns
- Look for inflection points

**Example:**
> Revenue has been declining steadily since January 15th, with a cumulative 18% drop. The decline accelerated in the past week (-8% vs -3% the week prior). This coincides with the mobile app update on January 14th.

### Distributions

When interpreting categorical breakdowns:
- Identify the dominant categories
- Note any surprises vs expectations
- Look for concentration or dispersion

**Example:**
> Three products account for 67% of revenue: Widget Pro (32%), Widget Basic (21%), and Widget Plus (14%). This concentration has increased from 58% last quarter, suggesting customers are consolidating around fewer products.

### Comparisons

When comparing periods or segments:
- State the comparison clearly
- Quantify the difference
- Test statistical significance if applicable

**Example:**
> Mobile orders (-31%) declined nearly 4x faster than desktop (-8%). This disparity suggests a mobile-specific issue rather than a general demand problem.

### Anomalies

When identifying outliers or unusual patterns:
- Describe what's unexpected
- Quantify the deviation
- Suggest possible causes

**Example:**
> Customer #4521 has 847 orders this month, which is 12 standard deviations above the mean (avg: 3.2 orders/customer). This appears to be either a test account or a data quality issue - recommend investigation.

---

## Red Flags to Highlight

Always call out:

- **Data quality issues**: NULLs, duplicates, orphaned records
- **Unexpected values**: Negatives where positives expected, future dates
- **Volume anomalies**: Sudden spikes or drops
- **Concentration risks**: Over-reliance on single customers/products
- **Trend changes**: Inflection points or reversals

---

## Interpretation Checklist

Before finalizing your interpretation:

- [ ] Did I state the main finding in the first sentence?
- [ ] Did I include specific numbers (not just "increased" or "decreased")?
- [ ] Did I compare to a relevant baseline?
- [ ] Did I note any data quality concerns?
- [ ] Did I mention what's NOT in the data?
- [ ] Did I suggest next steps if warranted?

---

## Example Full Interpretation

**Query intent:** Understand why orders are down this week

**Results:**
| period | orders | revenue |
|--------|--------|---------|
| this_week | 961 | $96,100 |
| last_week | 1,247 | $131,800 |

**Interpretation:**

> Orders decreased 23% this week (961 vs 1,247), with revenue down 27% ($96,100 vs $131,800). The larger revenue drop suggests higher-value orders were disproportionately affected.
>
> Looking at the breakdown by channel:
> - Mobile: -31% (478 → 330)
> - Desktop: -8% (769 → 631)
>
> The disparity strongly suggests a mobile-specific issue. This coincides with the iOS app update released on Monday.
>
> **Data quality note:** 12 orders are missing channel attribution and were excluded.
>
> **Recommended follow-up:**
> 1. Check mobile checkout completion rates
> 2. Review iOS app store reviews for reported issues
> 3. Compare Android vs iOS performance

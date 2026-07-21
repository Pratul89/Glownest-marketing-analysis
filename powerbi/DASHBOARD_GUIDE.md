# Power BI Dashboard Guide

Explains what each visual on the dashboard shows and how the underlying DAX measures work.
Data source: `campaigns_final.csv` (820 cleaned, deduplicated records), imported via
Get Data > Text/CSV, plus an auto-generated Calendar table for the monthly trend chart.

## DAX Measures Used

| Measure | Formula (logic) | Why |
|---|---|---|
| Total Spend | `SUM(spend_inr)` | True aggregate, not a per-row average |
| Total Revenue | `SUM(revenue_inr)` | Same reasoning |
| Total Conversions | `SUM(conversions)` | Same reasoning |
| ROAS | `DIVIDE(SUM(revenue_inr), SUM(spend_inr))` | `DIVIDE()` avoids divide-by-zero errors |
| CTR | `DIVIDE(SUM(clicks), SUM(impressions))` | Aggregate ratio, not average of row-level CTRs |
| Conversion Rate | `DIVIDE(SUM(conversions), SUM(clicks))` | Same reasoning |

Using `SUM()` of the numerator and denominator separately (rather than averaging a
pre-calculated per-row ratio) matters here — a simple average would give every campaign
equal weight regardless of its size, distorting the true overall rate.

## Visuals on the Dashboard

- **KPI Cards (6):** Total Spend, Total Revenue, ROAS, CTR, Conversion Rate, Total
  Conversions — headline numbers for the whole dataset, or filtered by whatever slicer
  selection is active.
- **Revenue by Marketing Channel (bar chart):** Compares total revenue across the 5
  channels — Google Ads leads.
- **Revenue by Region (bar chart):** Same comparison across regions — West and Central
  lead.
- **Monthly Revenue Trend (line chart):** Revenue by month across 2024, using the
  Calendar table's Month Name field for correct chronological ordering.
- **Marketing Spend by Target Audience (donut chart):** Shows how the budget is split
  across the 8 audience segments.
- **Campaign Performance (table):** Row-level detail — campaign name, channel, region,
  spend, revenue, ROAS — for drill-down investigation.
- **Slicers (4):** Region, Channel, Year, Target Audience — let the viewer filter the
  entire page interactively.

## How to Explore
Click any bar, slice, or slicer value to cross-filter the whole page (e.g. click
"Google Ads" on the channel chart to see only Google Ads campaigns across every visual).
Click the same value again, or an empty area of the chart, to clear the filter.

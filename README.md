# Swiggy Sales & Delivery Analytics | Snowflake + Power BI

> **Portfolio project / educational case study.** Not an official Swiggy corporate project. This repository documents the supplied project artifacts and a conceptual dimensional model, without claiming access to Swiggy production systems or verified business outcomes.

## Problem statement
Food-delivery operations generate data across restaurants, menus, customers, addresses, locations, orders, and delivery agents. Without a curated view, it is difficult to compare sales trends, understand restaurant and menu contributions, or monitor delivery-status distribution and agent performance.

## Business objectives
- Build a consistent **Sales Overview**: revenue, distinct orders, average order value, monthly sales, top restaurants and menu items.
- Build a **Deliveries Overview**: delivery statuses, delivery-agent counts, ratings and agent-level operational details.
- Convert operational CSV extracts into cleaned, history-aware analytical data using Snowflake.
- Make year and delivery-status filters available for business exploration.

## Architecture
```text
CSV (initial and delta files)
   -> Snowflake internal stage + CSV file format
   -> STAGE_SCH (raw/as-is tables, file audit metadata)
   -> CLEAN_SCH (typed tables, MERGE-based updates)
   -> CONSUMPTION_SCH (SCD Type 2 dimensions)
   -> Power BI (Sales Overview + Deliveries Overview)
```
Snowflake streams appear in both staging and clean layers. Source SQL includes PII classification tags and masking policies. `COPY INTO` loads data from the internal stage.

## Star schema: conceptual
```text
 CUSTOMER_DIM          CUSTOMER_ADDRESS_DIM          MENU_DIM
         \                |                        /
           \              |                      /
            +------------------------------------+
            |          ORDER_ITEM_FACT           |
            |  order_id, subtotal, status, ...   |
            +------------------------------------+
           /             |              \
    DATE_DIM      RESTAURANT_DIM       DELIVERY_AGENT_DIM
                          |
                RESTAURANT_LOCATION_DIM
```
The Power BI model contains `ORDER_ITEM_FACT`, `CUSTOMER_DIM`, `CUSTOMER_ADDRESS_DIM`, `MENU_DIM`, `RESTAURANT_DIM`, `RESTAURANT_LOCATION_DIM`, `DATE_DIM`, and `DELIVERY_AGENT_DIM`. It also contains an additional table named `Order item fact _2026-09-14-213`. **This diagram is illustrative, not a verified export of Power BI relationships.** Foreign keys, grain, cardinalities, filter directions, and SCD2 time-valid joins must be verified. The repository does not include `ORDER_ITEM_FACT` or `DATE_DIM` DDL.

## KPI dictionary
| KPI | Suggested definition | Business question |
|---|---|---|
| Total revenue | SUM eligible `ORDER_ITEM_FACT[SUBTOTAL]` | How much revenue did orders generate? |
| Total orders | DISTINCTCOUNT `ORDER_ITEM_FACT[ORDER_ID]` | How many unique orders? |
| Average order value | Total revenue / total eligible orders | How much is spent per order? |
| Monthly sales | Total revenue grouped by `DATE_DIM` year/month | How is sales performance changing? |
| Restaurant contribution | Revenue by `RESTAURANT_DIM[NAME]` | Which restaurants lead sales? |
| Top-selling items | Revenue by item name | Which items contribute most? |
| Delivery status mix | Distinct orders grouped by delivery status | What share of orders is in each status? |
| Delivery agents | Distinct delivery agent IDs | How many agents are represented? |
| Average agent rating | Mean valid `DELIVERY_AGENT_DIM[RATING]` | How is agent rating trending? |

**Important:** These are recommended definitions based on visible Power BI fields, *not* audited exported DAX measures. Verify whether subtotal reflects discounts/taxes/refunds, which statuses count as completed revenue, and whether fact rows are order-item grain. An on-time delivery rate cannot be validated using estimated time alone.

## Dashboard pages found in the PBIX
**Sales Overview** — revenue and order cards, year slicer, monthly sales trend, restaurant and item rankings, delivery-status mix, average per order, and average per item.

**Deliveries Overview** — revenue and order cards, year and status slicers, agent count, restaurant count, status/agent table, gender breakdown, and agent rating visual.

## Main data engineering features
- Snowflake **CSV file format, internal stage, and `COPY INTO`**.
- **Staging audit metadata**: file name, file modification time, file content hash/key, and copy timestamp.
- **Streams and MERGE** to process arriving changes.
- **SCD Type 2 dimensions** using effective start/end dates and current flags.
- **PII tags / masking policies** defined in SQL; deployment should verify policy attachment and access grants.

## Business challenges and approaches
1. **Fragmented entities** → separate raw, clean, and consumption schemas and dimensional reporting.
2. **Data quality and type consistency** → land as text, cast/clean downstream, validate nulls and types.
3. **Changing source records** → incremental capture with streams/MERGE, history-aware dimensions.
4. **Audit/security** → record file metadata, tag sensitive fields, verify masking and role policies.
5. **Reporting ambiguity** → document grain and precise KPI calculations.

## Repository structure
```text
sql/           Source Snowflake SQL scripts
 dashboard/    Original Power BI report (.pbix)
 docs/         KPI dictionary, assumptions, and star-schema illustration
```

## How to explore
1. Review `sql/Swiggy complete project.sql` for schema, file format, stage, tags, and masking-policy setup.
2. Review entity SQL scripts for staging tables, clean layer, streams, MERGE, and SCD2 dimension scripts.
3. Open `dashboard/Swiggy Dashboard.pbix` in Power BI Desktop and inspect the model relationships and DAX measures before publishing.
4. To execute the SQL, configure your own Snowflake environment, approved data extracts, stage paths, grants, and dependency order. These uploaded scripts are **not a verified one-click deployment**.

## Known gaps / responsible claims
- Raw CSVs, actual row counts, numerical KPI results, screenshots, and test outputs were not included.
- Fact and date table DDL, some model relationship specifications, and DAX measure definitions were not included.
- Some scripts use `CREATE OR REPLACE`, which may reset objects or streams; review before any rerun.
- This project demonstrates implementation patterns; no quantified improvements or verified real-world Swiggy results are claimed.

## Potential enhancements
Add version-controlled fact/date table DDL, tested DAX, data-quality queries, schema lineage, sample *synthetic* datasets, CI checks, screenshots, and role/access documentation. For high-quality reporting, implement as-of joins to historical dimension versions when appropriate.

## Conclusion
The project connects Snowflake incremental data processing and SCD2 modeling with a Power BI reporting layer for sales and delivery analytics. It provides a practical foundation for KPI governance and operational decision support once its missing fact/model definitions and measure rules are validated.

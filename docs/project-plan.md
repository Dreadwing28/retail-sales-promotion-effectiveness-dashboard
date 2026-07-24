# Project Plan

## Project name
Retail Sales Promotion Effectiveness Dashboard

## Objective
Build a retail analytics project that measures the impact of promotions and discounts on sales, margin, and inventory.

## Scope for version 1
1. Create source retail datasets in CSV format
2. Build SQL schema for dimensions and fact tables
3. Load and transform data using SQL
4. Run Python data quality checks
5. Build KPI queries
6. Create Power BI dashboard pages

## Main dimensions
1. dim_product
2. dim_store
3. dim_date
4. dim_promotion

## Main fact tables
1. fact_sales
2. fact_inventory_daily

## KPI list
1. Total Revenue
2. Total Cost
3. Margin
4. Margin Percent
5. Discount Amount
6. Discount Rate
7. Sell Through Rate
8. Stockout Rate
9. Promo Uplift Revenue
10. Promo Uplift Margin

## Dashboard pages
1. Executive Overview
2. Promotion Effectiveness
3. Store and Channel Performance
4. Inventory and Stockout Summary

## Notes
Version 1 will focus on a clean MVP build first.
Advanced semantic layer, SSAS, SSRS, and scheduler automation can be added later.

-- 02_create_dimensions.sql
-- Staging table for raw Kaggle data

CREATE TABLE retail_dw.stg_sales_raw (
    store_id          INT          NOT NULL,
    product_id        INT          NOT NULL,
    date              DATE         NOT NULL,
    category          NVARCHAR(50) NOT NULL,
    price             DECIMAL(18,2) NOT NULL,
    promotion_active  NVARCHAR(3)  NOT NULL,
    discount_percent  INT          NOT NULL,
    units_sold        INT          NOT NULL,
    inventory_level   INT          NOT NULL,
    day_of_week       NVARCHAR(20) NOT NULL
);
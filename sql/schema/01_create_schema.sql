-- 01_create_schema.sql
-- Retail Sales Promotion Effectiveness - schema creation

CREATE SCHEMA retail_dw;
GO

-- Dimension tables

CREATE TABLE retail_dw.dim_store (
    store_id       INT        NOT NULL PRIMARY KEY,
    store_name     NVARCHAR(100) NULL,
    region         NVARCHAR(50)  NULL,
    channel        NVARCHAR(20)  NULL
);

CREATE TABLE retail_dw.dim_product (
    product_id     INT           NOT NULL PRIMARY KEY,
    category       NVARCHAR(50)  NULL,
    brand          NVARCHAR(50)  NULL,
    list_price     DECIMAL(18,2) NULL
);

CREATE TABLE retail_dw.dim_date (
    date_id        INT           NOT NULL PRIMARY KEY, -- YYYYMMDD
    calendar_date  DATE          NOT NULL,
    day_of_week    NVARCHAR(20)  NULL,
    month          TINYINT       NULL,
    quarter        TINYINT       NULL,
    year           SMALLINT      NULL
);

CREATE TABLE retail_dw.dim_promotion (
    promotion_id       INT           NOT NULL PRIMARY KEY,
    promotion_active   NVARCHAR(3)   NOT NULL,   -- Yes / No
    discount_percent   INT           NOT NULL,
    promotion_type     NVARCHAR(50)  NULL
);

-- Fact tables

CREATE TABLE retail_dw.fact_sales (
    fact_sales_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    store_id            INT         NOT NULL,
    product_id          INT         NOT NULL,
    date_id             INT         NOT NULL,
    promotion_id        INT         NULL,
    units_sold          INT         NOT NULL,
    price               DECIMAL(18,2) NOT NULL,
    revenue             DECIMAL(18,2) NOT NULL,
    discount_amount     DECIMAL(18,2) NOT NULL,
    discount_percent    INT          NOT NULL,
    inventory_level     INT          NOT NULL,
    CONSTRAINT fk_sales_store    FOREIGN KEY (store_id)   REFERENCES retail_dw.dim_store(store_id),
    CONSTRAINT fk_sales_product  FOREIGN KEY (product_id) REFERENCES retail_dw.dim_product(product_id),
    CONSTRAINT fk_sales_date     FOREIGN KEY (date_id)    REFERENCES retail_dw.dim_date(date_id),
    CONSTRAINT fk_sales_promo    FOREIGN KEY (promotion_id) REFERENCES retail_dw.dim_promotion(promotion_id)
);

CREATE TABLE retail_dw.fact_inventory_daily (
    fact_inventory_id   BIGINT IDENTITY(1,1) PRIMARY KEY,
    store_id            INT         NOT NULL,
    product_id          INT         NOT NULL,
    date_id             INT         NOT NULL,
    inventory_level     INT         NOT NULL,
    stockout_flag       BIT         NOT NULL DEFAULT 0,
    CONSTRAINT fk_inv_store    FOREIGN KEY (store_id)   REFERENCES retail_dw.dim_store(store_id),
    CONSTRAINT fk_inv_product  FOREIGN KEY (product_id) REFERENCES retail_dw.dim_product(product_id),
    CONSTRAINT fk_inv_date     FOREIGN KEY (date_id)    REFERENCES retail_dw.dim_date(date_id)
);
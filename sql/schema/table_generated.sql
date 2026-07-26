------------------------------------------------------------
-- 1. CREATE DATABASE
------------------------------------------------------------
IF DB_ID('RetailSalesPromotionDB') IS NULL
BEGIN
    CREATE DATABASE RetailSalesPromotionDB;
END
GO

USE RetailSalesPromotionDB;
GO

------------------------------------------------------------
-- 2. CREATE STAGING SCHEMA
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END
GO

------------------------------------------------------------
-- 3. DROP TABLES IF YOU WANT TO RE-RUN CLEANLY
------------------------------------------------------------
IF OBJECT_ID('dbo.fact_promotion_performance', 'U') IS NOT NULL DROP TABLE dbo.fact_promotion_performance;
IF OBJECT_ID('dbo.fact_inventory_daily', 'U') IS NOT NULL DROP TABLE dbo.fact_inventory_daily;
IF OBJECT_ID('dbo.fact_sales', 'U') IS NOT NULL DROP TABLE dbo.fact_sales;

IF OBJECT_ID('dbo.dim_promotion', 'U') IS NOT NULL DROP TABLE dbo.dim_promotion;
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;
IF OBJECT_ID('dbo.dim_product', 'U') IS NOT NULL DROP TABLE dbo.dim_product;
IF OBJECT_ID('dbo.dim_store', 'U') IS NOT NULL DROP TABLE dbo.dim_store;

IF OBJECT_ID('stg.retail_sales_raw', 'U') IS NOT NULL DROP TABLE stg.retail_sales_raw;
GO

------------------------------------------------------------
-- 4. CREATE STAGING TABLE
------------------------------------------------------------
CREATE TABLE stg.retail_sales_raw (
    store_id INT,
    product_id INT,
    [date] DATE,
    category VARCHAR(100),
    price DECIMAL(18,2),
    promotion_active VARCHAR(10),
    discount_percent INT,
    units_sold INT,
    inventory_level INT,
    day_of_week VARCHAR(20)
);
GO

------------------------------------------------------------
-- 5. CREATE DIMENSION TABLES
------------------------------------------------------------
CREATE TABLE dbo.dim_store (
    store_id INT NOT NULL PRIMARY KEY,
    store_name VARCHAR(100) NULL,
    region VARCHAR(100) NULL,
    channel VARCHAR(50) NULL
);
GO

CREATE TABLE dbo.dim_product (
    product_id INT NOT NULL PRIMARY KEY,
    product_name VARCHAR(100) NULL,
    category VARCHAR(100) NULL,
    brand VARCHAR(100) NULL,
    cost DECIMAL(18,2) NULL,
    list_price DECIMAL(18,2) NULL
);
GO

CREATE TABLE dbo.dim_date (
    date_id INT NOT NULL PRIMARY KEY,
    calendar_date DATE NOT NULL,
    [month] TINYINT NULL,
    [quarter] TINYINT NULL,
    [year] SMALLINT NULL,
    day_of_week VARCHAR(20) NULL,
    holiday_flag BIT NULL
);
GO

CREATE TABLE dbo.dim_promotion (
    promotion_id INT NOT NULL PRIMARY KEY,
    promotion_type VARCHAR(50) NULL,
    discount_percent INT NOT NULL,
    campaign_name VARCHAR(100) NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    promotion_active VARCHAR(10) NOT NULL
);
GO

------------------------------------------------------------
-- 6. CREATE FACT TABLES
------------------------------------------------------------
CREATE TABLE dbo.fact_sales (
    sales_id INT IDENTITY(1,1) PRIMARY KEY,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    date_id INT NOT NULL,
    promotion_id INT NOT NULL,
    qty INT NOT NULL,
    gross_sales DECIMAL(18,2) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    net_revenue DECIMAL(18,2) NOT NULL,
    cost DECIMAL(18,2) NOT NULL,
    margin DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_fact_sales_store FOREIGN KEY (store_id) REFERENCES dbo.dim_store(store_id),
    CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_id) REFERENCES dbo.dim_product(product_id),
    CONSTRAINT FK_fact_sales_date FOREIGN KEY (date_id) REFERENCES dbo.dim_date(date_id),
    CONSTRAINT FK_fact_sales_promotion FOREIGN KEY (promotion_id) REFERENCES dbo.dim_promotion(promotion_id)
);
GO

CREATE TABLE dbo.fact_inventory_daily (
    inventory_id INT IDENTITY(1,1) PRIMARY KEY,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    date_id INT NOT NULL,
    stock_on_hand INT NOT NULL,
    units_sold INT NOT NULL,
    closing_stock INT NOT NULL,
    stockout_flag BIT NOT NULL,

    CONSTRAINT FK_fact_inventory_store FOREIGN KEY (store_id) REFERENCES dbo.dim_store(store_id),
    CONSTRAINT FK_fact_inventory_product FOREIGN KEY (product_id) REFERENCES dbo.dim_product(product_id),
    CONSTRAINT FK_fact_inventory_date FOREIGN KEY (date_id) REFERENCES dbo.dim_date(date_id)
);
GO

CREATE TABLE dbo.fact_promotion_performance (
    promotion_perf_id INT IDENTITY(1,1) PRIMARY KEY,
    promotion_id INT NOT NULL,
    date_id INT NOT NULL,
    promo_revenue DECIMAL(18,2) NOT NULL,
    promo_margin DECIMAL(18,2) NOT NULL,
    promo_units_sold INT NOT NULL,

    CONSTRAINT FK_fact_promo_perf_promotion FOREIGN KEY (promotion_id) REFERENCES dbo.dim_promotion(promotion_id),
    CONSTRAINT FK_fact_promo_perf_date FOREIGN KEY (date_id) REFERENCES dbo.dim_date(date_id)
);
GO

------------------------------------------------------------
-- 7. LOAD DIMENSIONS
------------------------------------------------------------

-- dim_store
INSERT INTO dbo.dim_store (store_id, store_name, region, channel)
SELECT DISTINCT
    r.store_id,
    CONCAT('Store ', r.store_id) AS store_name,
    CASE
        WHEN r.store_id % 4 = 0 THEN 'North'
        WHEN r.store_id % 4 = 1 THEN 'South'
        WHEN r.store_id % 4 = 2 THEN 'East'
        ELSE 'West'
    END AS region,
    CASE
        WHEN r.store_id % 2 = 0 THEN 'Online'
        ELSE 'Offline'
    END AS channel
FROM stg.retail_sales_raw r;
GO

-- dim_product
INSERT INTO dbo.dim_product (product_id, product_name, category, brand, cost, list_price)
SELECT DISTINCT
    r.product_id,
    CONCAT('Product ', r.product_id) AS product_name,
    r.category,
    CONCAT('Brand ', (r.product_id % 10) + 1) AS brand,
    CAST(r.price * 0.65 AS DECIMAL(18,2)) AS cost,
    r.price AS list_price
FROM stg.retail_sales_raw r;
GO

-- dim_date
INSERT INTO dbo.dim_date (date_id, calendar_date, [month], [quarter], [year], day_of_week, holiday_flag)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), r.[date], 112)) AS date_id,
    r.[date] AS calendar_date,
    MONTH(r.[date]) AS [month],
    DATEPART(QUARTER, r.[date]) AS [quarter],
    YEAR(r.[date]) AS [year],
    r.day_of_week,
    CAST(0 AS BIT) AS holiday_flag
FROM stg.retail_sales_raw r;
GO

-- dim_promotion
;WITH promo_cte AS (
    SELECT DISTINCT
        r.promotion_active,
        r.discount_percent
    FROM stg.retail_sales_raw r
)
INSERT INTO dbo.dim_promotion (
    promotion_id,
    promotion_type,
    discount_percent,
    campaign_name,
    start_date,
    end_date,
    promotion_active
)
SELECT
    ROW_NUMBER() OVER (ORDER BY promotion_active, discount_percent) AS promotion_id,
    CASE
        WHEN discount_percent = 0 THEN 'No Promotion'
        WHEN discount_percent <= 10 THEN 'Light Discount'
        WHEN discount_percent <= 20 THEN 'Medium Discount'
        ELSE 'Heavy Discount'
    END AS promotion_type,
    discount_percent,
    CONCAT('Campaign ', ROW_NUMBER() OVER (ORDER BY promotion_active, discount_percent)) AS campaign_name,
    NULL AS start_date,
    NULL AS end_date,
    promotion_active
FROM promo_cte;
GO

------------------------------------------------------------
-- 8. LOAD FACT_SALES
------------------------------------------------------------
INSERT INTO dbo.fact_sales (
    store_id,
    product_id,
    date_id,
    promotion_id,
    qty,
    gross_sales,
    discount_amount,
    net_revenue,
    cost,
    margin
)
SELECT
    r.store_id,
    r.product_id,
    CONVERT(INT, CONVERT(VARCHAR(8), r.[date], 112)) AS date_id,
    p.promotion_id,
    r.units_sold AS qty,
    CAST(r.units_sold * r.price AS DECIMAL(18,2)) AS gross_sales,
    CAST((r.units_sold * r.price) * (r.discount_percent / 100.0) AS DECIMAL(18,2)) AS discount_amount,
    CAST((r.units_sold * r.price) * (1 - r.discount_percent / 100.0) AS DECIMAL(18,2)) AS net_revenue,
    CAST(r.units_sold * dp.cost AS DECIMAL(18,2)) AS cost,
    CAST(
        ((r.units_sold * r.price) * (1 - r.discount_percent / 100.0))
        - (r.units_sold * dp.cost)
        AS DECIMAL(18,2)
    ) AS margin
FROM stg.retail_sales_raw r
INNER JOIN dbo.dim_product dp
    ON r.product_id = dp.product_id
INNER JOIN dbo.dim_promotion p
    ON r.promotion_active = p.promotion_active
   AND r.discount_percent = p.discount_percent;
GO

------------------------------------------------------------
-- 9. LOAD FACT_INVENTORY_DAILY
------------------------------------------------------------
INSERT INTO dbo.fact_inventory_daily (
    store_id,
    product_id,
    date_id,
    stock_on_hand,
    units_sold,
    closing_stock,
    stockout_flag
)
SELECT
    r.store_id,
    r.product_id,
    CONVERT(INT, CONVERT(VARCHAR(8), r.[date], 112)) AS date_id,
    r.inventory_level AS stock_on_hand,
    r.units_sold,
    CASE
        WHEN r.inventory_level - r.units_sold < 0 THEN 0
        ELSE r.inventory_level - r.units_sold
    END AS closing_stock,
    CASE
        WHEN r.inventory_level <= 0 THEN 1
        WHEN r.inventory_level - r.units_sold <= 0 THEN 1
        ELSE 0
    END AS stockout_flag
FROM stg.retail_sales_raw r;
GO

------------------------------------------------------------
-- 10. LOAD FACT_PROMOTION_PERFORMANCE
------------------------------------------------------------
INSERT INTO dbo.fact_promotion_performance (
    promotion_id,
    date_id,
    promo_revenue,
    promo_margin,
    promo_units_sold
)
SELECT
    fs.promotion_id,
    fs.date_id,
    SUM(fs.net_revenue) AS promo_revenue,
    SUM(fs.margin) AS promo_margin,
    SUM(fs.qty) AS promo_units_sold
FROM dbo.fact_sales fs
GROUP BY
    fs.promotion_id,
    fs.date_id;
GO

------------------------------------------------------------
-- 11. VALIDATION QUERIES
------------------------------------------------------------
SELECT COUNT(*) AS stg_count
FROM stg.retail_sales_raw;
GO

SELECT COUNT(*) AS dim_store_count
FROM dbo.dim_store;
GO

SELECT COUNT(*) AS dim_product_count
FROM dbo.dim_product;
GO

SELECT COUNT(*) AS dim_date_count
FROM dbo.dim_date;
GO

SELECT COUNT(*) AS dim_promotion_count
FROM dbo.dim_promotion;
GO

SELECT COUNT(*) AS fact_sales_count
FROM dbo.fact_sales;
GO

SELECT COUNT(*) AS fact_inventory_daily_count
FROM dbo.fact_inventory_daily;
GO

SELECT COUNT(*) AS fact_promotion_performance_count
FROM dbo.fact_promotion_performance;
GO

SELECT TOP 10 *
FROM dbo.fact_sales;
GO

SELECT TOP 10 *
FROM dbo.fact_inventory_daily;
GO

SELECT TOP 10 *
FROM dbo.fact_promotion_performance;
GO
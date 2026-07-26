CREATE DATABASE RetailSalesPromotionDB;
GO

USE RetailSalesPromotionDB;
GO

CREATE SCHEMA stg;
GO

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



USE RetailSalesPromotionDB;
GO

SELECT COUNT(*) AS row_count
FROM stg.retail_sales_raw;
GO


-- Creating the core dimentisons : 
CREATE TABLE dbo.dim_store (
    store_id INT NOT NULL PRIMARY KEY,
    store_name VARCHAR(100) NULL
);

CREATE TABLE dbo.dim_product (
    product_id INT NOT NULL PRIMARY KEY,
    category   VARCHAR(100) NULL,
    list_price DECIMAL(18,2) NULL
);
GO

CREATE TABLE dbo.dim_date (
    date_id       INT        NOT NULL PRIMARY KEY, -- YYYYMMDD
    calendar_date DATE       NOT NULL,
    day_of_week   VARCHAR(20) NULL,
    month         TINYINT    NULL,
    quarter       TINYINT    NULL,
    year          SMALLINT   NULL
);
GO

CREATE TABLE dbo.dim_promotion (
    promotion_id     INT        NOT NULL PRIMARY KEY,
    promotion_active VARCHAR(3) NOT NULL,   -- Yes / No
    discount_percent INT        NOT NULL
);
GO

INSERT INTO dbo.dim_store (store_id)
SELECT DISTINCT store_id
FROM stg.retail_sales_raw;
GO



INSERT INTO dbo.dim_product (product_id, category, list_price)
SELECT DISTINCT product_id, category, price
FROM stg.retail_sales_raw;
GO


SELECT COUNT(*) FROM dbo.dim_store;
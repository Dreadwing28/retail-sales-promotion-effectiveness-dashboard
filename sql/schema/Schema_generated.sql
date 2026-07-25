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



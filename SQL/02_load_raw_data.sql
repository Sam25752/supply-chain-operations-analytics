


BULK INSERT dbo.raw_orders
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO


--insert data into customer table

BULK INSERT dbo.raw_customers
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO


BULK INSERT dbo.raw_sellers
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO



BULK INSERT dbo.raw_products
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO



BULK INSERT dbo.raw_order_items
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO



BULK INSERT dbo.raw_order_payments
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO


BULK INSERT dbo.raw_order_reviews
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001', 
    TABLOCK
);
GO


BULK INSERT dbo.raw_geolocation
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\olist_geolocation_dataset.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
);
GO



BULK INSERT dbo.raw_category_translation
FROM 'C:\Users\DELL\OneDrive\Desktop\supply-chain-operations-analytics\RAW\product_category_name_translation.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
);
GO


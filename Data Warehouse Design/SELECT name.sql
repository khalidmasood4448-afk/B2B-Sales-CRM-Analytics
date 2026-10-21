SELECT name
FROM sqlite_master
WHERE type = 'table'
AND name IN (
    'DimRegion',
    'DimDate',
    'DimProduct',
    'DimCustomer',
    'DimSalesRep',
    'FactOpportunity',
    'FactSales'
);
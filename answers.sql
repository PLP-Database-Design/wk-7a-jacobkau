--  Question 1: Transform ProductDetail table to achieve 1NF
-- Create the original table with multi-valued attribute (not normalized)
CREATE TEMPORARY TABLE ProductDetail (
    OrderID INT,
    CustomerName VARCHAR(100),
    Products VARCHAR(255)
);

-- Insert sample data
INSERT INTO ProductDetail (OrderID, CustomerName, Products) VALUES
(101, 'John Doe', 'Laptop, Mouse'),
(102, 'Jane Smith', 'Tablet, Keyboard, Mouse'),
(103, 'Emily Clark', 'Phone');

-- 1NF Transformation: Split multiple products into individual rows
-- This SELECT simulates the normalized version using a string splitter (replace below with real function or logic in your RDBMS)
-- In MySQL 8+, you can use a JSON workaround:
SELECT 
    OrderID,
    CustomerName,
    TRIM(JSON_UNQUOTE(JSON_EXTRACT(js.value, '$'))) AS Product
FROM (
    SELECT 
        OrderID,
        CustomerName,
        JSON_TABLE(
            JSON_ARRAYAGG(JSON_QUOTE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Products, ',', numbers.n), ',', -1)))), 
            "$[*]" COLUMNS(value JSON PATH "$")
        ) AS js
    FROM ProductDetail
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    ) numbers
    ON CHAR_LENGTH(Products) - CHAR_LENGTH(REPLACE(Products, ',', '')) >= numbers.n - 1
    GROUP BY OrderID, CustomerName, Products
) AS extracted;

-- Note: In production, create a proper normalized table instead of this dynamic SELECT.

--  Question 2: Transform OrderDetails table to achieve 2NF
-- Create original 1NF table with partial dependencies
CREATE TEMPORARY TABLE OrderDetails (
    OrderID INT,
    CustomerName VARCHAR(100),
    Product VARCHAR(50),
    Quantity INT
);

-- Insert sample data
INSERT INTO OrderDetails (OrderID, CustomerName, Product, Quantity) VALUES
(101, 'John Doe', 'Laptop', 2),
(101, 'John Doe', 'Mouse', 1),
(102, 'Jane Smith', 'Tablet', 3),
(102, 'Jane Smith', 'Keyboard', 1),
(102, 'Jane Smith', 'Mouse', 2),
(103, 'Emily Clark', 'Phone', 1);

-- 2NF Step 1: Create separate table for Orders to remove partial dependency of CustomerName on OrderID
CREATE TEMPORARY TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerName VARCHAR(100)
);

-- Insert unique orders
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName FROM OrderDetails;

-- 2NF Step 2: Create new OrderItems table with only full dependencies on composite key (OrderID, Product)
CREATE TEMPORARY TABLE OrderItems (
    OrderID INT,
    Product VARCHAR(50),
    Quantity INT,
    PRIMARY KEY (OrderID, Product),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Insert product-specific details
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity FROM OrderDetails;

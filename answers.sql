-- Question 1: Achieving 1NF (First Normal Form)

-- Create the original table (for demonstration purposes)
CREATE TABLE ProductDetail (
    OrderID INT,
    CustomerName VARCHAR(50),
    Products VARCHAR(255)
);

-- Insert sample data
INSERT INTO ProductDetail VALUES 
(101, 'John Doe', 'Laptop, Mouse'),
(102, 'Jane Smith', 'Tablet, Keyboard, Mouse'),
(103, 'Emily Clark', 'Phone');

-- Transform to 1NF by splitting the Products column
SELECT 
    OrderID,
    CustomerName,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Products, ',', n), ',', -1)) AS Product
FROM ProductDetail
JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) numbers
ON CHAR_LENGTH(Products) - CHAR_LENGTH(REPLACE(Products, ',', '')) >= n - 1
ORDER BY OrderID;

-- Alternative approach using a recursive CTE (for MySQL 8.0+)
WITH RECURSIVE split_products AS (
    SELECT 
        OrderID,
        CustomerName,
        Products,
        TRIM(SUBSTRING_INDEX(Products, ',', 1)) AS Product,
        SUBSTRING(Products, LENGTH(SUBSTRING_INDEX(Products, ',', 1)) + 2) AS remaining_products,
        1 AS product_count
    FROM ProductDetail
    
    UNION ALL
    
    SELECT 
        OrderID,
        CustomerName,
        Products,
        TRIM(SUBSTRING_INDEX(remaining_products, ',', 1)) AS Product,
        SUBSTRING(remaining_products, LENGTH(SUBSTRING_INDEX(remaining_products, ',', 1)) + 2) AS remaining_products,
        product_count + 1
    FROM split_products
    WHERE remaining_products != ''
)
SELECT OrderID, CustomerName, Product
FROM split_products
ORDER BY OrderID, product_count;

-- Question 2: Achieving 2NF (Second Normal Form)

-- Create the 1NF table (for demonstration purposes)
CREATE TABLE OrderDetails_1NF (
    OrderID INT,
    CustomerName VARCHAR(50),
    Product VARCHAR(50),
    Quantity INT
);

-- Insert sample data
INSERT INTO OrderDetails_1NF VALUES 
(101, 'John Doe', 'Laptop', 2),
(101, 'John Doe', 'Mouse', 1),
(102, 'Jane Smith', 'Tablet', 3),
(102, 'Jane Smith', 'Keyboard', 1),
(102, 'Jane Smith', 'Mouse', 2),
(103, 'Emily Clark', 'Phone', 1);

-- Remove partial dependencies by creating separate tables

-- Create Orders table (removes CustomerName dependency on OrderID)
CREATE TABLE Orders AS
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails_1NF;

-- Create OrderItems table (contains only full dependencies)
CREATE TABLE OrderItems AS
SELECT OrderID, Product, Quantity
FROM OrderDetails_1NF;

-- Verify the 2NF structure
SELECT 'Orders Table:' AS Table_Name;
SELECT * FROM Orders ORDER BY OrderID;

SELECT 'OrderItems Table:' AS Table_Name;
SELECT * FROM OrderItems ORDER BY OrderID, Product;

-- Alternative: Show the normalized structure in a single query
SELECT 
    o.OrderID,
    o.CustomerName,
    oi.Product,
    oi.Quantity
FROM Orders o
JOIN OrderItems oi ON o.OrderID = oi.OrderID
ORDER BY o.OrderID, oi.Product;
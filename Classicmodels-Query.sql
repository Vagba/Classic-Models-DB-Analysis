#Q1(a): Change the column names in the customers table

ALTER TABLE customers
CHANGE customerNumber customer_id INT;

ALTER TABLE customers
CHANGE contactLastName Last_Name VARCHAR(50),
CHANGE contactFirstName First_Name VARCHAR(50);

SELECT *
FROM CUSTOMERS
LIMIT 10;

#Q1(b): Change the column names in the employees table

ALTER TABLE employees
CHANGE employeeNumber employee_id INT;

SELECT *
FROM employees;

#Q2: Which country has the most customers?

SELECT country,
       COUNT(country) AS Country_occurrences
FROM customers
GROUP BY 1
ORDER BY 2 DESC;

#Q3: Maximum, minimum, and mean of customer's credit limit

SELECT MAX(creditLimit) AS max_Credit,
       MIN(creditLimit) AS min_Credit, 
       ROUND(AVG(creditLimit), 2) AS avg_Credit
FROM customers;

#Q4: Where every employee reports

SELECT employees.firstName AS employee_firstName,
       employees.lastName AS employee_lastName,
       CONCAT(manager.firstName, " ", manager.lastName) AS reportsTo,
       manager.jobTitle
FROM employees
INNER JOIN employees manager ON manager.employee_id = employees.reportsTo;

#Q5: Top 5 customers ordered by total amount (descending)

SELECT customers.customer_id,
       CONCAT(customers.First_Name, " ", customers.Last_Name) AS Customer_Name,
       SUM(payments.amount) AS total_amount
FROM customers
JOIN payments ON customers.customer_id = payments.customerNumber
GROUP BY 1
ORDER BY 1 DESC
LIMIT 5;

#Q6: Group customers by the number of orders and count the number of customers for a specific date range

SELECT total_orders AS orders_bucket, COUNT(customerNumber) AS cust_num
FROM (
    SELECT customerNumber, COUNT(orderNumber) AS total_orders
    FROM orders
    WHERE orderDate BETWEEN '2003-01-01' AND '2004-01-01'
    GROUP BY customerNumber
) AS total_orders
GROUP BY 1 
ORDER BY 1 ASC;

#Q7: Percentage of orders in different statuses
SELECT ROUND(100.0 * SUM(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) / COUNT(*), 2) AS shipped_perc,
       ROUND(100.0 * SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*), 2) AS resolved_perc,
       ROUND(100.0 * SUM(CASE WHEN status NOT IN ('shipped', 'Resolved') THEN 1 ELSE 0 END) / COUNT(*), 2) AS other_status_perc
FROM orders;

#Q8: Time taken from order to shipment

SELECT orders.orderNumber,
       prod.productName,
       DATEDIFF(shippedDate, orderDate) AS date_diff
FROM orders
JOIN orderdetails details ON details.orderNumber = orders.orderNumber
JOIN products prod ON prod.productCode = details.productCode
ORDER BY 3 DESC;

#Q9: Comments from customers (unhappy and happy)

SELECT customers.customer_id,
       CONCAT(customers.First_Name, ' ', customers.Last_Name) AS customer_name,
       prod.ProductName,
       (CASE WHEN cust_comments.comments LIKE '%difficult%' OR cust_comments.comments LIKE '%cautions%' THEN cust_comments.comments END) AS difficult_comments,
       (CASE WHEN cust_comments.comments LIKE '%satisfied%' OR cust_comments.comments LIKE '%happy%' THEN cust_comments.comments END) AS happy_comments
FROM (
    SELECT orders.customerNumber,
           orders.comments AS comments
    FROM orders
    WHERE comments LIKE '%difficult%' OR comments LIKE '%cautions%'
    
    UNION
    
    SELECT orders.customerNumber,
           orders.comments AS comments
    FROM orders
    WHERE comments LIKE '%satisfied%' OR comments LIKE '%happy%'
) AS cust_comments
JOIN customers ON customers.customer_id = cust_comments.customerNumber
JOIN orders ON orders.customerNumber = cust_comments.customerNumber
JOIN orderdetails details ON details.orderNumber = orders.orderNumber
JOIN products prod ON prod.productCode = details.productCode;

#Q10: Relationship between sold units and stock

SELECT p.productCode,
       p.productName,
       p.quantityInStock,
       SUM(quantityOrdered) AS total_sold_units
FROM products p
JOIN orderdetails d ON p.productCode = d.productCode
GROUP BY 1, 2, 3;

#Q11: Relationship between customers and sales reps

SELECT e.employee_id,
       CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
       COUNT(c.salesRepEmployeeNumber) AS total_sales_by_srp
FROM employees e
JOIN customers c ON e.employee_id = c.salesRepEmployeeNumber    
GROUP BY 1, 2
ORDER BY 3 DESC;

#Q12: Every manager and the number of members in their team

SELECT e.employee_id,
       CONCAT(e.firstName, ' ', e.lastName) AS manager_name,
       e.jobTitle,
       COUNT(*) AS members_team
FROM employees e
JOIN employees m ON e.employee_id = m.reportsTo
GROUP BY 1, 2, 3;

#Q13: The best manager and total sales per team 

WITH Teamsalesdata AS (
    SELECT e.reportsTo AS manager_id,
           CONCAT(e.firstName, ' ', e.lastName) AS employee_name,
           COUNT(c.salesRepEmployeeNumber) AS total_sales_by_srp
    FROM employees e
    JOIN customers c ON c.salesRepEmployeeNumber = e.employee_id
    GROUP BY 1, 2
),
Managerteam AS (
    SELECT m.employee_id AS manager_id,
           CONCAT(m.firstName, ' ', m.lastName) AS manager_name,
           COUNT(*) AS members_count
    FROM employees m
    JOIN employees e ON m.employee_id = e.reportsTo
    GROUP BY 1, 2
)
SELECT mnt.manager_id,
       mnt.manager_name,
       mnt.members_count,
       SUM(tsd.total_sales_by_srp) AS total_sales_by_team
FROM Managerteam mnt
JOIN Teamsalesdata tsd ON mnt.manager_id = tsd.manager_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

#Q14: Create a view for product summary

CREATE VIEW ProductSummaryView AS
SELECT o.productCode,
       p.productName,
       SUM(o.quantityOrdered * o.priceEach) AS product_summary
FROM orderdetails o
JOIN products p ON o.productCode = p.productCode
GROUP BY 1;

SELECT *
FROM ProductSummaryView;

#Q15: Create indexes for optimization

CREATE INDEX customers_city_idx ON customers(city);
CREATE INDEX orders_customerNumber ON orders(customerNumber);

#Q16: Count total orders for Madrid city
SELECT city,
       COUNT(orderNumber) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customerNumber
WHERE city = 'Madrid'
GROUP BY 1;

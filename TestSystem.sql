-- 1. Data Structure Testing

-- 1.1 Check all required tables exist
SELECT table_name
FROM user_tables
WHERE table_name IN ('CUSTOMER', 'STAFF', 'SUPPLIER', 'MENUITEM', 'ORDERS', 'ORDERDETAIL')
ORDER BY table_name;

-- 1.2 Check columns and data types
DESCRIBE CUSTOMER;
DESCRIBE STAFF;
DESCRIBE SUPPLIER;
DESCRIBE MENUITEM;
DESCRIBE ORDERS;
DESCRIBE ORDERDETAIL;

-- 1.3 Check foreign keys and constraints
SELECT constraint_name, constraint_type, table_name
FROM user_constraints
WHERE table_name IN ('CUSTOMER', 'STAFF', 'SUPPLIER', 'MENUITEM', 'ORDERS', 'ORDERDETAIL');

-- 2. Insert / Preview Testing
SELECT * FROM CUSTOMER;
SELECT * FROM STAFF;
SELECT * FROM SUPPLIER;
SELECT * FROM MENUITEM;
SELECT * FROM ORDERS;
SELECT * FROM ORDERDETAIL;

-- 3. Constraint Testing and Data Integrity Testing

-- 3.1 Primary Key Constraint Testing
INSERT INTO CUSTOMER (CUS_ID, CUS_NAME)
VALUES ('C311', 'Duplicate Customer');
-- Expected Result: Rejected due to PK constraint violation

-- 3.2 NOT NULL Constraint Testing
INSERT INTO STAFF (STA_ID, STA_NAME)
VALUES ('S999', NULL);
-- Expected Result: Rejected due to NOT NULL constraint violation

-- 3.3 Foreign Key Constraint Testing
INSERT INTO ORDERS (ORD_ID, CUS_ID, STA_ID, ORD_DATE, ORD_TOTALAMOUNT)
VALUES ('O999', 'C999', 'S124', SYSDATE, 100);
-- Expected Result: Rejected due to foreign key constraint violation

-- 3.4 Business Rule Constraint Testing (Quantity Validation)
INSERT INTO ORDERDETAIL (ORD_ID, ITEM_ID, QUANTITY)
VALUES ('O001', 'I001', -5);
-- Expected Result: Rejected due to CHECK constraint violation (quantity must be positive)

-- 4. Query / Functionality Testing

-- 4.1. Check STAFF with zero orders
SELECT s.STA_ID, s.STA_NAME, COUNT(o.ORD_ID) AS ORDERS_HANDLED
FROM STAFF s
LEFT JOIN ORDERS o ON s.STA_ID = o.STA_ID
GROUP BY s.STA_ID, s.STA_NAME
HAVING COUNT(o.ORD_ID) = 0;

-- 4.2 Low stock MENUITEMs (edge case)
SELECT ITEM_ID, ITEM_NAME, ITEM_STOCKQTY
FROM MENUITEM
WHERE ITEM_STOCKQTY <= 10
ORDER BY ITEM_STOCKQTY ASC;

-- 4.3 Check that each order's calculated subtotal matches ITEM_PRICE * QUANTITY
SELECT o.ORD_ID,
       o.ORD_TOTALAMOUNT AS RECORDED_TOTAL,
       SUM(od.QUANTITY * m.ITEM_PRICE) AS CALCULATED_TOTAL,
       CASE 
           WHEN o.ORD_TOTALAMOUNT = SUM(od.QUANTITY * m.ITEM_PRICE) THEN 'MATCH'
           ELSE 'MISMATCH'
       END AS CHECK_RESULT
FROM ORDERS o
JOIN ORDERDETAIL od ON o.ORD_ID = od.ORD_ID
JOIN MENUITEM m ON od.ITEM_ID = m.ITEM_ID
GROUP BY o.ORD_ID, o.ORD_TOTALAMOUNT
ORDER BY o.ORD_ID;

-- 4.4 Customers who spent above average (edge case)
SELECT CUS_ID, CUS_NAME
FROM CUSTOMER c
WHERE EXISTS (
    SELECT 1
    FROM ORDERS o
    WHERE o.CUS_ID = c.CUS_ID
    GROUP BY o.CUS_ID
    HAVING SUM(o.ORD_TOTALAMOUNT) > (
        SELECT AVG(SUM(o2.ORD_TOTALAMOUNT))
        FROM ORDERS o2
        GROUP BY o2.CUS_ID
    )
);

-- 4.5 Staff top-selling item correctness check
SELECT s.STA_ID, s.STA_NAME, COUNT(DISTINCT od.ITEM_ID) AS ITEMS_SOLD
FROM STAFF s
JOIN ORDERS o ON s.STA_ID = o.STA_ID
JOIN ORDERDETAIL od ON o.ORD_ID = od.ORD_ID
GROUP BY s.STA_ID, s.STA_NAME
HAVING COUNT(DISTINCT od.ITEM_ID) > 0;

-- 4.6 Daily sales sum check
SELECT TO_CHAR(o.ORD_DATE,'YYYY-MM-DD') AS SALE_DATE,
       SUM(od.QUANTITY * m.ITEM_PRICE) AS DAILY_SALES
FROM ORDERS o
JOIN ORDERDETAIL od ON o.ORD_ID = od.ORD_ID
JOIN MENUITEM m ON od.ITEM_ID = m.ITEM_ID
GROUP BY TO_CHAR(o.ORD_DATE,'YYYY-MM-DD')
ORDER BY SALE_DATE;

-- 4.7 Supplier inventory value sanity check
SELECT s.SUP_ID, s.SUP_NAME,
       SUM(m.ITEM_STOCKQTY * m.ITEM_PRICE) AS TOTAL_VALUE
FROM SUPPLIER s
LEFT JOIN MENUITEM m ON s.SUP_ID = m.SUP_ID
GROUP BY s.SUP_ID, s.SUP_NAME
ORDER BY TOTAL_VALUE DESC;

-- 5. Delete / Referential Integrity Testing

-- 5.1 Referential Integrity Deletion Testing
DELETE FROM CUSTOMER
WHERE CUS_ID = 'C311';
-- Expected Result: Rejected due to FK constraint if orders exist

-- 5.2 Orphan Record Integrity Verification
SELECT od.ORD_ID
FROM ORDERDETAIL od
LEFT JOIN ORDERS o ON od.ORD_ID = o.ORD_ID
WHERE o.ORD_ID IS NULL;
-- Expected Result: No orphan records











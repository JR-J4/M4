/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: первинний ключ (PRIMARY KEY), зовнішній ключ (FOREIGN KEY), залежна таблиця
 *
 * PRIMARY KEY — колонка (найчастіше int), яка однозначно ідентифікує рядок:
 *   Customers.CustomerID, Orders.OrderID, Products.ProductID.
 * FOREIGN KEY — колонка залежної таблиці, яка посилається на PRIMARY KEY іншої:
 *   Orders.CustomerID -> Customers.CustomerID.
 * Натуральний ключ — колонка, унікальна «від природи» (email, ІПН, номер паспорта).
 *   Її рідко роблять первинним ключем: такі дані змінюються.
 *
 * Синтаксис (оголошення в CREATE TABLE):
 *   id          INT PRIMARY KEY AUTO_INCREMENT,
 *   customer_id INT,
 *   FOREIGN KEY (customer_id) REFERENCES customers (id)
 *
 * Аналогія: номер паспорта — первинний ключ людини. Номер паспорта в договорі
 * оренди — зовнішній ключ: договір «залежить» від людини і посилається на неї.
 *
 * Де застосовують:
 *   - саме за PK = FK зʼєднують таблиці у JOIN;
 *   - FOREIGN KEY не дає вставити замовлення неіснуючому клієнту (цілісність даних);
 *   - PK автоматично має індекс — пошук за id миттєвий.
 */


-- ============================================================
-- 1. Які первинні ключі є у w3schools
-- ============================================================
-- Сценарій: новий розробник хоче зрозуміти, як ідентифікується кожна сутність.

SELECT TABLE_NAME, COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'w3schools'
  AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME;
-- | TABLE_NAME   | COLUMN_NAME   |
-- | Categories   | CategoryID    |
-- | Customers    | CustomerID    |
-- | Employees    | EmployeeID    |
-- | OrderDetails | OrderDetailID |
-- | Orders       | OrderID       |
-- | Products     | ProductID     |
-- | Shippers     | ShipperID     |
-- | Suppliers    | SupplierID    |


-- ============================================================
-- 2. Які таблиці залежні і від кого
-- ============================================================
-- Сценарій: перед написанням JOIN треба знати, за якими колонками зʼєднувати.
-- REFERENCED_TABLE_NAME — «головна» таблиця, TABLE_NAME — залежна.

SELECT
    TABLE_NAME             AS dependent_table,
    COLUMN_NAME            AS fk_column,
    REFERENCED_TABLE_NAME  AS main_table,
    REFERENCED_COLUMN_NAME AS pk_column
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'w3schools'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
-- | dependent_table | fk_column  | main_table | pk_column  |
-- | OrderDetails    | OrderID    | Orders     | OrderID    |
-- | OrderDetails    | ProductID  | Products   | ProductID  |
-- | Orders          | CustomerID | Customers  | CustomerID |
-- | Orders          | EmployeeID | Employees  | EmployeeID |
-- | Orders          | ShipperID  | Shippers   | ShipperID  |
-- | Products        | CategoryID | Categories | CategoryID |
-- | Products        | SupplierID | Suppliers  | SupplierID |
-- Схема звʼязків:
--   Customers ─┐
--   Employees ─┼─< Orders ─< OrderDetails >─ Products >─┬─ Categories
--   Shippers  ─┘                                        └─ Suppliers


-- ============================================================
-- 3. Ключі однієї таблиці — коротко
-- ============================================================
-- Сценарій: подивитися, як оголошена таблиця Orders.

SHOW CREATE TABLE Orders;
-- CREATE TABLE `Orders` (
--   `OrderID` int NOT NULL AUTO_INCREMENT,
--   `CustomerID` int DEFAULT NULL,
--   `EmployeeID` int DEFAULT NULL,
--   `OrderDate` date DEFAULT NULL,
--   `ShipperID` int DEFAULT NULL,
--   PRIMARY KEY (`OrderID`),
--   KEY `CustomerID` (`CustomerID`),
--   KEY `EmployeeID` (`EmployeeID`),
--   KEY `ShipperID` (`ShipperID`),
--   CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `Customers` (`CustomerID`),
--   CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`EmployeeID`) REFERENCES `Employees` (`EmployeeID`),
--   CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`ShipperID`) REFERENCES `Shippers` (`ShipperID`)
-- ) ENGINE=InnoDB ...
-- KEY — індекси на FK-колонках: MySQL створює їх, щоб JOIN за ними працював швидко.


-- ============================================================
-- 4. FOREIGN KEY захищає цілісність
-- ============================================================
-- Сценарій: хтось намагається створити замовлення для клієнта з id 999,
-- якого не існує. База даних не дозволить — рядок не буде вставлено.
-- (Розкоментуйте, щоб побачити помилку. Детально про INSERT — у лекції 6.)

-- INSERT INTO Orders (OrderID, CustomerID, EmployeeID, OrderDate, ShipperID)
-- VALUES (99999, 999, 1, '1997-01-01', 1);
-- ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
-- (`w3schools`.`Orders`, CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`CustomerID`)
--  REFERENCES `Customers` (`CustomerID`))

-- Сценарій: аудитор перевіряє, чи немає «замовлень-сиріт» — тих, що посилаються
-- на неіснуючого клієнта. Завдяки FOREIGN KEY таких бути не може.
-- (Запит використовує LEFT JOIN — він детально розібраний в example05.)
SELECT COUNT(*) AS orphan_orders
FROM Orders o
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NOT NULL
  AND c.CustomerID IS NULL;
-- 0

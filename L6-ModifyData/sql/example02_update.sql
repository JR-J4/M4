/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: UPDATE — змінюємо існуючі рядки
 *
 * Синтаксис:
 *   UPDATE таблиця
 *   SET колонка1 = вираз1,
 *       колонка2 = вираз2
 *   WHERE умова;
 *
 * UPDATE змінює ВСІ рядки, що підходять під WHERE. Немає WHERE — змінить усю таблицю.
 *
 * Аналогія: пошук і заміна в Word. «Замінити все» без фільтра — і документ зіпсовано.
 *
 * Правило: спершу SELECT із тим самим WHERE, потім UPDATE.
 *
 * Усі зміни — у транзакції з ROLLBACK наприкінці, тож база w3schools не змінюється.
 */


START TRANSACTION;


-- ============================================================
-- 1. Один рядок за id
-- ============================================================
-- Сценарій: постачальник підняв ціну на чай Chais з 18 до 20.

UPDATE Products
SET Price = 20
WHERE ProductID = 1;

SELECT ProductID, ProductName, Price
FROM Products
WHERE ProductID = 1;
-- | ProductID | ProductName | Price |
-- |         1 | Chais       |    20 |


-- ============================================================
-- 2. Кілька колонок одночасно
-- ============================================================
-- Сценарій: клієнт Alfreds Futterkiste переїхав і змінив контактну особу.

UPDATE Customers
SET ContactName = 'Anna Schmidt',
    City        = 'Hamburg',
    PostalCode  = '20095'
WHERE CustomerName = 1;


UPDATE Customers
SET City = 'Brlin'
WHERE City = 'Berlin';


SELECT *
FROM Customers
WHERE City = 'Brlin';



SELECT CustomerName, ContactName, City, PostalCode
FROM Customers
WHERE CustomerID = 1;
-- | CustomerName        | ContactName  | City    | PostalCode |
-- | Alfreds Futterkiste | Anna Schmidt | Hamburg | 20095      |


-- ============================================================
-- 3. Група рядків: нова ціна через вираз
-- ============================================================
-- Сценарій: усі напої (CategoryID = 1) дорожчають на 10%.
-- Крок 1 — перевіряємо, скільки рядків зачепимо.

SELECT COUNT(*) AS will_change
FROM Products
WHERE CategoryID = 1;
-- 12

-- Крок 2 — той самий WHERE в UPDATE.
UPDATE Products
SET Price = ROUND(Price * 1.1, 2)
WHERE CategoryID = 1;


SELECT ROW_COUNT() AS changed;
-- 12   (ROW_COUNT() — скільки рядків змінив попередній запит)

SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1
ORDER BY ProductID
LIMIT 3;
-- | ProductName        | Price |
-- | Chais              |    22 |   (20 * 1.1 — ціну вже змінили в блоці 1)
-- | Chang              |  20.9 |
-- | Guaraná Fantástica |  4.95 |


-- ============================================================
-- 4. UPDATE з даними з іншої таблиці (JOIN)
-- ============================================================
-- Сценарій: усі товари японських постачальників — знижка 5%.
-- Країна є лише в Suppliers, тому з'єднуємо таблиці.

UPDATE Products p
JOIN Suppliers s ON s.SupplierID = p.SupplierID
SET p.Price = ROUND(p.Price * 0.95, 2)
WHERE s.Country = 'Japan';
-- 6 rows affected

-- Той самий запит у формі з лекції (через кому) працює так само:
--   UPDATE Products p, Suppliers s
--   SET p.Price = ROUND(p.Price * 0.95, 2)
--   WHERE s.SupplierID = p.SupplierID AND s.Country = 'Japan';


-- ============================================================
-- 5. Відкочуємо все
-- ============================================================

ROLLBACK;

SELECT ProductName, Price
FROM Products
WHERE ProductID = 1;
-- | ProductName | Price |
-- | Chais       |    18 |   (ціна знову як була)

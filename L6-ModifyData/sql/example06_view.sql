/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: VIEW — віртуальна таблиця
 *
 * VIEW — це збережений SELECT. Даних не зберігає: щоразу бере їх зі справжніх таблиць.
 *
 * Синтаксис:
 *   CREATE VIEW ім'я AS SELECT ...;
 *   CREATE OR REPLACE VIEW ім'я AS SELECT ...;   -- створити або переписати
 *   DROP VIEW IF EXISTS ім'я;
 *
 * Аналогія: вітрина магазину — показує частину складу, а склад один.
 *
 * Де застосовують:
 *   - сховати приватні колонки (дату народження, зарплату);
 *   - сховати складний JOIN за простим іменем.
 *
 * Скрипт створює view і видаляє їх наприкінці.
 */


-- ============================================================
-- 1. Ховаємо приватні дані
-- ============================================================
-- Сценарій: довідник працівників для всієї компанії — без дати народження і нотаток.

CREATE OR REPLACE VIEW l6_public_employee AS
SELECT EmployeeID, FirstName, LastName
FROM Employees;

SELECT *
FROM l6_public_employee
LIMIT 3;
-- | EmployeeID | FirstName | LastName  |
-- |          1 | Nancy     | Davolio   |
-- |          2 | Andrew    | Fuller    |
-- |          3 | Janet     | Leverling |


-- ============================================================
-- 2. Ховаємо складний JOIN
-- ============================================================
-- Сценарій: аналітик щодня пише один і той самий JOIN з чотирьох таблиць.
-- Робимо з нього view — далі це «звичайна таблиця».

CREATE OR REPLACE VIEW l6_order_summary AS
SELECT
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    c.Country,
    CONCAT(e.FirstName, ' ', e.LastName) AS employee,
    s.ShipperName
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Employees e ON e.EmployeeID = o.EmployeeID
JOIN Shippers  s ON s.ShipperID  = o.ShipperID;

SELECT OrderID, CustomerName, employee, ShipperName
FROM l6_order_summary
WHERE Country = 'Germany'
ORDER BY OrderID
LIMIT 3;
-- | OrderID | CustomerName           | employee         | ShipperName      |
-- |   10267 | Frankenversand         | Margaret Peacock | Speedy Express   |
-- |   10273 | QUICK-Stop             | Janet Leverling  | Federal Shipping |
-- |   10277 | Morgenstern Gesundkost | Andrew Fuller    | Federal Shipping |


-- ============================================================
-- 3. Пастка: VIEW не завжди «лише для читання»
-- ============================================================
-- У лекції сказано, що view змінити дані не може. У MySQL простий view
-- (одна таблиця, без GROUP BY / DISTINCT) — ОНОВЛЮВАНИЙ: UPDATE через нього
-- змінить справжню таблицю.

START TRANSACTION;

UPDATE l6_public_employee
SET LastName = 'CHANGED'
WHERE EmployeeID = 1;

SELECT LastName
FROM Employees
WHERE EmployeeID = 1;
-- CHANGED   — змінилась справжня таблиця Employees!

ROLLBACK;

-- Як уникнути: не давати користувачам прав UPDATE на view
-- (GRANT SELECT ON l6_public_employee TO ...) або робити view необновлюваним.


-- Прибираємо за собою
DROP VIEW IF EXISTS l6_public_employee;
DROP VIEW IF EXISTS l6_order_summary;

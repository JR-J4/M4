/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: DELETE, TRUNCATE, DROP — видаляємо
 *
 * Синтаксис:
 *   DELETE FROM таблиця WHERE id = 133;          -- один рядок
 *   DELETE FROM таблиця WHERE id IN (1, 2, 3);   -- список
 *   DELETE FROM таблиця WHERE умова;             -- за умовою
 *   TRUNCATE TABLE таблиця;                      -- усі рядки, швидко
 *   DROP TABLE таблиця;                          -- таблиця повністю
 *
 * Аналогія: DELETE — викреслити рядки в зошиті, TRUNCATE — вирвати всі
 * сторінки, DROP — викинути зошит.
 *
 * DELETE — у транзакції з ROLLBACK, TRUNCATE/DROP — на власній таблиці.
 */


START TRANSACTION;


-- ============================================================
-- 1. Один рядок, список, умова
-- ============================================================
-- Сценарій: клієнт прибрав позиції із замовлення 10248.

SELECT *
FROM OrderDetails
WHERE OrderID = 10248;
-- | OrderDetailID | OrderID | ProductID | Quantity |
-- |             1 |   10248 |        11 |       12 |
-- |             2 |   10248 |        42 |       10 |
-- |             3 |   10248 |        72 |        5 |

DELETE FROM OrderDetails
WHERE OrderDetailID = 1;

DELETE FROM OrderDetails
WHERE OrderDetailID IN (2, 3);

-- Сценарій: склад більше не відвантажує дрібні позиції (менше 5 штук).
SELECT COUNT(*)
FROM OrderDetails
WHERE Quantity < 5;
-- 28

DELETE FROM OrderDetails
WHERE Quantity < 5;
-- 28 rows affected


-- ============================================================
-- 2. FOREIGN KEY не дає видалити те, на що посилаються
-- ============================================================
-- Сценарій: хтось хоче видалити клієнта Ernst Handel, у якого 10 замовлень.
-- Розкоментуйте, щоб побачити помилку:

ROLLBACK;
START TRANSACTION ;

DELETE FROM Customers WHERE CustomerID = 20;
-- ERROR 1451: Cannot delete or update a parent row: a foreign key constraint fails
--             (`w3schools`.`Orders`, CONSTRAINT `orders_ibfk_1` ...)

-- А клієнтів без жодного замовлення видалити можна:
DELETE FROM Customers c
WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);
-- 19 rows affected

ROLLBACK;

SELECT COUNT(*)
FROM OrderDetails;
-- 518  (усе на місці)


-- ============================================================
-- 3. TRUNCATE і DROP
-- ============================================================
-- Сценарій: таблиця з тимчасовим логом, яку треба очистити, а потім прибрати.

DROP TABLE IF EXISTS l6_log;

CREATE TABLE l6_log (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    message VARCHAR(100)
);

INSERT INTO l6_log (message)
VALUES ('start'), ('step 1'), ('finish');

TRUNCATE TABLE l6_log;      -- усі рядки зникли, таблиця лишилась

SELECT COUNT(*)
FROM l6_log;
-- 0

DROP TABLE IF EXISTS l6_log; -- зникла і сама таблиця

-- У лекції ще є TRUNCATE SCHEME / DROP SCHEME. У MySQL правильно:
--   DROP SCHEMA ім'я;            (або DROP DATABASE ім'я)
-- Команди «TRUNCATE SCHEMA» у MySQL немає.

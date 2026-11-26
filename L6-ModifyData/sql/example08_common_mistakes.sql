/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: типові помилки під час зміни даних і як їх уникнути
 *
 * Кожен блок: помилка -> що станеться -> як уникнути.
 *
 * Головні правила:
 *   1. Спершу SELECT із тим самим WHERE — подивитися, ЩО зміниться.
 *   2. Ризиковані зміни — у START TRANSACTION, перевірити, потім COMMIT або ROLLBACK.
 *   3. Перед змінами на проді — бекап.
 *
 * Скрипт працює на власних таблицях l6_*: сам створює і сам видаляє.
 */


DROP TABLE IF EXISTS l6_product;

CREATE TABLE l6_product AS
SELECT ProductID, ProductName, CategoryID, SupplierID, Price
FROM Products;
-- 77 товарів


-- ============================================================
-- 1. UPDATE / DELETE без WHERE
-- ============================================================
-- Помилка: виділили в IDE лише перший рядок запиту і натиснули «Run».
--   UPDATE l6_product SET Price = 0      <- виконалось
--   WHERE ProductID = 1;                 <- не потрапило у виділення
-- Що станеться: ціна 0 у ВСІХ 77 товарів.

START TRANSACTION;

UPDATE l6_product
SET Price = 0;

SELECT COUNT(*) AS free_products
FROM l6_product
WHERE Price = 0;
-- 77   — «безкоштовний» увесь магазин

ROLLBACK;   -- врятувала транзакція

-- Як уникнути ще й так: режим safe updates забороняє UPDATE/DELETE без WHERE по ключу.
SET SQL_SAFE_UPDATES = 1;

-- UPDATE l6_product SET Price = 0;
-- ERROR 1175: You are using safe update mode and you tried to update a table
--             without a WHERE that uses a KEY column.

SET SQL_SAFE_UPDATES = 0;


-- ============================================================
-- 2. AND сильніший за OR
-- ============================================================
-- Завдання: знижка 50% на напої (1) і приправи (2), але лише постачальника 1.
-- Помилка: забули дужки.
--   WHERE CategoryID = 1 OR CategoryID = 2 AND SupplierID = 1
-- MySQL читає це як: CategoryID = 1 OR (CategoryID = 2 AND SupplierID = 1)

SELECT *
FROM l6_product
WHERE CategoryID = 1 OR CategoryID = 2 AND SupplierID = 1;
-- 13   — зачепили б усі 12 напоїв від будь-яких постачальників

SELECT COUNT(*) AS with_brackets
FROM l6_product
WHERE (CategoryID = 1 OR CategoryID = 2) AND SupplierID = 1;
-- 3    — те, що треба

-- Як уникнути: при змішуванні AND і OR завжди ставити дужки; або IN:
--   WHERE CategoryID IN (1, 2) AND SupplierID = 1


-- ============================================================
-- 3. WHERE колонка = NULL
-- ============================================================
-- Завдання: усім товарам без ціни поставити ціну 0.

UPDATE l6_product
SET Price = NULL
WHERE ProductID = 1;          -- готуємо: один товар без ціни

UPDATE l6_product
SET Price = 0
WHERE Price = NULL;
-- 0 rows affected   — порівняння з NULL ніколи не буває «істиною»

UPDATE l6_product
SET Price = 0
WHERE Price IS NULL;
-- 1 row affected    — правильно: IS NULL / IS NOT NULL


-- ============================================================
-- 4. DELETE ... NOT IN, коли в підзапиті є NULL
-- ============================================================
-- Завдання: видалити товари, яких немає в списку «залишити».

DROP TABLE IF EXISTS l6_keep;

CREATE TABLE l6_keep (ProductID INT);

INSERT INTO l6_keep (ProductID)
VALUES (1), (2), (NULL);      -- хтось випадково вставив NULL

DELETE FROM l6_product
WHERE ProductID NOT IN (SELECT ProductID FROM l6_keep);
-- 0 rows affected   — через один NULL не видалилось НІЧОГО

-- Як уникнути: NOT EXISTS — йому NULL не заважає.
START TRANSACTION;

DELETE FROM l6_product p
WHERE NOT EXISTS (SELECT 1 FROM l6_keep k WHERE k.ProductID = p.ProductID);
-- 75 rows affected  — лишились товари 1 і 2

ROLLBACK;


-- ============================================================
-- 5. INSERT без списку колонок
-- ============================================================
-- Помилка: INSERT INTO l6_product VALUES (100, 'Borscht', 6, 1, 9.99);
-- Сьогодні працює. Завтра хтось додав колонку — запит падає.

ALTER TABLE l6_product ADD COLUMN stock INT DEFAULT 0;

INSERT INTO l6_product VALUES (100, 'Borscht', 6, 1, 9.99);

-- INSERT INTO l6_product VALUES (100, 'Borscht', 6, 1, 9.99);
-- ERROR 1136: Column count doesn't match value count at row 1

-- Як уникнути: завжди перелічувати колонки.
INSERT INTO l6_product (ProductID, ProductName, CategoryID, SupplierID, Price)
VALUES (100, 'Borscht', 6, 1, 9.99);
-- 1 row affected


-- ============================================================
-- 6. DDL усередині транзакції робить COMMIT
-- ============================================================
-- Помилка: розраховували на ROLLBACK, але посеред транзакції виконали ALTER / CREATE / DROP / TRUNCATE.

SELECT COUNT(*)
FROM l6_product;
-- 78

START TRANSACTION;

DELETE FROM l6_product
WHERE CategoryID = 1;         -- 12 рядків

ALTER TABLE l6_product ADD COLUMN note VARCHAR(50);   -- тихий COMMIT!

ROLLBACK;                     -- уже нічого відкочувати

SELECT COUNT(*)
FROM l6_product;
-- 66   — напої зникли назавжди

-- Як уникнути: не змішувати зміну структури (DDL) і зміну даних (DML) в одній
-- транзакції. TRUNCATE — теж DDL: на відміну від DELETE, його не відкотити.


-- ============================================================
-- 7. ON DELETE CASCADE видаляє більше, ніж здається
-- ============================================================
-- Сценарій: видаляємо одного клієнта, а за ним мовчки зникають усі його замовлення.

DROP TABLE IF EXISTS l6_order;
DROP TABLE IF EXISTS l6_client;

CREATE TABLE l6_client (
    id   INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE l6_order (
    id        INT PRIMARY KEY,
    client_id INT,
    FOREIGN KEY (client_id) REFERENCES l6_client (id) ON DELETE CASCADE
);

INSERT INTO l6_client (id, name)
VALUES (1, 'Kyiv Coffee');

INSERT INTO l6_order (id, client_id)
VALUES (1, 1), (2, 1), (3, 1);

DELETE FROM l6_client
WHERE id = 1;
-- 1 row affected   — пише «1 рядок», а насправді зникло 4

SELECT COUNT(*)
FROM l6_order;
-- 0

-- Як уникнути: CASCADE — лише для «частин» запису (рядки замовлення без замовлення
-- не мають сенсу). Для важливих даних — RESTRICT (за замовчуванням): база не дасть
-- видалити, поки є посилання.


-- Прибираємо за собою
DROP TABLE IF EXISTS l6_order;
DROP TABLE IF EXISTS l6_client;
DROP TABLE IF EXISTS l6_keep;
DROP TABLE IF EXISTS l6_product;

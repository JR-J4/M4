/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: INSERT — додаємо рядки
 *
 * Синтаксис:
 *   INSERT INTO таблиця (колонка1, колонка2) VALUES (значення1, значення2);
 *   INSERT INTO таблиця (колонка1, колонка2) VALUES (...), (...), (...);
 *   INSERT INTO таблиця (колонка1, колонка2) SELECT ... FROM інша_таблиця;
 *
 * Колонки, яких немає у списку, отримають DEFAULT (або NULL),
 * а id з AUTO_INCREMENT сервер видасть сам.
 *
 * Аналогія: новий рядок у журналі відвідувань — номер ставить вахтер,
 * ви пишете лише ім'я.
 *
 * Скрипт працює на власній таблиці l6_customer: сам створює і сам видаляє.
 */
USE w3schools;


DROP TABLE IF EXISTS l6_customer;

CREATE TABLE l6_customer (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    status  VARCHAR(10) DEFAULT 'new'
);


-- ============================================================
-- 1. Один рядок
-- ============================================================
-- Сценарій: зареєструвався новий клієнт. id і status не передаємо.

INSERT INTO l6_customer (name, country)
VALUES ('Kyiv Coffee', 'Ukraine');

SELECT *
FROM l6_customer;
-- | id | name        | country | status |
-- |  1 | Kyiv Coffee | Ukraine | new    |

-- id щойно вставленого рядка:
SELECT LAST_INSERT_ID();
-- 1


-- ============================================================
-- 2. Кілька рядків одним запитом
-- ============================================================
-- Сценарій: менеджер переносить клієнтів зі своєї таблички Excel.
-- Один INSERT на сотню рядків набагато швидший за сотню окремих.

INSERT INTO l6_customer (name, country, status)
VALUES
    ('Lviv Chocolate', 'Ukraine', 'vip'),
    ('Odesa Wine',     'Ukraine', 'new');

SELECT *
FROM l6_customer;
-- | id | name           | country | status |
-- |  1 | Kyiv Coffee    | Ukraine | new    |
-- |  2 | Lviv Chocolate | Ukraine | vip    |
-- |  3 | Odesa Wine     | Ukraine | new    |


-- ============================================================
-- 3. INSERT ... SELECT — копіюємо з іншої таблиці
-- ============================================================
-- Сценарій: маркетинг запускає акцію в Німеччині — переносимо всіх німецьких
-- клієнтів із Customers до нашого списку.

INSERT INTO l6_customer (name, country)
SELECT CustomerName, Country
FROM Customers
WHERE Country = 'Germany';
-- 11 rows affected

SELECT COUNT(*) AS total
FROM l6_customer;
-- 14  (3 + 11)

SELECT *
FROM l6_customer
ORDER BY id
LIMIT 3 OFFSET 3;
-- | id | name                      | country | status |
-- |  4 | Alfreds Futterkiste       | Germany | new    |
-- |  5 | Blauer See Delikatessen   | Germany | new    |
-- |  6 | Drachenblut Delikatessend | Germany | new    |


-- Прибираємо за собою
DROP TABLE IF EXISTS l6_customer;

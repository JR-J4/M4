/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: індекси
 *
 * Індекс — відсортований «покажчик» на рядки за якоюсь колонкою.
 * Без індексу сервер переглядає ВСІ рядки, з індексом — одразу знаходить потрібні.
 *
 * Синтаксис:
 *   ALTER TABLE t ADD INDEX ім'я (колонка);
 *   ALTER TABLE t ADD INDEX ім'я (колонка1, колонка2);   -- складений
 *   ALTER TABLE t DROP INDEX ім'я;
 *   EXPLAIN SELECT ...;   -- показує, чи використано індекс
 *
 * Як читати EXPLAIN:
 *   type = ALL         — повний перегляд таблиці (погано на великих таблицях)
 *   type = ref / range — використано індекс
 *   key                — який саме індекс
 *   rows               — скільки рядків сервер планує переглянути
 *
 * Аналогія: предметний покажчик у кінці книжки — не гортаєш усі 500 сторінок.
 *
 * Ціна: індекс займає місце і сповільнює INSERT/UPDATE/DELETE.
 *
 * Скрипт працює на копії Orders — власній таблиці l6_orders без індексів.
 */


DROP TABLE IF EXISTS l6_orders;

CREATE TABLE l6_orders AS
SELECT *
FROM Orders;
-- CREATE TABLE ... AS SELECT копіює дані, але НЕ індекси і ключі.


-- ============================================================
-- 1. Без індексу
-- ============================================================
-- Сценарій: менеджер часто шукає замовлення конкретного клієнта.

EXPLAIN
SELECT *
FROM l6_orders
WHERE CustomerID = 20;
-- | type | key  | rows |
-- | ALL  | NULL |  196 |   переглянуто всю таблицю


-- ============================================================
-- 2. З індексом
-- ============================================================

ALTER TABLE l6_orders ADD INDEX idx_customer (CustomerID);

EXPLAIN
SELECT *
FROM l6_orders
WHERE CustomerID = 20;
-- | type | key          | rows |
-- | ref  | idx_customer |   10 |   лише 10 рядків цього клієнта


-- ============================================================
-- 3. Складений індекс
-- ============================================================
-- Сценарій: звіт «замовлення працівника за період» — фільтр по двох колонках.

ALTER TABLE l6_orders ADD INDEX idx_employee_date (EmployeeID, OrderDate);

EXPLAIN
SELECT *
FROM l6_orders
WHERE EmployeeID = 4
  AND OrderDate BETWEEN '1997-01-01' AND '1997-01-31';
-- | type  | key               | rows |
-- | range | idx_employee_date |    8 |


-- ============================================================
-- 4. Пастки: коли індекс НЕ працює
-- ============================================================

-- а) Пошук лише за ДРУГОЮ колонкою складеного індексу.
--    Індекс (EmployeeID, OrderDate) — як телефонна книга «прізвище, ім'я»:
--    за самим ім'ям у ній не пошукаєш.
EXPLAIN
SELECT *
FROM l6_orders
WHERE OrderDate = '1997-01-15';
-- | type | key  | rows |
-- | ALL  | NULL |  196 |

-- б) Функція над колонкою в WHERE.
ALTER TABLE l6_orders ADD INDEX idx_date (OrderDate);

EXPLAIN
SELECT *
FROM l6_orders
WHERE YEAR(OrderDate) = 1997;
-- | type | key  | rows |
-- | ALL  | NULL |  196 |   YEAR() «ховає» колонку від індексу

-- Як уникнути: залишити колонку «голою», а умову переписати діапазоном.
EXPLAIN
SELECT *
FROM l6_orders
WHERE OrderDate >= '1997-01-01'
  AND OrderDate <  '1998-01-01';
-- | type  | key      | rows |
-- | range | idx_date |   44 |


-- ============================================================
-- 5. Видаляємо індекс
-- ============================================================

ALTER TABLE l6_orders DROP INDEX idx_date;


-- Прибираємо за собою
DROP TABLE IF EXISTS l6_orders;

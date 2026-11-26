/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: схеми та ALTER TABLE — змінюємо структуру
 *
 * Схема (= база даних у MySQL):
 *   CREATE SCHEMA ім'я;             DROP SCHEMA IF EXISTS ім'я;
 *   USE ім'я;                        -- схема за замовчуванням
 *   SELECT * FROM схема.таблиця;     -- або явно вказати схему
 *
 * ALTER TABLE змінює не дані, а «каркас» таблиці:
 *   ALTER TABLE t ADD COLUMN колонка тип;
 *   ALTER TABLE t MODIFY COLUMN колонка новий_тип;
 *   ALTER TABLE t ALTER COLUMN колонка SET DEFAULT значення;
 *   ALTER TABLE t DROP COLUMN колонка;
 *   ALTER TABLE t ADD PRIMARY KEY (колонка);   / DROP PRIMARY KEY;
 *
 * Аналогія: в анкету додали нове поле «email» — старі анкети лишились,
 * у них це поле просто порожнє.
 *
 * Скрипт працює на власній таблиці l6_employee: сам створює і сам видаляє.
 */


-- ============================================================
-- 1. Схема: явне ім'я або USE
-- ============================================================
-- Користувач w3 має права лише на w3schools, тому CREATE SCHEMA тут не виконаємо.
-- Під root це виглядало б так:
--   CREATE SCHEMA shop;
--   DROP SCHEMA IF EXISTS shop;      (у лекції помилка: IF EXIST без S)

USE w3schools;

SELECT ShipperName
FROM w3schools.Shippers
WHERE ShipperID = 1;
-- Speedy Express


-- ============================================================
-- 2. Додаємо колонку і первинний ключ
-- ============================================================
-- Сценарій: таблицю створили поспіхом — без ключа і без email.

DROP TABLE IF EXISTS l6_employee;

CREATE TABLE l6_employee (
    id   INT,
    name VARCHAR(50)
);

INSERT INTO l6_employee (id, name)
VALUES (1, 'Olena'), (2, 'Taras');

ALTER TABLE l6_employee ADD PRIMARY KEY (id);
ALTER TABLE l6_employee ADD COLUMN email VARCHAR(10);

SELECT *
FROM l6_employee;
-- | id | name  | email |
-- |  1 | Olena | NULL  |    у старих рядків нова колонка = NULL
-- |  2 | Taras | NULL  |


-- ============================================================
-- 3. Змінюємо тип і значення за замовчуванням
-- ============================================================
-- Сценарій: 10 символів на email замало — розширюємо до 100 і додаємо DEFAULT.

ALTER TABLE l6_employee MODIFY COLUMN email VARCHAR(100);
ALTER TABLE l6_employee ALTER COLUMN email SET DEFAULT 'test@test.com';
-- У лекції: ALTER COLUMN email VARCHAR(100) DEFAULT '...' — так MySQL не вміє.
-- Тип міняє MODIFY, а ALTER COLUMN — лише DEFAULT (SET DEFAULT / DROP DEFAULT).

INSERT INTO l6_employee (id, name)
VALUES (3, 'Ivan');

SELECT *
FROM l6_employee;
-- | id | name  | email         |
-- |  1 | Olena | NULL          |
-- |  2 | Taras | NULL          |
-- |  3 | Ivan  | test@test.com |   DEFAULT діє лише на нові рядки


-- ============================================================
-- 4. Видаляємо колонку і ключ
-- ============================================================

ALTER TABLE l6_employee DROP COLUMN email;
ALTER TABLE l6_employee DROP PRIMARY KEY;
-- У лекції: DELETE PRIMARY KEY — такої команди немає, правильно DROP.

DESCRIBE l6_employee;
-- | Field | Type        | Null | Key | Default |
-- | id    | int         | NO   |     | NULL    |
-- | name  | varchar(50) | YES  |     | NULL    |


-- Прибираємо за собою
DROP TABLE IF EXISTS l6_employee;

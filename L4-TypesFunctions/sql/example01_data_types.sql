/*
 * Лекція 4. SQL-типи даних та SQL-функції
 * Тема: типи даних
 *
 * Тип колонки каже, ЩО в ній можна зберігати, і не пускає туди сміття.
 *
 *   Числа:  TINYINT, SMALLINT, MEDIUMINT, INT, BIGINT  — цілі (byte ... long у Java)
 *           FLOAT, DOUBLE                              — дробові, приблизні
 *           DECIMAL(всього_цифр, після_коми)           — дробові, точні (гроші!)
 *   Рядки:  CHAR(n)     — рівно n символів (код країни, валюти)
 *           VARCHAR(n)  — до n символів (ім'я, адреса)
 *           TEXT        — довгий текст
 *   Дати:   DATE, TIME, DATETIME, TIMESTAMP, YEAR
 *   Інше:   ENUM('a','b') — одне значення зі списку; BLOB — байти (картинка)
 *
 * Аналогія: анкета з клітинками — у поле «вік» слово не впишеш,
 * у поле «дата» 30 лютого не поставиш.
 *
 * Скрипт працює на власній таблиці demo_types: сам створює і сам видаляє.
 */


-- ============================================================
-- 1. Таблиця з різними типами
-- ============================================================
-- Сценарій: заводимо картку клієнта — вік, код країни, ім'я, дата народження,
-- час реєстрації, розмір футболки.

DROP TABLE IF EXISTS demo_types;

CREATE TABLE demo_types (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    age           TINYINT,                -- -128..127
    price_float   FLOAT,                  -- приблизне число
    price_decimal DECIMAL(10, 2),         -- точне: 10 цифр, 2 після коми
    code          CHAR(3),                -- фіксована довжина
    name          VARCHAR(255),            -- змінна довжина, максимум 50
    born          DATE,                   -- лише дата
    created       DATETIME,               -- дата і час
    size          ENUM('S', 'M', 'L')     -- лише одне з трьох значень
);

INSERT INTO demo_types (age, price_float, price_decimal, code, name, born, created, size)
VALUES (30, 0.1, 0.1, 'UA', 'Олена', '1995-03-14', '2024-01-15 09:30:00', 'M');

SELECT *
FROM demo_types;
-- | id | age | price_float | price_decimal | code | name  | born       | created             | size |
-- |  1 |  30 |         0.1 |          0.10 | UA   | Олена | 1995-03-14 | 2024-01-15 09:30:00 | M    |


-- ============================================================
-- 2. Чому гроші — це DECIMAL, а не FLOAT
-- ============================================================
-- Сценарій: товар коштує 0.10, клієнт купив 3 штуки. Скільки до сплати?

SELECT
    price_float * 3         AS float_x3,
    price_float * 3 = 0.3   AS float_ok,
    price_decimal * 3       AS decimal_x3,
    price_decimal * 3 = 0.3 AS decimal_ok
FROM demo_types;
-- | float_x3            | float_ok | decimal_x3 | decimal_ok |
-- | 0.30000000447034836 |        0 |       0.30 |          1 |
-- FLOAT «загубив» копійки, DECIMAL порахував точно.


-- ============================================================
-- 3. Тип не пускає неправильні дані
-- ============================================================
-- Сценарій: оператор помилився під час введення. База відмовить сама.
-- Розкоментуйте рядок, щоб побачити помилку.

-- INSERT INTO demo_types (age) VALUES (200);
-- ERROR 1264: Out of range value for column 'age'          (TINYINT — максимум 127)

-- INSERT INTO demo_types (code) VALUES ('UKRAINE');
-- ERROR 1406: Data too long for column 'code'              (CHAR(3) — максимум 3 символи)

-- INSERT INTO demo_types (born) VALUES ('2024-02-30');
-- ERROR 1292: Incorrect date value: '2024-02-30'           (30 лютого не існує)

-- INSERT INTO demo_types (size) VALUES ('XXL');
-- ERROR 1265: Data truncated for column 'size'             (XXL немає в ENUM)


-- Прибираємо за собою
DROP TABLE IF EXISTS demo_types;

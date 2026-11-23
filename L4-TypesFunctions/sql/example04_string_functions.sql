/*
 * Лекція 4. SQL-типи даних та SQL-функції
 * Тема: рядкові функції
 *
 *   LENGTH(s)             довжина в БАЙТАХ
 *   CHAR_LENGTH(s)        довжина в символах
 *   UPPER(s), LOWER(s)    верхній / нижній регістр
 *   CONCAT(s1, s2, ...)   склеїти рядки
 *   SUBSTR(s, з, скільки) підрядок (позиції рахуються з 1, а не з 0!)
 *   LOCATE(що, де)        позиція підрядка — як indexOf(), 0 = не знайдено
 *   REPLACE(s, що, на_що) замінити підрядок
 *
 * Аналогія: ті самі методи String із Java — toUpperCase(), substring(),
 * indexOf(), replace() — тільки викликаються прямо в запиті.
 *
 * Де застосовують: ПІБ у звіті, генерація логіна чи email, пошук без урахування
 * регістру, приведення даних до одного формату.
 */


-- ============================================================
-- 1. Довжина рядка: байти чи символи
-- ============================================================
-- Сценарій: перевіряємо, чи влізе текст у VARCHAR(10).
-- Кирилична літера в utf8mb4 займає 2 байти, тому LENGTH «бреше».

SELECT
    LENGTH('text')        AS bytes_en,
    LENGTH('Привіт')      AS bytes_ua,
    CHAR_LENGTH('Привіт') AS chars_ua;
-- | bytes_en | bytes_ua | chars_ua |
-- |        4 |       12 |        6 |
-- Довжину тексту рахуйте через CHAR_LENGTH.


-- ============================================================
-- 2. Прості перетворення
-- ============================================================

SELECT
    UPPER('Привіт')                      AS up,
    LOWER('Привіт')                      AS low,
    SUBSTR('Привіт', 2, 3)               AS part,
    SUBSTR('Привіт як справи?', 8)       AS tail,
    LOCATE('як', 'Привіт як справи?')    AS pos,
    REPLACE('2024.01.15', '.', '-')      AS replaced;
-- | up     | low    | part | tail       | pos | replaced   |
-- | ПРИВІТ | привіт | рив  | як справи? |   8 | 2024-01-15 |


-- ============================================================
-- 3. ПІБ та email працівника
-- ============================================================
-- Сценарій: HR готує бейджі (повне ім'я, скорочене) і корпоративні поштові адреси.

SELECT
    CONCAT(FirstName, ' ', LastName)                       AS full_name,
    CONCAT(SUBSTR(FirstName, 1, 1), '. ', LastName)        AS short_name,
    LOWER(CONCAT(FirstName, '.', LastName, '@shop.com'))   AS email
FROM Employees
ORDER BY EmployeeID
LIMIT 3;
-- | full_name       | short_name   | email                    |
-- | Nancy Davolio   | N. Davolio   | nancy.davolio@shop.com   |
-- | Andrew Fuller   | A. Fuller    | andrew.fuller@shop.com   |
-- | Janet Leverling | J. Leverling | janet.leverling@shop.com |


-- ============================================================
-- 4. Найдовші назви
-- ============================================================
-- Сценарій: дизайнер питає, які назви клієнтів не влізуть у вузьку колонку звіту.

SELECT
    CustomerName,
    CHAR_LENGTH(CustomerName) AS len
FROM Customers
ORDER BY len DESC, CustomerName
LIMIT 3;
-- | CustomerName                         | len |
-- | FISSA Fabrica Inter. Salchichas S.A. |  36 |
-- | Ana Trujillo Emparedados y helados   |  34 |
-- | Trail's Head Gourmet Provisioners    |  33 |


-- ============================================================
-- 5. Перше слово назви: LOCATE + SUBSTR
-- ============================================================
-- Сценарій: для короткого ярлика на полиці потрібне лише перше слово назви товару.
-- LOCATE знаходить пробіл, SUBSTR бере все до нього.

SELECT
    ProductName,
    SUBSTR(ProductName, 1, LOCATE(' ', ProductName) - 1) AS first_word
FROM Products
WHERE LOCATE(' ', ProductName) > 0
ORDER BY ProductID
LIMIT 3;
-- | ProductName                  | first_word |
-- | Aniseed Syrup                | Aniseed    |
-- | Chef Anton's Cajun Seasoning | Chef       |
-- | Chef Anton's Gumbo Mix       | Chef       |


-- ============================================================
-- 6. Позначка в тексті: CONCAT + умова по даті
-- ============================================================
-- Сценарій: як у лекції з «EXPIRED!» — замовлення, старші за 8 липня 1996,
-- показуємо з позначкою OLD!.

SELECT
    CONCAT('OLD! ', OrderID) AS label,
    OrderDate
FROM Orders
WHERE OrderDate < '1996-07-08'
ORDER BY OrderID;
-- | label      | OrderDate  |
-- | OLD! 10248 | 1996-07-04 |
-- | OLD! 10249 | 1996-07-05 |


-- ============================================================
-- 7. Пастка: CONCAT і NULL
-- ============================================================
-- Якщо хоч один аргумент NULL — увесь результат CONCAT стає NULL.
-- CONCAT_WS(роздільник, ...) пропускає NULL.

SELECT
    CONCAT('Berlin', NULL, 'Germany')           AS with_concat,
    CONCAT_WS(', ', 'Berlin', NULL, 'Germany')  AS with_concat_ws;
-- | with_concat | with_concat_ws  |
-- | NULL        | Berlin, Germany |

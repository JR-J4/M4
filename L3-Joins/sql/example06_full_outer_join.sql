/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: FULL OUTER JOIN і всі типи JOIN разом
 *
 * Чотири типи JOIN (А — ліва таблиця, Б — права):
 *   JOIN        = INNER JOIN        — лише рядки, які мають пару в А і в Б
 *   LEFT JOIN   = LEFT OUTER JOIN   — + рядки з А без пари
 *   RIGHT JOIN  = RIGHT OUTER JOIN  — + рядки з Б без пари
 *   FULL JOIN   = FULL OUTER JOIN   — + рядки без пари з обох боків
 *
 * У MySQL FULL OUTER JOIN НЕМАЄ. Його збирають з двох запитів:
 *   SELECT ... FROM A LEFT  JOIN B ON ...
 *   UNION
 *   SELECT ... FROM A RIGHT JOIN B ON ...
 * UNION прибирає дублікати — рядки з парою, які повернули обидва запити.
 *
 * Аналогія: два списки — хто з друзів був на дні народження і хто на весіллі.
 * FULL OUTER JOIN — загальний список: був лише на ДН, лише на весіллі або на обох.
 *
 * Де застосовують:
 *   - звірка двох джерел даних (склад vs бухгалтерія: що є тільки в одному з них);
 *   - міграції: які записи є лише в старій або лише в новій таблиці.
 */


-- ============================================================
-- 1. Країни клієнтів і країни постачальників
-- ============================================================
-- Сценарій: відділ розвитку хоче побачити, у яких країнах у нас лише клієнти,
-- у яких лише постачальники, а де — і ті, й інші.
-- Збираємо дві «таблиці країн» підзапитами (детальніше про підзапити — example08–10).
-- У Customers є два тестові записи «Nullable Customer» з Country = NULL —
-- відкидаємо їх (WHERE Country IS NOT NULL), щоб не отримати рядок «NULL | NULL».

SELECT COUNT(DISTINCT Country) AS customer_countries
FROM Customers;
-- 21

SELECT COUNT(DISTINCT Country) AS supplier_countries
FROM Suppliers;
-- 16


-- ============================================================
-- 2. INNER JOIN — країни, де є і клієнти, і постачальники
-- ============================================================

SELECT cc.Country
FROM (SELECT DISTINCT Country FROM Customers WHERE Country IS NOT NULL) cc
JOIN (SELECT DISTINCT Country FROM Suppliers) sc
    ON cc.Country = sc.Country
ORDER BY cc.Country;
-- Brazil, Canada, Denmark, Finland, France, Germany, Italy, Norway, Spain, Sweden, UK, USA
-- 12 рядків


-- ============================================================
-- 3. LEFT і RIGHT JOIN — лише з одного боку
-- ============================================================

-- Країни, де є клієнти, але немає постачальників:
SELECT cc.Country
FROM (SELECT DISTINCT Country FROM Customers WHERE Country IS NOT NULL) cc
LEFT JOIN (SELECT DISTINCT Country FROM Suppliers) sc ON cc.Country = sc.Country
WHERE sc.Country IS NULL
ORDER BY cc.Country;
-- Argentina, Austria, Belgium, Ireland, Mexico, Poland, Portugal, Switzerland, Venezuela
-- 9 рядків

-- Країни, де є постачальники, але немає клієнтів:
SELECT sc.Country
FROM (SELECT DISTINCT Country FROM Customers WHERE Country IS NOT NULL) cc
RIGHT JOIN (SELECT DISTINCT Country FROM Suppliers) sc ON cc.Country = sc.Country
WHERE cc.Country IS NULL
ORDER BY sc.Country;
-- Australia, Japan, Netherlands, Singapore
-- 4 рядки


-- ============================================================
-- 4. FULL OUTER JOIN через UNION
-- ============================================================
-- Сценарій: одна зведена таблиця по всіх країнах з позначкою «хто там є».

-- FULL OUTER JOIN у MySQL не працює:
-- SELECT * FROM Customers FULL OUTER JOIN Suppliers ON Customers.Country = Suppliers.Country;
-- ERROR 1064 (42000): You have an error in your SQL syntax; ... near 'OUTER JOIN Suppliers ...'
--
-- Ще гірше — FULL JOIN без OUTER: помилки НЕМАЄ! MySQL сприймає FULL як аліас
-- таблиці Customers, і запит тихо виконується як звичайний INNER JOIN:
SELECT COUNT(*) AS full_join_rows
FROM Customers FULL JOIN Suppliers ON FULL.Country = Suppliers.Country;
-- 167

SELECT COUNT(*) AS inner_join_rows
FROM Customers
JOIN Suppliers ON Customers.Country = Suppliers.Country;
-- 167  — те саме число: жодного «FULL» тут не було

-- Правильна емуляція — LEFT JOIN + UNION + RIGHT JOIN:

WITH CustomerCountry AS ( SELECT DISTINCT Country FROM Customers WHERE Country IS NOT NULL )
WITH SupplierCountry AS (SELECT DISTINCT Country FROM Suppliers)

SELECT cc.Country AS customer_country, sc.Country AS supplier_country
FROM CustomerCountry cc
LEFT JOIN SupplierCountry sc ON cc.Country = sc.Country
UNION
SELECT cc.Country, sc.Country
FROM CustomerCountry cc
RIGHT JOIN SupplierCountry sc ON cc.Country = sc.Country
ORDER BY COALESCE(customer_country, supplier_country);
-- | customer_country | supplier_country |
-- | Argentina        | NULL             |
-- | NULL             | Australia        |
-- | Austria          | NULL             |
-- | Belgium          | NULL             |
-- | Brazil           | Brazil           |
-- | Canada           | Canada           |
-- | ...              | ...              |
-- | NULL             | Japan            |
-- | Mexico           | NULL             |
-- | ...              | ...              |
-- | USA              | USA              |
-- | Venezuela        | NULL             |
-- 25 рядків = 12 (обидва) + 9 (лише клієнти) + 4 (лише постачальники)
-- NULL ліворуч — у країні лише постачальники, NULL праворуч — лише клієнти.

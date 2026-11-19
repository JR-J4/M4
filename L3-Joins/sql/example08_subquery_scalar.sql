/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: підзапит, який повертає ОДНЕ значення (скалярний підзапит)
 *
 * Підзапит — SELECT усередині іншого запиту, у круглих дужках.
 * Скалярний підзапит повертає одну колонку й один рядок, тому його можна
 * ставити всюди, де очікується одне значення: у WHERE, у SELECT, у HAVING.
 *
 * Синтаксис:
 *   SELECT ... FROM таблиця
 *   WHERE колонка > (SELECT AVG(колонка) FROM таблиця)
 *
 * Аналогія: «хто з класу вищий за середній зріст?» — спершу рахуємо середній зріст
 * (підзапит), потім порівнюємо з ним кожного.
 *
 * Де застосовують:
 *   - порівняння з агрегатом: вище середнього, найновіше, максимальне;
 *   - додаткова колонка-показник у звіті (частка від загальної суми).
 *
 * Увага: якщо «скалярний» підзапит поверне більше одного рядка —
 * ERROR 1242 (21000): Subquery returns more than 1 row.
 */


-- ============================================================
-- 1. Товари, дорожчі за середню ціну
-- ============================================================
-- Сценарій: маркетолог формує розділ «преміум» — товари з ціною вище середньої.

SELECT ROUND(AVG(Price), 2) AS avg_price
FROM Products;
-- 28.87

SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
ORDER BY Price DESC
LIMIT 5;


-- | ProductName             | Price  |
-- | Côte de Blaye           |  263.5 |
-- | Thüringer Rostbratwurst | 123.79 |
-- | Mishi Kobe Niku         |     97 |
-- | Sir Rodney's Marmalade  |     81 |
-- | Carnarvon Tigers        |   62.5 |

SELECT COUNT(*) AS premium_products
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
-- 25  (з 77 товарів)


-- ============================================================
-- 2. Найдорожчий товар
-- ============================================================
-- Сценарій: «який у нас найдорожчий товар і хто його постачає?»
-- ORDER BY ... LIMIT 1 віддасть лише один рядок, а підзапит з MAX —
-- усі товари з максимальною ціною, якщо їх кілька.

SELECT p.ProductName, p.Price, s.SupplierName
FROM Products p
JOIN Suppliers s ON s.SupplierID = p.SupplierID
WHERE p.Price = (SELECT MAX(Price) FROM Products);
-- | ProductName   | Price | SupplierName               |
-- | Côte de Blaye | 263.5 | Aux joyeux ecclésiastiques |


-- ============================================================
-- 3. Підзапит з іншої таблиці
-- ============================================================
-- Сценарій: керівник хоче бачити всі замовлення, оформлені в останній день,
-- за який є дані.

SELECT o.OrderID, o.OrderDate, c.CustomerName
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE o.OrderDate = (SELECT MAX(OrderDate) FROM Orders);
-- | OrderID | OrderDate  | CustomerName       |
-- |   10443 | 1997-02-12 | Reggiani Caseifici |


-- ============================================================
-- 4. Скалярний підзапит у SELECT
-- ============================================================
-- Сценарій: фінансист хоче бачити частку кожної служби доставки
-- від загальної кількості замовлень у відсотках.

SELECT
    s.ShipperName,
    COUNT(o.OrderID) AS orders,
    ROUND(COUNT(o.OrderID) * 100 / (SELECT COUNT(*) FROM Orders), 1) AS percent
FROM Shippers s
JOIN Orders o ON o.ShipperID = s.ShipperID
GROUP BY s.ShipperID, s.ShipperName
ORDER BY orders DESC;
-- | ShipperName      | orders | percent |
-- | United Package   |     74 |    37.8 |
-- | Federal Shipping |     68 |    34.7 |
-- | Speedy Express   |     54 |    27.6 |


-- ============================================================
-- 5. Корельований підзапит: значення для кожного рядка
-- ============================================================
-- Сценарій: для кожного працівника показати дату його останнього замовлення.
-- Підзапит посилається на e.EmployeeID із зовнішнього запиту і виконується
-- для кожного працівника окремо.

SELECT
    e.EmployeeID,
    e.LastName,
    (SELECT MAX(o.OrderDate)
     FROM Orders o
     WHERE o.EmployeeID = e.EmployeeID) AS last_order
FROM Employees e
ORDER BY e.EmployeeID;
-- | EmployeeID | LastName  | last_order |
-- |          1 | Davolio   | 1997-01-06 |
-- |          2 | Fuller    | 1997-01-22 |
-- |          3 | Leverling | 1997-02-11 |
-- |          4 | Peacock   | 1997-02-10 |
-- |          5 | Buchanan  | 1996-12-27 |
-- |          6 | Suyama    | 1997-02-07 |
-- |          7 | King      | 1997-01-28 |
-- |          8 | Callahan  | 1997-02-12 |
-- |          9 | Dodsworth | 1997-01-10 |
-- |         10 | West      | NULL       |
-- West — NULL: замовлень немає, MAX по порожній множині дає NULL.

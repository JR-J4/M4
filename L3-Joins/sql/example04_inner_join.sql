/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: оператор JOIN (INNER JOIN)
 *
 * JOIN явно каже серверу: «мені потрібен не декартів добуток, а склеювання рядків,
 * які посилаються один на одного». Для цього в сервера є окремі алгоритми,
 * тож JOIN працює швидше й читається краще, ніж FROM a, b WHERE ...
 *
 * Синтаксис:
 *   SELECT колонки
 *   FROM таблиця1
 *   [INNER] JOIN таблиця2 ON умова
 *   [JOIN таблиця3 ON умова ...]
 *   [WHERE фільтр]
 *
 * JOIN і INNER JOIN — одне й те саме. Результат містить лише рядки,
 * для яких знайшлася пара в обох таблицях.
 *
 * Аналогія: роздача квитків за списком. Кожному імені в списку відповідає
 * квиток з тим самим номером. Імена без квитків і квитки без імен — не потрапляють.
 *
 * Де застосовують: майже скрізь — «замовлення з іменем клієнта»,
 * «товар з назвою категорії», «рядок чека з ціною товару».
 */


-- ============================================================
-- 1. Той самий запит: WHERE проти JOIN
-- ============================================================
-- Сценарій: список замовлень з іменем клієнта (як у example01, блок 3).

-- Старий стиль — умова звʼязку змішана з фільтрами у WHERE:
SELECT o.OrderID, c.CustomerName
FROM Orders o, Customers c
WHERE o.CustomerID = c.CustomerID
  AND c.Country = 'Germany'
ORDER BY o.OrderID
LIMIT 3;
-- | OrderID | CustomerName           |
-- |   10267 | Frankenversand         |
-- |   10273 | QUICK-Stop             |
-- |   10277 | Morgenstern Gesundkost |

-- Сучасний стиль — звʼязок у ON, фільтр у WHERE. Результат той самий:
SELECT o.OrderID, c.CustomerName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Country = 'Germany'
ORDER BY o.OrderID
LIMIT 3;
-- | OrderID | CustomerName           |
-- |   10267 | Frankenversand         |
-- |   10273 | QUICK-Stop             |
-- |   10277 | Morgenstern Gesundkost |


-- ============================================================
-- 2. JOIN трьох і більше таблиць
-- ============================================================
-- Сценарій: служба підтримки отримала дзвінок щодо замовлення 10248.
-- Потрібно: хто клієнт, хто з працівників оформив і якою службою відправлено.

SELECT
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    CONCAT(e.FirstName, ' ', e.LastName) AS employee,
    s.ShipperName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Shippers  s ON o.ShipperID  = s.ShipperID
WHERE o.OrderID = 10248;
-- | OrderID | OrderDate  | CustomerName | employee        | ShipperName      |
-- |   10248 | 1996-07-04 | Wilman Kala  | Steven Buchanan | Federal Shipping |


-- ============================================================
-- 3. «Ланцюжок» таблиць: чек замовлення
-- ============================================================
-- Сценарій: клієнт просить надіслати чек за замовлення 10250 —
-- товари, їхні категорії, кількість і суму за кожен рядок.
-- Orders -> OrderDetails -> Products -> Categories

SELECT
    od.OrderID,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    p.Price,
    od.Quantity * p.Price AS line_total
FROM OrderDetails od
JOIN Products   p   ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE od.OrderID = 10250;
-- | OrderID | ProductName                      | CategoryName | Quantity | Price | line_total |
-- |   10250 | Jack's New England Clam Chowder  | Seafood      |       10 |  9.65 |       96.5 |
-- |   10250 | Manjimup Dried Apples            | Produce      |       35 |    53 |       1855 |
-- |   10250 | Louisiana Fiery Hot Pepper Sauce | Condiments   |       15 | 21.05 |     315.75 |


-- ============================================================
-- 4. JOIN + GROUP BY: аналітика з кількох таблиць
-- ============================================================
-- Сценарій: директор з продажу хоче рейтинг працівників за виручкою.
-- Виручка = сума (кількість × ціна) за всіма рядками всіх їхніх замовлень.

SELECT
    CONCAT(e.FirstName, ' ', e.LastName)  AS employee,
    COUNT(DISTINCT o.OrderID)             AS orders,
    ROUND(SUM(od.Quantity * p.Price), 2)  AS revenue
FROM Employees e
JOIN Orders       o  ON o.EmployeeID = e.EmployeeID
JOIN OrderDetails od ON od.OrderID   = o.OrderID
JOIN Products     p  ON p.ProductID  = od.ProductID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY revenue DESC;
-- | employee         | orders | revenue  |
-- | Margaret Peacock |     40 | 105696.5 |
-- | Nancy Davolio    |     29 | 57690.39 |
-- | Janet Leverling  |     31 | 42838.35 |
-- | Robert King      |     14 |  39772.3 |
-- | Laura Callahan   |     27 | 39309.38 |
-- | Andrew Fuller    |     20 | 32503.16 |
-- | Steven Buchanan  |     11 |  27480.8 |
-- | Michael Suyama   |     18 | 25399.25 |
-- | Anne Dodsworth   |      6 |  15734.1 |
-- 9 рядків
-- Adam West (EmployeeID = 10) у рейтингу немає: INNER JOIN відкинув його,
-- бо в нього немає замовлень.


-- ============================================================
-- 5. Умова в ON не обовʼязково «id = id»
-- ============================================================
-- Сценарій: логіст шукає пари «клієнт — постачальник» з одного міста,
-- щоб організувати доставку без посередників.

SELECT c.CustomerName, s.SupplierName, c.City
FROM Customers c
JOIN Suppliers s ON c.City = s.City AND c.Country = s.Country
ORDER BY c.City;
-- | CustomerName           | SupplierName                    | City      |
-- | Alfreds Futterkiste    | Heli Süßwaren GmbH &amp; Co. KG | Berlin    |
-- | Mère Paillarde         | Ma Maison                       | Montréal  |
-- | Paris spécialités      | Aux joyeux ecclésiastiques      | Paris     |
-- | Spécialités du monde   | Aux joyeux ecclésiastiques      | Paris     |
-- | Comércio Mineiro       | Refrescos Americanas LTDA       | São Paulo |
-- | Familia Arquibaldo     | Refrescos Americanas LTDA       | São Paulo |
-- | Queen Cozinha          | Refrescos Americanas LTDA       | São Paulo |
-- | Tradição Hipermercados | Refrescos Americanas LTDA       | São Paulo |
-- 8 рядків («&amp;» — так записано в самих даних w3schools)

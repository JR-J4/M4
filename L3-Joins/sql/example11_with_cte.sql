/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: оператор WITH (CTE — Common Table Expression, іменований підзапит)
 *
 * Починаючи з MySQL 8, підзапити не обовʼязково «засовувати» всередину запиту.
 * WITH дає підзапиту імʼя, і далі до нього звертаються як до звичайної таблиці.
 * Можна оголосити кілька CTE через кому, і кожна наступна може посилатися на попередні.
 *
 * Синтаксис:
 *   WITH імʼя AS (запит)
 *   SELECT ... FROM імʼя ...
 *
 *   WITH імʼя(колонка1, колонка2, ...) AS (запит)   -- з явними іменами колонок
 *
 *   WITH a AS (...),
 *        b AS (SELECT ... FROM a ...)               -- b використовує a
 *   SELECT ...
 *
 * Аналогія: рецепт, де спочатку окремо готують «соус» і «тісто» з назвами,
 * а потім пишуть «змішати соус з тістом» замість переписувати весь процес.
 *
 * Де застосовують:
 *   - складні звіти, розбиті на зрозумілі кроки;
 *   - коли той самий підзапит потрібен двічі;
 *   - WITH RECURSIVE — дерева та ієрархії (категорії, оргструктура).
 */


-- ============================================================
-- 1. Простий WITH замість підзапиту в FROM
-- ============================================================
-- Сценарій: топ-5 клієнтів за кількістю замовлень (як у example10, блок 2),
-- але підзапит винесено нагору й названо.

WITH customer_stats AS (
    SELECT CustomerID, COUNT(*) AS orders, MAX(OrderDate) AS last_order
    FROM Orders
    GROUP BY CustomerID
)

SELECT c.CustomerName, c.Country, cs.orders, cs.last_order
FROM Customers c
JOIN customer_stats cs ON cs.CustomerID = c.CustomerID
ORDER BY cs.orders DESC, c.CustomerName
LIMIT 5;
-- | CustomerName                 | Country | orders | last_order |
-- | Ernst Handel                 | Austria |     10 | 1997-02-11 |
-- | QUICK-Stop                   | Germany |      7 | 1997-01-17 |
-- | Rattlesnake Canyon Grocery   | USA     |      7 | 1997-01-01 |
-- | Wartian Herkku               | Finland |      7 | 1997-02-05 |
-- | Hungry Owl All-Night Grocers | Ireland |      6 | 1997-01-29 |


-- ============================================================
-- 2. Один CTE — двічі в запиті
-- ============================================================
-- Сценарій: «великі» замовлення (сума > 3 × середня). У example10 підзапит
-- довелося писати двічі, тут — один раз.

WITH order_totals AS (
    SELECT od.OrderID, SUM(od.Quantity * p.Price) AS order_total
    FROM OrderDetails od
    JOIN Products p ON p.ProductID = od.ProductID
    GROUP BY od.OrderID
)
SELECT ot.OrderID, c.CustomerName, ROUND(ot.order_total, 2) AS order_total
FROM order_totals ot
JOIN Orders o    ON o.OrderID    = ot.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE ot.order_total > 3 * (SELECT AVG(order_total) FROM order_totals)
ORDER BY ot.order_total DESC;
-- | OrderID | CustomerName          | order_total |
-- |   10372 | Queen Cozinha         |     15353.6 |
-- |   10424 | Mère Paillarde        |     14366.5 |
-- |     ... | ...                   |         ... |
-- |   10329 | Split Rail Beer & Ale |     6025.12 |
-- 10 рядків — той самий результат, що в example10, блок 4


-- ============================================================
-- 3. Кілька CTE, які посилаються один на одного
-- ============================================================
-- Сценарій: керівник продажів хоче по кожній країні клієнтів знати виручку
-- і хто з працівників приніс там найбільше.
-- Крок 1 — виручка кожного замовлення; крок 2 — виручка «країна × працівник»;
-- крок 3 — найкращий працівник у кожній країні.

WITH order_totals AS (
    SELECT od.OrderID, SUM(od.Quantity * p.Price) AS order_total
    FROM OrderDetails od
    JOIN Products p ON p.ProductID = od.ProductID
    GROUP BY od.OrderID
),
country_employee AS (
    SELECT c.Country, o.EmployeeID, SUM(ot.order_total) AS revenue
    FROM order_totals ot
    JOIN Orders o    ON o.OrderID    = ot.OrderID
    JOIN Customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.Country, o.EmployeeID
),
country_best AS (
    SELECT Country, MAX(revenue) AS best_revenue, SUM(revenue) AS country_revenue
    FROM country_employee
    GROUP BY Country
)
SELECT
    cb.Country,
    ROUND(cb.country_revenue, 2)          AS country_revenue,
    CONCAT(e.FirstName, ' ', e.LastName)  AS best_employee,
    ROUND(cb.best_revenue, 2)             AS employee_revenue
FROM country_best cb
JOIN country_employee ce ON ce.Country = cb.Country AND ce.revenue = cb.best_revenue
JOIN Employees e         ON e.EmployeeID = ce.EmployeeID
ORDER BY cb.country_revenue DESC
LIMIT 5;
-- | Country | country_revenue | best_employee    | employee_revenue |
-- | USA     |        69611.75 | Margaret Peacock |         22552.88 |
-- | Austria |        51671.96 | Robert King      |            13427 |
-- | Germany |        47241.82 | Margaret Peacock |         18330.97 |
-- | Brazil  |        40215.25 | Steven Buchanan  |          15353.6 |
-- | Canada  |        31326.35 | Robert King      |          14366.5 |


-- ============================================================
-- 4. WITH з явним списком колонок
-- ============================================================
-- Сценарій: звіт «служба доставки — кількість замовлень». Імена колонок CTE
-- задаємо в дужках після імені — тоді в самому запиті аліаси не потрібні.

WITH shipper_load(shipper_id, orders) AS (
    SELECT ShipperID, COUNT(*)
    FROM Orders
    GROUP BY ShipperID
)
SELECT s.ShipperName, sl.orders
FROM Shippers s
JOIN shipper_load sl ON sl.shipper_id = s.ShipperID
ORDER BY sl.orders DESC;
-- | ShipperName      | orders |
-- | United Package   |     74 |
-- | Federal Shipping |     68 |
-- | Speedy Express   |     54 |


-- ============================================================
-- 5. Бонус: WITH RECURSIVE — календар без пропусків
-- ============================================================
-- Сценарій: аналітик будує графік замовлень за перший тиждень роботи магазину.
-- У дні без замовлень у таблиці Orders рядків немає, а на графіку потрібен 0.
-- Рекурсивний CTE генерує всі дати, LEFT JOIN приклеює до них замовлення.

WITH RECURSIVE calendar(day) AS (
    SELECT DATE('1996-07-04')
    UNION ALL
    SELECT day + INTERVAL 1 DAY
    FROM calendar
    WHERE day < '1996-07-12'
)
SELECT cal.day, DAYNAME(cal.day) AS weekday, COUNT(o.OrderID) AS orders
FROM calendar cal
LEFT JOIN Orders o ON o.OrderDate = cal.day
GROUP BY cal.day
ORDER BY cal.day;
-- | day        | weekday   | orders |
-- | 1996-07-04 | Thursday  |      1 |
-- | 1996-07-05 | Friday    |      1 |
-- | 1996-07-06 | Saturday  |      0 |   <- рядків в Orders немає, але день у звіті є
-- | 1996-07-07 | Sunday    |      0 |
-- | 1996-07-08 | Monday    |      2 |
-- | 1996-07-09 | Tuesday   |      1 |
-- | 1996-07-10 | Wednesday |      1 |
-- | 1996-07-11 | Thursday  |      1 |
-- | 1996-07-12 | Friday    |      1 |

/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: підзапит, який повертає ТАБЛИЦЮ (derived table)
 *
 * Підзапит у FROM / JOIN поводиться як тимчасова таблиця. Своєї назви в нього
 * немає, тому аліас ОБОВʼЯЗКОВИЙ (у MySQL без нього — ERROR 1248:
 * Every derived table must have its own alias).
 *
 * Синтаксис:
 *   SELECT ...
 *   FROM таблиця t
 *   JOIN (SELECT ... FROM ... GROUP BY ...) аліас ON умова
 *
 * Аналогія: спочатку на чернетці рахуєте підсумки по кожному клієнту,
 * а потім переписуєте їх у чистовий звіт поруч з іменами.
 *
 * Де застосовують:
 *   - JOIN з уже згрупованими / порахованими даними;
 *   - «підготувати» таблицю перед JOIN: замінити NULL, обрізати, перейменувати;
 *   - фільтр за агрегатом агрегату («середня кількість замовлень на клієнта»).
 */


-- ============================================================
-- 1. JOIN з підготовленою таблицею (аналог прикладу з лекції)
-- ============================================================
-- Сценарій з лекції: «усі завислі задачі без виконавця призначити на директора».
-- Аналог у w3schools: у звіті «замовлення — співробітник» усі замовлення
-- клієнта Ernst Handel (CustomerID = 20) передаються на Andrew Fuller (EmployeeID = 2),
-- бо його менеджер звільнився. Підзапит «підміняє» EmployeeID, а JOIN бере вже нове значення.

SELECT o.OrderID, o.CustomerID, o.old_employee_id, CONCAT(e.FirstName, ' ', e.LastName) AS responsible
FROM Employees e
JOIN (
    SELECT
        OrderID,
        CustomerID,
        EmployeeID                         AS old_employee_id,
        IF(CustomerID = 20, 2, EmployeeID) AS EmployeeID
    FROM Orders
) o ON o.EmployeeID = e.EmployeeID
WHERE o.CustomerID = 20
ORDER BY o.OrderID;
-- | OrderID | CustomerID | old_employee_id | responsible   |
-- |   10258 |         20 |               1 | Andrew Fuller |
-- |   10263 |         20 |               9 | Andrew Fuller |
-- |   10351 |         20 |               1 | Andrew Fuller |
-- |   10368 |         20 |               2 | Andrew Fuller |
-- |   10382 |         20 |               4 | Andrew Fuller |
-- |   10390 |         20 |               6 | Andrew Fuller |
-- |   10402 |         20 |               8 | Andrew Fuller |
-- |   10403 |         20 |               4 | Andrew Fuller |
-- |   10430 |         20 |               4 | Andrew Fuller |
-- |   10442 |         20 |               3 | Andrew Fuller |
-- Дані в Orders не змінилися — підміна існує лише в результаті запиту.


-- ============================================================
-- 2. JOIN з агрегованими даними
-- ============================================================
-- Сценарій: відділ лояльності хоче топ-5 клієнтів за кількістю замовлень
-- з повною інформацією про клієнта.

SELECT c.CustomerName, c.Country, stats.orders, stats.last_order
FROM Customers c
JOIN (
    SELECT CustomerID, COUNT(*) AS orders, MAX(OrderDate) AS last_order
    FROM Orders
    GROUP BY CustomerID
) stats ON stats.CustomerID = c.CustomerID
ORDER BY stats.orders DESC, c.CustomerName
LIMIT 5;
-- | CustomerName                 | Country | orders | last_order |
-- | Ernst Handel                 | Austria |     10 | 1997-02-11 |
-- | QUICK-Stop                   | Germany |      7 | 1997-01-17 |
-- | Rattlesnake Canyon Grocery   | USA     |      7 | 1997-01-01 |
-- | Wartian Herkku               | Finland |      7 | 1997-02-05 |
-- | Hungry Owl All-Night Grocers | Ireland |      6 | 1997-01-29 |


-- ============================================================
-- 3. Агрегат від агрегату
-- ============================================================
-- Сценарій: аналітик хоче знати, скільки в середньому замовлень припадає
-- на одного клієнта, який хоч раз щось купив.
-- AVG(COUNT(*)) написати не можна — спершу рахуємо COUNT у підзапиті.

SELECT ROUND(AVG(orders), 2) AS avg_orders_per_customer,
       MAX(orders)           AS max_orders
FROM (
    SELECT CustomerID, COUNT(*) AS orders
    FROM Orders
    GROUP BY CustomerID
) per_customer;
-- | avg_orders_per_customer | max_orders |
-- |                    2.65 |         10 |


-- ============================================================
-- 4. Сума замовлення і порівняння з середнім чеком
-- ============================================================
-- Сценарій: менеджер хоче список «великих» замовлень — сума яких
-- більша за середню суму замовлення в 3+ рази.
-- Підзапит-таблиця totals використовується двічі: у FROM і в скалярному підзапиті.

SELECT totals.OrderID, c.CustomerName, ROUND(totals.order_total, 2) AS order_total
FROM (
    SELECT od.OrderID, SUM(od.Quantity * p.Price) AS order_total
    FROM OrderDetails od
    JOIN Products p ON p.ProductID = od.ProductID
    GROUP BY od.OrderID
) totals
JOIN Orders o    ON o.OrderID    = totals.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE totals.order_total > 3 * (
    SELECT AVG(t.order_total)
    FROM (
        SELECT od.OrderID, SUM(od.Quantity * p.Price) AS order_total
        FROM OrderDetails od
        JOIN Products p ON p.ProductID = od.ProductID
        GROUP BY od.OrderID
    ) t
)
ORDER BY totals.order_total DESC;
-- | OrderID | CustomerName          | order_total |
-- |   10372 | Queen Cozinha         |     15353.6 |
-- |   10424 | Mère Paillarde        |     14366.5 |
-- |   10417 | Simons bistro         |       14104 |
-- |   10353 | Piccolo und mehr      |       13427 |
-- |   10360 | Blondel père et fils  |     9244.25 |
-- |   10324 | Save-a-lot Markets    |     7698.45 |
-- |   10440 | Save-a-lot Markets    |     7246.01 |
-- |   10430 | Ernst Handel          |        7245 |
-- |   10351 | Ernst Handel          |      7103.6 |
-- |   10329 | Split Rail Beer & Ale |     6025.12 |
-- 10 рядків
-- Один і той самий підзапит записаний двічі — незручно й легко помилитися.
-- Оператор WITH розвʼязує цю проблему (example11_with_cte.sql).

/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: LEFT JOIN і RIGHT JOIN (OUTER JOIN)
 *
 * INNER JOIN губить рядки без пари. OUTER JOIN їх зберігає,
 * а колонки «відсутньої» таблиці заповнює NULL.
 *
 * Синтаксис:
 *   таблиця1 LEFT  [OUTER] JOIN таблиця2 ON умова   -- усі рядки з ЛІВОЇ (таблиця1)
 *   таблиця1 RIGHT [OUTER] JOIN таблиця2 ON умова   -- усі рядки з ПРАВОЇ (таблиця2)
 *
 * A RIGHT JOIN B — те саме, що B LEFT JOIN A. На практиці майже завжди пишуть LEFT JOIN.
 *
 * Аналогія: список гостей на весілля і список подарунків. LEFT JOIN — «всі гості,
 * і поруч, що кожен подарував». Хто нічого не приніс — усе одно в списку, з порожньою клітинкою.
 *
 * Де застосовують:
 *   - «клієнти, які нічого не купували» (для розсилки зі знижкою);
 *   - «товари, яких ніхто не замовляв» (кандидати на розпродаж);
 *   - звіти, де нулі теж важливі: «кількість замовлень на кожного працівника, навіть 0».
 */



SELECT p.ProductID, p.ProductName, c.CategoryName
FROM Categories c
JOIN Products p on p.CategoryID = c.CategoryID
ORDER BY ProductID;


SELECT c.CustomerID, c.CustomerName, OrderID
FROM Customers c
LEFT JOIN Orders o on c.CustomerID = o.CustomerID
WHERE OrderID is null ;



-- ============================================================
-- 1. INNER JOIN проти LEFT JOIN
-- ============================================================
-- Сценарій: директор хоче бачити ВСІХ працівників і кількість їхніх замовлень.

-- INNER JOIN — працівник без замовлень зникає:
SELECT e.EmployeeID, e.LastName, COUNT(o.OrderID) AS orders
FROM Employees e
JOIN Orders o ON o.EmployeeID = e.EmployeeID
GROUP BY e.EmployeeID
ORDER BY e.EmployeeID;
-- | EmployeeID | LastName  | orders |
-- |          1 | Davolio   |     29 |
-- |          2 | Fuller    |     20 |
-- |          3 | Leverling |     31 |
-- |          4 | Peacock   |     40 |
-- |          5 | Buchanan  |     11 |
-- |          6 | Suyama    |     18 |
-- |          7 | King      |     14 |
-- |          8 | Callahan  |     27 |
-- |          9 | Dodsworth |      6 |
-- 9 рядків — West зник

-- LEFT JOIN — West на місці з нулем:
SELECT e.EmployeeID, e.LastName, COUNT(o.OrderID) AS orders
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID
GROUP BY e.EmployeeID, e.LastName
ORDER BY e.EmployeeID;
-- | EmployeeID | LastName  | orders |
-- |          1 | Davolio   |     29 |
-- |          2 | Fuller    |     20 |
-- |          3 | Leverling |     31 |
-- |          4 | Peacock   |     40 |
-- |          5 | Buchanan  |     11 |
-- |          6 | Suyama    |     18 |
-- |          7 | King      |     14 |
-- |          8 | Callahan  |     27 |
-- |          9 | Dodsworth |      6 |
-- |         10 | West      |      0 |
-- Увага: COUNT(o.OrderID), а не COUNT(*). COUNT(*) порахував би рядок із NULL як 1.


-- ============================================================
-- 2. Що саме повертає LEFT JOIN для рядка без пари
-- ============================================================
-- Сценарій: подивитися «сирі» рядки для двох працівників — з замовленнями і без.

SELECT e.EmployeeID, e.LastName, o.OrderID, o.OrderDate
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID
WHERE e.EmployeeID IN (9, 10)
ORDER BY e.EmployeeID, o.OrderID;
-- | EmployeeID | LastName  | OrderID | OrderDate  |
-- |          9 | Dodsworth |   10255 | 1996-07-12 |
-- |          9 | Dodsworth |   10263 | 1996-07-23 |
-- |          9 | Dodsworth |   10324 | 1996-10-08 |
-- |          9 | Dodsworth |   10331 | 1996-10-16 |
-- |          9 | Dodsworth |   10386 | 1996-12-18 |
-- |          9 | Dodsworth |   10411 | 1997-01-10 |
-- |         10 | West      |    NULL | NULL       |   <- пари немає, колонки Orders = NULL


-- ============================================================
-- 3. LEFT JOIN ... WHERE права.id IS NULL — «рядки без пари»
-- ============================================================
-- Сценарій: маркетолог хоче надіслати промокод клієнтам,
-- які зареєструвалися, але не зробили жодного замовлення.

SELECT c.CustomerID, c.CustomerName, c.Country
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL
ORDER BY c.CustomerID;
-- | CustomerID | CustomerName                         | Country   |
-- |          1 | Alfreds Futterkiste                  | Germany   |
-- |          6 | Blauer See Delikatessen              | Germany   |
-- |         12 | Cactus Comidas para llevar           | Argentina |
-- |         22 | FISSA Fabrica Inter. Salchichas S.A. | Spain     |
-- |        ... | ...                                  | ...       |
-- |         82 | Trail's Head Gourmet Provisioners    | USA       |
-- |         92 | Nullable Customer                    | NULL      |
-- |         93 | Nullable Customer                    | NULL      |
-- 19 рядків (92 і 93 — тестові записи з порожніми полями, вони є в самому дампі)

-- Сценарій: менеджер хоче знати, які клієнти з Німеччини нічого не замовляли.
SELECT c.CustomerName, c.City
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL
  AND c.Country = 'Germany';
-- | CustomerName            | City     |
-- | Alfreds Futterkiste     | Berlin   |
-- | Blauer See Delikatessen | Mannheim |


-- ============================================================
-- 4. RIGHT JOIN — дзеркало LEFT JOIN
-- ============================================================
-- Сценарій: той самий звіт «працівник — кількість замовлень»,
-- але таблиці записані в іншому порядку. Результат як у блоці 1 з LEFT JOIN.

SELECT e.EmployeeID, e.LastName, COUNT(o.OrderID) AS orders
FROM Orders o
RIGHT JOIN Employees e ON o.EmployeeID = e.EmployeeID
GROUP BY e.EmployeeID, e.LastName
ORDER BY e.EmployeeID;
-- 10 рядків, як у блоці 1 з LEFT JOIN (West — 0)


-- ============================================================
-- 5. Пастка: фільтр по правій таблиці у WHERE «вбиває» LEFT JOIN
-- ============================================================
-- Сценарій: директор хоче кількість замовлень кожного працівника лише за 1997 рік,
-- і щоб працівники без замовлень у 1997-му теж були в списку з нулем.

-- Неправильно: умова у WHERE відкидає рядки з NULL, LEFT JOIN стає INNER JOIN.
SELECT e.EmployeeID, e.LastName, COUNT(o.OrderID) AS orders_1997
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID
WHERE YEAR(o.OrderDate) = 1997
GROUP BY e.EmployeeID, e.LastName
ORDER BY e.EmployeeID;
-- | EmployeeID | LastName  | orders_1997 |
-- |          1 | Davolio   |           3 |
-- |          2 | Fuller    |           4 |
-- |          3 | Leverling |          13 |
-- |          4 | Peacock   |           9 |
-- |          6 | Suyama    |           3 |
-- |          7 | King      |           3 |
-- |          8 | Callahan  |           8 |
-- |          9 | Dodsworth |           1 |
-- 8 рядків — зникли і West, і Buchanan (у 1997-му в нього замовлень немає)

-- Правильно: умову по правій таблиці переносимо в ON.
SELECT e.EmployeeID, e.LastName, COUNT(o.OrderID) AS orders_1997
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID
                  AND YEAR(o.OrderDate) = 1997
GROUP BY e.EmployeeID, e.LastName
ORDER BY e.EmployeeID;
-- | EmployeeID | LastName  | orders_1997 |
-- |          1 | Davolio   |           3 |
-- |          2 | Fuller    |           4 |
-- |          3 | Leverling |          13 |
-- |          4 | Peacock   |           9 |
-- |          5 | Buchanan  |           0 |
-- |          6 | Suyama    |           3 |
-- |          7 | King      |           3 |
-- |          8 | Callahan  |           8 |
-- |          9 | Dodsworth |           1 |
-- |         10 | West      |           0 |
-- 10 рядків

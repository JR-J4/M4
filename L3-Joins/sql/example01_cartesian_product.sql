/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: запит до двох таблиць одразу та декартів добуток
 *
 * Якщо в одній таблиці зберігаються ID з іншої таблиці, вона називається ЗАЛЕЖНОЮ.
 * У w3schools: Orders зберігає CustomerID, EmployeeID, ShipperID —
 * тобто Orders залежить від Customers, Employees і Shippers.
 *
 * Синтаксис:
 *   SELECT колонки
 *   FROM таблиця1, таблиця2, ..., таблицяN
 *   [WHERE умова_звʼязку]
 *
 * Без умови SQL склеює КОЖЕН рядок першої таблиці з КОЖНИМ рядком другої —
 * це декартів добуток: 10 рядків × 3 рядки = 30 рядків.
 *
 * Аналогія: у вас 10 працівників і 3 курʼєрські служби. Якщо скласти
 * «всі можливі пари», вийде 30 пар — навіть ті, що ніколи не працювали разом.
 * Умова WHERE залишає тільки ті пари, які справді повʼязані.
 *
 * Де застосовують:
 *   - навмисно декартів добуток потрібен рідко: згенерувати всі комбінації
 *     (розміри × кольори товару, дні × зміни в графіку);
 *   - частіше це ПОМИЛКА: забули умову звʼязку, і запит повернув мільйони рядків.
 */


-- ============================================================
-- 1. Декартів добуток: кожен з кожним
-- ============================================================
-- Сценарій: HR хоче скласти «матрицю» — кожен працівник × кожна курʼєрська служба,
-- щоб потім відмітити, хто з ким має договір. Тут декартів добуток — те, що треба.

SELECT COUNT(*) AS employees
FROM Employees;
-- 10

SELECT COUNT(*) AS shippers
FROM Shippers;
-- 3

SELECT COUNT(*) AS pairs
FROM Employees, Shippers;
-- 30  (10 × 3)

SELECT Employees.EmployeeID, Employees.LastName, Shippers.ShipperName
FROM Employees, Shippers
ORDER BY Shippers.ShipperID, Employees.EmployeeID;
-- | EmployeeID | LastName  | ShipperName    |
-- |          1 | Davolio   | Speedy Express |
-- |          2 | Fuller    | Speedy Express |
-- |        ... | ...       | Speedy Express |
-- |         10 | West      | Speedy Express |
-- |          1 | Davolio   | United Package |   <- працівники пішли по другому колу
-- |          2 | Fuller    | United Package |


-- ============================================================
-- 2. Чому декартів добуток зазвичай — помилка
-- ============================================================
-- Сценарій: менеджер хоче список замовлень з іменами клієнтів.
-- Новачок пише запит до двох таблиць і забуває умову звʼязку.

SELECT COUNT(*) AS orders
FROM Orders;
-- 196

SELECT COUNT(*) AS customers
FROM Customers;
-- 93

SELECT COUNT(*) AS rows_without_condition
FROM Orders, Customers;
-- 18228  (196 × 93) — кожне замовлення «приписане» кожному клієнту.
-- Більшість цих рядків безглузді: замовлення 10248 зробив один клієнт, а не 93.


-- ============================================================
-- 3. Прибираємо безглузді рядки за допомогою WHERE
-- ============================================================
-- Сценарій: той самий список «замовлення + клієнт», але правильно.
-- Залишаємо лише пари, де CustomerID у замовленні = CustomerID клієнта.

SELECT COUNT(*) AS rows_with_condition
FROM Orders, Customers
WHERE Orders.CustomerID = Customers.CustomerID;
-- 196  — рівно по одному рядку на замовлення

SELECT Orders.OrderID, Orders.OrderDate, Customers.CustomerName, Customers.Country
FROM Orders, Customers
WHERE Orders.CustomerID = Customers.CustomerID
ORDER BY Orders.OrderID
LIMIT 5;
-- | OrderID | OrderDate  | CustomerName           | Country |
-- |   10248 | 1996-07-04 | Wilman Kala            | Finland |
-- |   10249 | 1996-07-05 | Tradição Hipermercados | Brazil  |
-- |   10250 | 1996-07-08 | Hanari Carnes          | Brazil  |
-- |   10251 | 1996-07-08 | Victuailles en stock   | France  |
-- |   10252 | 1996-07-09 | Suprêmes délices       | Belgium |


-- ============================================================
-- 4. Мінус такого підходу: рядки без пари зникають
-- ============================================================
-- Сценарій: директор хоче бачити ВСІХ працівників і їхні замовлення.
-- Але працівник №10 (Adam West) ще не оформив жодного замовлення.

SELECT COUNT(DISTINCT Employees.EmployeeID) AS employees_in_result
FROM Employees, Orders
WHERE Employees.EmployeeID = Orders.EmployeeID;
-- 9  — а працівників 10!
-- West не має жодного рядка в Orders, тому WHERE його відкинув.
-- Як зберегти таких «самотніх» — див. example05_left_right_join.sql.

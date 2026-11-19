/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: псевдоніми (аліаси) колонок і таблиць
 *
 * Коли таблиць кілька, виникають дві проблеми:
 *   1) однакові імена колонок у різних таблицях (CustomerID є і в Orders, і в Customers;
 *      ContactName — і в Customers, і в Suppliers);
 *   2) довгі префікси: Customers.CustomerName, Orders.OrderDate, ...
 *
 * Синтаксис:
 *   SELECT т.колонка AS нова_назва        -- аліас колонки
 *   FROM   таблиця1 т1, таблиця2 т2      -- аліас таблиці (AS можна писати, можна ні)
 *
 * Аналогія: у класі два Олександри — вчитель кличе їх «Саша К.» і «Саша М.»,
 * щоб не плутати. Аліас таблиці — це прізвище, аліас колонки — зрозуміле імʼя.
 *
 * Де застосовують:
 *   - майже в кожному запиті з JOIN — короткі аліаси (o, c, e) стали стандартом;
 *   - аліаси колонок — щоб звіт / Java-код отримав зрозумілі імена (rs.getString("customer")).
 */


-- ============================================================
-- 1. Неоднозначна колонка — помилка
-- ============================================================
-- Сценарій: розробник хоче вивести CustomerID разом з іменем клієнта.
-- Колонка CustomerID є в обох таблицях, і MySQL не знає, яку брати.

-- SELECT CustomerID, CustomerName, OrderDate
-- FROM Orders, Customers
-- WHERE Orders.CustomerID = Customers.CustomerID;
-- ERROR 1052 (23000): Column 'CustomerID' in field list is ambiguous

-- Виправлення — вказати таблицю явно:
SELECT Orders.CustomerID, CustomerName, OrderDate
FROM Orders, Customers
WHERE Orders.CustomerID = Customers.CustomerID
ORDER BY Orders.OrderID
LIMIT 3;
-- | CustomerID | CustomerName           | OrderDate  |
-- |         90 | Wilman Kala            | 1996-07-04 |
-- |         81 | Tradição Hipermercados | 1996-07-05 |
-- |         34 | Hanari Carnes          | 1996-07-08 |


-- ============================================================
-- 2. Аліаси колонок: однакові імена — різний зміст
-- ============================================================
-- Сценарій: закупівельник хоче таблицю «товар — постачальник — контактна особа».
-- У Products і Suppliers обидві назви стоять у колонках *Name, а контакт є лише
-- в Suppliers. Перейменовуємо, щоб у звіті було зрозуміло, що де.

SELECT
    Products.ProductID     AS product_id,
    Products.ProductName   AS product,
    Suppliers.SupplierName AS supplier,
    Suppliers.ContactName  AS supplier_contact
FROM
    Products,
    Suppliers
WHERE
    Products.SupplierID = Suppliers.SupplierID
ORDER BY Products.ProductID
LIMIT 4;
-- | product_id | product                      | supplier                   | supplier_contact |
-- |          1 | Chais                        | Exotic Liquid              | Charlotte Cooper |
-- |          2 | Chang                        | Exotic Liquid              | Charlotte Cooper |
-- |          3 | Aniseed Syrup                | Exotic Liquid              | Charlotte Cooper |
-- |          4 | Chef Anton's Cajun Seasoning | New Orleans Cajun Delights | Shelley Burke    |


-- ============================================================
-- 3. Аліаси таблиць: коротше й читабельніше
-- ============================================================
-- Сценарій: той самий звіт, але без довгих префіксів.
-- Після оголошення аліасу (Products p) звертатися треба саме через p.

SELECT
    p.ProductID     AS product_id,
    p.ProductName   AS product,
    s.SupplierName  AS supplier,
    s.Country       AS supplier_country
FROM
    Products p,
    Suppliers AS s
WHERE
    p.SupplierID = s.SupplierID
    AND s.Country = 'Japan';
-- | product_id | product         | supplier      | supplier_country |
-- |          9 | Mishi Kobe Niku | Tokyo Traders | Japan            |
-- |         10 | Ikura           | Tokyo Traders | Japan            |
-- |         74 | Longlife Tofu   | Tokyo Traders | Japan            |
-- |         13 | Konbu           | Mayumi's      | Japan            |
-- |         14 | Tofu            | Mayumi's      | Japan            |
-- |         15 | Genen Shouyu    | Mayumi's      | Japan            |
-- 6 рядків

-- Увага: якщо таблиці дано аліас, старе імʼя в цьому запиті вже не працює:
-- SELECT Products.ProductName FROM Products p;
-- ERROR 1054 (42S22): Unknown column 'Products.ProductName' in 'field list'


-- ============================================================
-- 4. Аліас колонки у ORDER BY
-- ============================================================
-- Сценарій: бухгалтер хоче бачити вартість кожного рядка замовлення 10248
-- (кількість × ціна), відсортовану від найдорожчого.
-- Обчислена колонка без аліасу мала б імʼя «od.Quantity * p.Price» — незручно.

SELECT
    od.OrderID,
    p.ProductName           AS product,
    od.Quantity             AS qty,
    p.Price                 AS price,
    od.Quantity * p.Price   AS line_total
FROM
    OrderDetails od,
    Products p
WHERE
    od.ProductID = p.ProductID
    AND od.OrderID = 10248
ORDER BY line_total DESC;
-- | OrderID | product                       | qty | price | line_total |
-- |   10248 | Queso Cabrales                |  12 |    21 |        252 |
-- |   10248 | Mozzarella di Giovanni        |   5 |  34.8 |        174 |
-- |   10248 | Singaporean Hokkien Fried Mee |  10 |    14 |        140 |

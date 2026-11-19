/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: підзапит, який повертає СПИСОК значень (одну колонку)
 *
 * Такий підзапит використовують з операторами IN / NOT IN, а «родич» —
 * EXISTS / NOT EXISTS — перевіряє, чи повертає підзапит хоч один рядок.
 *
 * Синтаксис:
 *   WHERE колонка IN     (SELECT колонка FROM ...)
 *   WHERE колонка NOT IN (SELECT колонка FROM ... WHERE колонка IS NOT NULL)
 *   WHERE EXISTS         (SELECT 1 FROM ... WHERE звʼязок_із_зовнішнім_запитом)
 *
 * Аналогія: охорона на вході з паперовим списком гостей. IN — «чи є ти в списку?».
 *
 * Де застосовують:
 *   - фільтр за даними з іншої таблиці без потреби виводити її колонки;
 *   - «рядки без пари» — NOT IN / NOT EXISTS або LEFT JOIN ... IS NULL.
 *
 * Як радить лекція, для «рядків без пари» LEFT JOIN часто зрозуміліший і
 * передбачуваніший. NOT IN має пастку з NULL — див. блок 4.
 */


-- ============================================================
-- 1. IN: клієнти, які замовляли через певну службу доставки
-- ============================================================
-- Сценарій: Federal Shipping змінює тарифи — треба попередити клієнтів,
-- які хоч раз нею користувалися.

SELECT CustomerName, Country
FROM Customers
WHERE CustomerID IN (
    SELECT o.CustomerID
    FROM Orders o
    JOIN Shippers s ON s.ShipperID = o.ShipperID
    WHERE s.ShipperName = 'Federal Shipping'
)
ORDER BY CustomerName
LIMIT 5;
-- | CustomerName                       | Country |
-- | Ana Trujillo Emparedados y helados | Mexico  |
-- | Around the Horn                    | UK      |
-- | B's Beverages                      | UK      |
-- | Berglunds snabbköp                 | Sweden  |
-- | Blondel père et fils               | France  |

SELECT COUNT(*) AS customers_federal
FROM Customers
WHERE CustomerID IN (
    SELECT o.CustomerID
    FROM Orders o
    JOIN Shippers s ON s.ShipperID = o.ShipperID
    WHERE s.ShipperName = 'Federal Shipping'
);
-- 42
-- Дублікати CustomerID у підзапиті не заважають: IN лише перевіряє «є чи немає».


-- ============================================================
-- 2. NOT IN: працівники без замовлень (приклад з лекції)
-- ============================================================
-- Сценарій: HR хоче знати, хто з працівників ще не оформив жодного замовлення.

SELECT EmployeeID, FirstName, LastName
FROM Employees
WHERE EmployeeID NOT IN (
    SELECT DISTINCT EmployeeID
    FROM Orders
    WHERE EmployeeID IS NOT NULL
);
-- | EmployeeID | FirstName | LastName |
-- |         10 | Adam      | West     |

-- Те саме через LEFT JOIN — варіант, який радить лекція:
SELECT e.EmployeeID, e.FirstName, e.LastName
FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID = e.EmployeeID
WHERE o.EmployeeID IS NULL;
-- | EmployeeID | FirstName | LastName |
-- |         10 | Adam      | West     |


-- ============================================================
-- 3. EXISTS / NOT EXISTS
-- ============================================================
-- Сценарій: склад хоче список постачальників, чиї товари хоч раз замовляли
-- понад 100 одиниць за одне замовлення.

SELECT s.SupplierName, s.Country
FROM Suppliers s
WHERE EXISTS (
    SELECT 1
    FROM Products p
    JOIN OrderDetails od ON od.ProductID = p.ProductID
    WHERE p.SupplierID = s.SupplierID
      AND od.Quantity > 100
);
-- | SupplierName | Country |
-- | Ma Maison    | Canada  |

-- Клієнти з Німеччини без замовлень — через NOT EXISTS:
SELECT c.CustomerName, c.City
FROM Customers c
WHERE c.Country = 'Germany'
  AND NOT EXISTS (
      SELECT 1
      FROM Orders o
      WHERE o.CustomerID = c.CustomerID
  );
-- | CustomerName            | City     |
-- | Alfreds Futterkiste     | Berlin   |
-- | Blauer See Delikatessen | Mannheim |
-- (той самий результат, що й через LEFT JOIN в example05, блок 3)


-- ============================================================
-- 4. Пастка NOT IN і NULL
-- ============================================================
-- Сценарій: у лекції в підзапиті є WHERE employee_id IS NOT NULL. Навіщо?
-- Якщо у списку для NOT IN є хоча б один NULL, порівняння «x <> NULL» дає
-- UNKNOWN, і запит повертає ПОРОЖНІЙ результат.
-- У w3schools NULL-ів у Orders немає, тож додаємо NULL у список штучно через UNION.

SELECT EmployeeID, LastName
FROM Employees
WHERE EmployeeID NOT IN (
    SELECT EmployeeID FROM Orders
    UNION
    SELECT NULL
);
-- Empty set — West зник, хоча замовлень у нього немає!

-- NOT EXISTS на NULL не зважає — результат правильний:
SELECT e.EmployeeID, e.LastName
FROM Employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.EmployeeID = e.EmployeeID
);
-- | EmployeeID | LastName |
-- |         10 | West     |

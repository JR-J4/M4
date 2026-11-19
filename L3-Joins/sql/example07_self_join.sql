/*
 * Лекція 3. SQL-запити до кількох таблиць
 * Тема: SELF JOIN — зʼєднання таблиці з самою собою
 *
 * Окремого ключового слова немає: це звичайний JOIN, де обидві сторони —
 * одна й та сама таблиця. Без аліасів тут не обійтися — інакше незрозуміло,
 * яка «копія» мається на увазі.
 *
 * Синтаксис:
 *   SELECT a.колонка, b.колонка
 *   FROM таблиця a
 *   JOIN таблиця b ON умова
 *
 * Аналогія: у класі шукаємо пари учнів, які живуть на одній вулиці, щоб
 * ходили до школи разом. Порівнюємо список учнів сам із собою.
 *
 * Де застосовують:
 *   - ієрархії: employee.manager_id -> employee.id («хто чий керівник»);
 *   - пошук дублікатів (два клієнти з однаковою адресою);
 *   - пари «сусідів» за містом, датою, ціною.
 */


-- ============================================================
-- 1. Клієнти з одного міста
-- ============================================================
-- Сценарій: курʼєр хоче обʼєднати доставки — пари клієнтів з одного міста.
-- Умова c1.CustomerID < c2.CustomerID прибирає пари «сам із собою»
-- та дзеркальні дублікати (A-B і B-A).

SELECT c1.City, c1.CustomerName AS customer_1, c2.CustomerName AS customer_2
FROM Customers c1
JOIN Customers c2 ON c1.City = c2.City
                 AND c1.CustomerID < c2.CustomerID
WHERE c1.City = 'Madrid';
-- | City   | customer_1                           | customer_2                           |
-- | Madrid | Bólido Comidas preparadas            | FISSA Fabrica Inter. Salchichas S.A. |
-- | Madrid | Bólido Comidas preparadas            | Romero y tomillo                     |
-- | Madrid | FISSA Fabrica Inter. Salchichas S.A. | Romero y tomillo                     |


-- ============================================================
-- 2. Що буде без умови «<»
-- ============================================================
-- Сценарій: та сама задача, але розробник забув відсікти зайві пари.

SELECT COUNT(*) AS pairs_without_filter
FROM Customers c1
JOIN Customers c2 ON c1.City = c2.City
WHERE c1.City = 'Madrid';
-- 9  — 3 клієнти × 3: кожен «у парі сам із собою» + кожна пара двічі (A-B і B-A)

SELECT COUNT(*) AS pairs_with_filter
FROM Customers c1
JOIN Customers c2 ON c1.City = c2.City
                 AND c1.CustomerID < c2.CustomerID
WHERE c1.City = 'Madrid';
-- 3


-- ============================================================
-- 3. Товари однієї категорії, дорожчі за інший
-- ============================================================
-- Сценарій: продавець пропонує апсейл — для «Chang» показати
-- дорожчі напої з тієї ж категорії.

SELECT base.ProductName AS current_product, base.Price AS current_price,
       better.ProductName AS upsell, better.Price AS upsell_price
FROM Products base
JOIN Products better ON better.CategoryID = base.CategoryID
                    AND better.Price > base.Price
WHERE base.ProductName = 'Chang'
ORDER BY better.Price;
-- | current_product | current_price | upsell        | upsell_price |
-- | Chang           |            19 | Ipoh Coffee   |           46 |
-- | Chang           |            19 | Côte de Blaye |        263.5 |


-- ============================================================
-- 4. Повторні замовлення клієнта в той самий день
-- ============================================================
-- Сценарій: аналітик шукає підозрілі випадки — клієнт оформив
-- два різні замовлення в той самий день (можливо, дубль).

SELECT o1.CustomerID, o1.OrderDate, o1.OrderID AS order_1, o2.OrderID AS order_2
FROM Orders o1
JOIN Orders o2 ON o1.CustomerID = o2.CustomerID
              AND o1.OrderDate  = o2.OrderDate
              AND o1.OrderID    < o2.OrderID;
-- | CustomerID | OrderDate  | order_1 | order_2 |
-- |         10 | 1997-01-10 |   10410 |   10411 |

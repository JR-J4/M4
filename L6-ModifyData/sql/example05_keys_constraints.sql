/*
 * Лекція 6. Зміна даних в таблиці: insert, update, delete
 * Тема: ключі та обмеження (constraints)
 *
 *   PRIMARY KEY     унікальний ідентифікатор рядка (податковий номер)
 *   UNIQUE          значення не повторюються (номер паспорта — може змінитися)
 *   NOT NULL        поле обов'язкове
 *   DEFAULT x       значення, якщо його не передали
 *   AUTO_INCREMENT  id видає сервер
 *   FOREIGN KEY (колонка) REFERENCES таблиця(колонка)
 *       [ON DELETE RESTRICT | CASCADE | SET NULL]
 *       [ON UPDATE RESTRICT | CASCADE | SET NULL]
 *
 * Аналогія: охоронець на вході — без перепустки (NOT NULL) не пустить,
 * двох людей з одним пропуском (UNIQUE) не пустить, на неіснуючий відділ
 * (FOREIGN KEY) не запише.
 *
 * Скрипт працює на власних таблицях l6_department і l6_worker.
 */


DROP TABLE IF EXISTS l6_worker;
DROP TABLE IF EXISTS l6_department;

CREATE TABLE l6_department (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE l6_worker (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(50) NOT NULL,
    passport      CHAR(8) UNIQUE,
    salary        DECIMAL(10, 2) DEFAULT 1000,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES l6_department (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

INSERT INTO l6_department (name)
VALUES ('Sales'), ('IT');

INSERT INTO l6_worker (name, passport, department_id)
VALUES ('Olena', 'AA111111', 1),
       ('Taras', 'BB222222', 2),
       ('Ivan',  'CC333333', 2);


-- ============================================================
-- 1. DEFAULT і AUTO_INCREMENT
-- ============================================================
-- id та salary не передавали — сервер підставив сам.

SELECT *
FROM l6_worker;
-- | id | name  | passport | salary  | department_id |
-- |  1 | Olena | AA111111 | 1000.00 |             1 |
-- |  2 | Taras | BB222222 | 1000.00 |             2 |
-- |  3 | Ivan  | CC333333 | 1000.00 |             2 |


-- ============================================================
-- 2. Обмеження не пускають неправильні дані
-- ============================================================
-- Розкоментуйте рядок, щоб побачити помилку.

-- INSERT INTO l6_worker (passport) VALUES ('DD444444');
-- ERROR 1364: Field 'name' doesn't have a default value         (NOT NULL)

-- INSERT INTO l6_worker (name, passport) VALUES ('Petro', 'AA111111');
-- ERROR 1062: Duplicate entry 'AA111111' for key 'l6_worker.passport'   (UNIQUE)

-- INSERT INTO l6_worker (name, department_id) VALUES ('Petro', 99);
-- ERROR 1452: Cannot add or update a child row: a foreign key constraint fails   (відділу 99 немає)


-- ============================================================
-- 3. ON UPDATE CASCADE: id змінився — посилання теж
-- ============================================================
-- Сценарій: відділу IT змінили id з 2 на 20.

UPDATE l6_department
SET id = 20
WHERE id = 2;

SELECT name, department_id
FROM l6_worker;
-- | name  | department_id |
-- | Olena |             1 |
-- | Taras |            20 |   оновилось автоматично
-- | Ivan  |            20 |


-- ============================================================
-- 4. ON DELETE SET NULL: відділ закрили — працівники лишились
-- ============================================================

DELETE FROM l6_department
WHERE id = 20;

SELECT name, department_id
FROM l6_worker;
-- | name  | department_id |
-- | Olena |             1 |
-- | Taras |          NULL |   працівник є, відділу немає
-- | Ivan  |          NULL |

-- Інші варіанти:
--   RESTRICT / NO ACTION (за замовчуванням) — заборонити видалення, поки є посилання.
--                         Так налаштовано в w3schools: Customers з замовленнями не видалити.
--   CASCADE             — видалити і залежні рядки. Обережно, див. example08.
--   SET DEFAULT         — у MySQL (InnoDB) не підтримується, хоч і є в лекції.


-- Прибираємо за собою (спершу таблицю, що посилається)
DROP TABLE IF EXISTS l6_worker;
DROP TABLE IF EXISTS l6_department;

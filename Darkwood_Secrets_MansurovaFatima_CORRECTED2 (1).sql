/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Мансурова Фатима
 * Дата: 02.07.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков


-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT 
COUNT (*) as total_players,
SUM (payer) as paying_players,
AVG (payer) as paying_ratio
FROM fantasy.users;
  
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
WITH unique_players AS (
    SELECT 
        id,
        race_id,
        payer
    FROM 
        fantasy.users
    GROUP BY 
        id, race_id, payer
)
SELECT 
    r.race AS race_name,  -- Название расы
    COUNT(DISTINCT u.id) AS total_players,  -- Общее количество уникальных игроков по расе
    SUM(u.payer) AS paying_players,  -- Количество платящих игроков по расе
    CAST(SUM(u.payer) AS FLOAT) / COUNT(DISTINCT u.id) AS paying_ratio  -- Доля платящих игроков по расе
FROM 
    unique_players u
JOIN 
    fantasy.race r ON u.race_id = r.race_id
GROUP BY 
    r.race;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT 
    COUNT(*) AS total_purchases,  -- Общее количество покупок
    SUM(amount) AS total_amount,  -- Суммарная стоимость всех покупок
    MIN(amount) AS min_amount,  -- Минимальная стоимость покупки
    MAX(amount) AS max_amount,  -- Максимальная стоимость покупки
    AVG(amount) AS avg_amount,  -- Среднее значение стоимости покупки
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,  -- Медиана стоимости покупки
    STDDEV(amount) AS stddev_amount  -- Стандартное отклонение стоимости покупки
FROM 
    fantasy.events;
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT 
    COUNT(*) AS zero_amount_count,  -- Абсолютное количество покупок с нулевой стоимостью
    CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM fantasy.events) AS zero_amount_ratio  -- Доля покупок с нулевой стоимостью
FROM 
    fantasy.events
WHERE 
    amount = 0;
-- 2.3: Популярные эпические предметы:
SELECT 
    i.game_items AS item_name,  -- Название эпического предмета
    COUNT(e.transaction_id) AS total_sales,  -- Общее количество продаж
    COUNT(e.transaction_id) * 1.0 / (SELECT COUNT(*) FROM fantasy.events WHERE amount > 0) AS relative_sales,  -- Относительное количество продаж
    COUNT(DISTINCT e.id) * 1.0 / (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0) AS player_ratio  -- Доля игроков, покупавших предмет
FROM 
    fantasy.events e
JOIN 
    fantasy.items i ON e.item_code = i.item_code
WHERE 
    e.amount > 0  -- Фильтрация покупок с ненулевой стоимостью
GROUP BY 
    i.game_items
ORDER BY 
    total_sales DESC;  -- Сортировка по популярности (общее количество продаж)
-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH unique_players AS (
    SELECT 
        id,
        race_id,
        payer
    FROM 
        fantasy.users
    GROUP BY 
        id, race_id, payer
),
buyers AS (
    SELECT 
        u.id,
        u.race_id,
        u.payer,
        e.transaction_id,
        e.amount
    FROM 
        unique_players u
    LEFT JOIN 
        fantasy.events e ON u.id = e.id AND e.amount > 0  
)
SELECT 
    r.race AS race_name,  -
    COUNT(DISTINCT u.id) AS total_players,  
    COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL THEN u.id END) AS buyers_count,  
    COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL THEN u.id END) * 1.0 / COUNT(DISTINCT u.id) AS buyers_ratio, 
    COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL AND u.payer = 1 THEN u.id END) * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL THEN u.id END), 0) AS paying_ratio,  
    COUNT(b.transaction_id) * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL THEN u.id END), 0) AS avg_purchases_per_player,  
    SUM(b.amount) * 1.0 / NULLIF(COUNT(b.transaction_id), 0) AS avg_purchase_value_per_player,  -
    SUM(b.amount) * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN b.transaction_id IS NOT NULL THEN u.id END), 0) AS avg_total_spent_per_player  
FROM 
    unique_players u
LEFT JOIN 
    buyers b ON u.id = b.id
JOIN 
    fantasy.race r ON u.race_id = r.race_id  
GROUP BY 
    r.race
ORDER BY 
    r.race;  
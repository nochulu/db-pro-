--каждый пользователь имеет одинаковое количество измерений (по 5 на пачку)?
SELECT 
    u.user_id,
    u.full_name,
    COUNT(mp.parameter_type_id) AS cnt_records
FROM users u
JOIN packs p ON u.user_id = p.user_id
LEFT JOIN measurement_parameters mp ON p.pack_id = mp.pack_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(mp.parameter_type_id) % 5 != 0;


-- у нас нет пустых пачек измерения?
SELECT p.pack_id, p.pack_number 
FROM packs p
LEFT JOIN measurement_parameters mp ON p.pack_id = mp.pack_id
GROUP BY p.pack_id, p.pack_number
HAVING COUNT(mp.parameter_type_id) = 0;


-- каждая пачка измерений содержит полное количество параметров (5 шт)?
SELECT p.pack_id, p.pack_number, COUNT(DISTINCT mp.parameter_type_id) AS cnt_params
FROM packs p
LEFT JOIN measurement_parameters mp ON p.pack_id = mp.pack_id
GROUP BY p.pack_id, p.pack_number
HAVING COUNT(DISTINCT mp.parameter_type_id) != 5;


-- все значения в рамках физических диапазонов?
SELECT 
    mp.pack_id,
    pt.name AS param_name,
    mp.parameter_value
FROM measurement_parameters mp
JOIN parameter_types pt ON mp.parameter_type_id = pt.parameter_type_id
WHERE 
    (mp.parameter_type_id = 1 AND (mp.parameter_value < 600 OR mp.parameter_value > 800)) -- давление
    OR (mp.parameter_type_id = 2 AND (mp.parameter_value < -50 OR mp.parameter_value > 50)) -- температура
    OR (mp.parameter_type_id = 3 AND (mp.parameter_value < 0 OR mp.parameter_value > 100))  -- влажность
    OR (mp.parameter_type_id = 4 AND (mp.parameter_value < 0 OR mp.parameter_value > 60))   -- скорость
    OR (mp.parameter_type_id = 5 AND (mp.parameter_value < 0 OR mp.parameter_value > 360)); -- направление


-- все единицы измерения верны и корректны по отношению к параметрам?
SELECT 
    mp.pack_id,
    pt.name AS param_name,
    u.short_name AS unit_name
FROM measurement_parameters mp
JOIN parameter_types pt ON mp.parameter_type_id = pt.parameter_type_id
JOIN units u ON pt.unit_id = u.unit_id
WHERE 
    (mp.parameter_type_id = 1 AND u.short_name != 'мм рт. ст.')
    OR (mp.parameter_type_id = 2 AND u.short_name != '°C')
    OR (mp.parameter_type_id = 3 AND u.short_name != '%')
    OR (mp.parameter_type_id = 4 AND u.short_name != 'м/с')
    OR (mp.parameter_type_id = 5 AND u.short_name != 'deg');
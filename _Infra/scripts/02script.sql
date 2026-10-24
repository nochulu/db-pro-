DROP TABLE IF EXISTS measurement_parameters CASCADE;
DROP TABLE IF EXISTS parameter_types CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS base_units CASCADE;

-- создание нормализованных таблиц
CREATE TABLE base_units (
    base_unit_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
COMMENT ON TABLE base_units IS 'Справочник базовых физических величин';

CREATE TABLE units (
    unit_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(20) NOT NULL,
    base_unit_id INT REFERENCES base_units(base_unit_id)
);
COMMENT ON TABLE units IS 'Справочник единиц измерения';

CREATE TABLE parameter_types (
    parameter_type_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit_id INT REFERENCES units(unit_id)
);
COMMENT ON TABLE parameter_types IS 'Справочник измеряемых типов параметров';

CREATE TABLE measurement_parameters (
    measurement_parameter_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pack_id INT REFERENCES packs(pack_id),
    parameter_type_id INT REFERENCES parameter_types(parameter_type_id),
    parameter_value NUMERIC(10,2) NOT NULL
);
COMMENT ON TABLE measurement_parameters IS 'Таблица значений параметров конкретных измерений';

-- заполнение справочников 
INSERT INTO base_units (base_unit_id, name) VALUES 
(1, 'Высота'),
(2, 'Температура'),
(3, 'Давление'),
(4, 'Направление ветра'),
(5, 'Скорость ветра'),
(6, 'Дальность сноса пуль');

INSERT INTO units (unit_id, name, short_name, base_unit_id) VALUES 
(1, 'Метр', 'м', 1),
(2, 'Градус Цельсия', '°C', 2),
(3, 'Миллиметр ртутного столба', 'мм рт. ст.', 3),
(4, 'Большое деление угломера', 'делен.', 4),
(5, 'Метр в секунду', 'м/с', 5),
(6, 'Метр', 'м', 6);

-- набор типов параметров
INSERT INTO parameter_types (parameter_type_id, name, unit_id) VALUES 
(1, 'Высота метеопоста', 1),
(2, 'Температура', 2),
(3, 'Давление', 3),
(4, 'Направление ветра', 4),
(5, 'Скорость ветра', 5),
(6, 'Дальность сноса пуль', 6);

-- парсинг данных из текстовых строк
WITH parsed_data AS (
    SELECT 
        p.pack_id,
        parsed.ord AS parameter_type_id,
        CAST(parsed.val[1] AS NUMERIC(10,2)) AS parameter_value
    FROM packs p
    JOIN parametrs pr ON p.parametr_id = pr.parametr_id
    CROSS JOIN LATERAL (
        SELECT 
            ROW_NUMBER() OVER () AS ord,
            m AS val
        FROM regexp_matches(pr.param_value, '([0-9]+(?:\.[0-9]+)?)', 'g') AS m
    ) parsed
)
INSERT INTO measurement_parameters (pack_id, parameter_type_id, parameter_value)
SELECT pack_id, parameter_type_id, parameter_value
FROM parsed_data;

-- удаляем старую ненормализованную колонку
ALTER TABLE packs DROP CONSTRAINT IF EXISTS packs_parametr_id_fkey;
ALTER TABLE packs DROP COLUMN IF EXISTS parametr_id CASCADE;
DROP TABLE IF EXISTS parametrs CASCADE;
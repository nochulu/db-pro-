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
COMMENT ON COLUMN base_units.base_unit_id IS 'Уникальный код базовой единицы';
COMMENT ON COLUMN base_units.name IS 'Название физической величины';

CREATE TABLE units (
    unit_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(20) NOT NULL,
    base_unit_id INT REFERENCES base_units(base_unit_id)
);
COMMENT ON TABLE units IS 'Справочник единиц измерения';
COMMENT ON COLUMN units.unit_id IS 'Уникальный код единицы измерения';
COMMENT ON COLUMN units.name IS 'Полное название единицы измерения';
COMMENT ON COLUMN units.short_name IS 'Краткое обозначение единицы измерения';
COMMENT ON COLUMN units.base_unit_id IS 'Ссылка на базовую физическую величину';

CREATE TABLE parameter_types (
    parameter_type_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit_id INT REFERENCES units(unit_id)
);
COMMENT ON TABLE parameter_types IS 'Справочник измеряемых типов параметров';
COMMENT ON COLUMN parameter_types.parameter_type_id IS 'Уникальный код типа параметра';
COMMENT ON COLUMN parameter_types.name IS 'Название параметра';
COMMENT ON COLUMN parameter_types.unit_id IS 'Ссылка на единицу измерения по умолчанию';

CREATE TABLE measurement_parameters (
    measurement_parameter_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pack_id INT REFERENCES packs(pack_id),
    parameter_type_id INT REFERENCES parameter_types(parameter_type_id),
    parameter_value NUMERIC(10,2) NOT NULL
);
COMMENT ON TABLE measurement_parameters IS 'Таблица значений параметров конкретных измерений';
COMMENT ON COLUMN measurement_parameters.measurement_parameter_id IS 'Уникальный код записи измерения';
COMMENT ON COLUMN measurement_parameters.pack_id IS 'Ссылка на пачку измерений';
COMMENT ON COLUMN measurement_parameters.parameter_type_id IS 'Ссылка на тип параметра';
COMMENT ON COLUMN measurement_parameters.parameter_value IS 'Числовое значение параметра';

-- заполнение справочников
INSERT INTO base_units (base_unit_id, name) VALUES 
(1, 'Давление'),
(2, 'Температура'),
(3, 'Влажность'),
(4, 'Скорость ветра'),
(5, 'Направление ветра');

INSERT INTO units (unit_id, name, short_name, base_unit_id) VALUES 
(1, 'Миллиметр ртутного столба', 'мм рт. ст.', 1),
(2, 'Градус Цельсия', '°C', 2),
(3, 'Процент', '%', 3),
(4, 'Метр в секунду', 'м/с', 4),
(5, 'Градус', 'deg', 5);

INSERT INTO parameter_types (parameter_type_id, name, unit_id) VALUES 
(1, 'Давление', 1),
(2, 'Температура', 2),
(3, 'Влажность', 3),
(4, 'Скорость ветра', 4),
(5, 'Направление ветра', 5);


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

-- Удаляем старую ненормализованную таблицу
ALTER TABLE packs DROP CONSTRAINT IF EXISTS packs_parametr_id_fkey;
ALTER TABLE packs DROP COLUMN IF EXISTS parametr_id CASCADE;
DROP TABLE IF EXISTS parametrs CASCADE;
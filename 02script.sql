DROP TABLE IF EXISTS measurement_parameters CASCADE;
DROP TABLE IF EXISTS parameter_types CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS base_units CASCADE;

-- создание нормализованных справочников и таблиц
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
(2, 'Температура');

INSERT INTO units (unit_id, name, short_name, base_unit_id) VALUES 
(1, 'Миллиметр ртутного столба', 'мм рт. ст.', 1),
(2, 'Градус Цельсия', '°C', 2);

INSERT INTO parameter_types (parameter_type_id, name, unit_id) VALUES 
(1, 'Давление', 1),
(2, 'Температура', 2);


-- давление из формата '765 мм / 28 C' -> 765.00
INSERT INTO measurement_parameters (pack_id, parameter_type_id, parameter_value)
SELECT 
    p.pack_id,
    1 AS parameter_type_id,
    CAST(split_part(trim(split_part(pr.param_value, '/', 1)), ' ', 1) AS NUMERIC(10,2))
FROM packs p
JOIN parametrs pr ON p.parametr_id = pr.parametr_id;

-- температура из формата '765 мм / 28 C' -> 28.00
INSERT INTO measurement_parameters (pack_id, parameter_type_id, parameter_value)
SELECT 
    p.pack_id,
    2 AS parameter_type_id,
    CAST(split_part(trim(split_part(pr.param_value, '/', 2)), ' ', 1) AS NUMERIC(10,2))
FROM packs p
JOIN parametrs pr ON p.parametr_id = pr.parametr_id;

-- удаление устаревших связей и старой таблицы
ALTER TABLE packs DROP CONSTRAINT IF EXISTS packs_parametr_id_fkey;
ALTER TABLE packs DROP COLUMN IF EXISTS parametr_id CASCADE;
DROP TABLE IF EXISTS parametrs CASCADE;

SELECT 
    p.pack_number AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    pos.title AS "Должность",
    eq.type_name AS "Тип оборудования",
    pt.name || ', ' || un.short_name AS "Параметр (ед. изм.)",
    mp.parameter_value AS "Значение"
FROM 
    packs p
    JOIN users u ON u.user_id = p.user_id
    JOIN positions pos ON pos.position_id = u.position_id
    JOIN equipment_types eq ON eq.equipment_type_id = p.equipment_type_id
    JOIN measurement_parameters mp ON mp.pack_id = p.pack_id
    JOIN parameter_types pt ON pt.parameter_type_id = mp.parameter_type_id
    JOIN units un ON un.unit_id = pt.unit_id
ORDER BY 
    p.pack_id ASC,
    pt.parameter_type_id ASC;
DROP TABLE IF EXISTS packs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS parametrs;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS base_units;
DROP TABLE IF EXISTS units;
DROP TABLE IF EXISTS parameter_types;
DROP TABLE IF EXISTS measurement_parameters;

-- должности
CREATE TABLE positions (
    position_id INT PRIMARY KEY,
    title VARCHAR
);
COMMENT ON TABLE positions IS 'Список должностей сотрудников';
COMMENT ON COLUMN positions.position_id IS 'Уникальный код должности';
COMMENT ON COLUMN positions.title IS 'Название должности';

-- пользователи
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR,
    position_id INT REFERENCES positions(position_id)
);
COMMENT ON TABLE users IS 'список пользователей и сотрудников';
COMMENT ON COLUMN users.user_id IS 'Уникальный код пользователя';
COMMENT ON COLUMN users.full_name IS 'ФИО сотрудника';
COMMENT ON COLUMN users.position_id IS 'ссылка на должность сотрудника';

-- типы оборудования 
CREATE TABLE equipment_types(
    equipment_type_id INT PRIMARY KEY,
    type_name VARCHAR
);
COMMENT ON TABLE equipment_types IS 'Список типов оборудования';
COMMENT ON COLUMN equipment_types.equipment_type_id IS 'уникальный код типа оборудования';
COMMENT ON COLUMN equipment_types.type_name IS 'название типа оборудования';

-- пачки
CREATE TABLE packs (
    pack_id INT PRIMARY KEY,
    pack_number VARCHAR(50) NOT NULL,
    user_id INT REFERENCES users(user_id),
    position_id INT REFERENCES positions(position_id),
    equipment_type_id INT REFERENCES equipment_types(equipment_type_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE packs IS 'список сформированных пачек данных';
COMMENT ON COLUMN packs.pack_id IS 'уникальный код пачки';
COMMENT ON COLUMN packs.pack_number IS 'учетный номер пачки';
COMMENT ON COLUMN packs.user_id IS 'ссылка на пользователя, создавшего пачку';
COMMENT ON COLUMN packs.position_id IS 'ссылка на должность ответственного сотрудника';
COMMENT ON COLUMN packs.equipment_type_id IS 'ссылка на тип используемого оборудования';
COMMENT ON COLUMN packs.created_at IS 'Дата и время формирования пачки';

-- список базовых единиц измерения
CREATE TABLE base_units (
    base_unit_id INT PRIMARY KEY, 
    name VARCHAR 
);
COMMENT ON TABLE base_units IS 'Справочник базовых физических величин';
COMMENT ON COLUMN base_units.base_unit_id IS 'Уникальный код базовой единицы';
COMMENT ON COLUMN base_units.name IS 'Название физической величины';

-- список единиц измерения 
CREATE TABLE units (
    unit_id INT PRIMARY KEY,
    name VARCHAR,
    short_name VARCHAR,
    base_unit_id INT REFERENCES base_units(base_unit_id)
);
COMMENT ON TABLE units IS 'Справочник единиц измерения';
COMMENT ON COLUMN units.unit_id IS 'Уникальный код единицы измерения';
COMMENT ON COLUMN units.name IS 'Полное название единицы измерения';
COMMENT ON COLUMN units.short_name IS 'Краткое обозначение единицы измерения';
COMMENT ON COLUMN units.base_unit_id IS 'ссылка на базовую физическую величину';

-- список типов параметров 
CREATE TABLE parameter_types (
    parameter_type_id INT PRIMARY KEY,
    name VARCHAR,
    unit_id INT REFERENCES units(unit_id)
);
COMMENT ON TABLE parameter_types IS 'Справочник измеряемых типов параметров';
COMMENT ON COLUMN parameter_types.parameter_type_id IS 'Уникальный код типа параметра';
COMMENT ON COLUMN parameter_types.name IS 'Название параметра';
COMMENT ON COLUMN parameter_types.unit_id IS 'Ссылка на единицу измерения по умолчанию';

-- значение параметров измерений 
CREATE TABLE measurement_parameters (
    measurement_parameter_id INT PRIMARY KEY,
    pack_id INT REFERENCES packs(pack_id),
    parameter_type_id INT REFERENCES parameter_types(parameter_type_id),
    parameter_value NUMERIC(10,2) 
);
COMMENT ON TABLE measurement_parameters IS 'Таблица значений параметров конкретных измерений';
COMMENT ON COLUMN measurement_parameters.measurement_parameter_id IS 'Уникальный код записи параметра';
COMMENT ON COLUMN measurement_parameters.pack_id IS 'Ссылка на пачку измерений';
COMMENT ON COLUMN measurement_parameters.parameter_type_id IS 'Ссылка на тип параметра';
COMMENT ON COLUMN measurement_parameters.parameter_value IS 'Числовое значение параметра';

INSERT INTO positions (position_id, title) VALUES (1, 'Инженер');
INSERT INTO positions (position_id, title) VALUES (2, 'Оператор метеопоста');

INSERT INTO users (user_id, full_name, position_id) VALUES (11, 'Сергеев Сергей Игоревич', 1);
INSERT INTO users (user_id, full_name, position_id) VALUES (12, 'Борисов АНдрей АЛександрович', 2);

INSERT INTO equipment_types (equipment_type_id, type_name) VALUES (21, 'ДМК');
INSERT INTO equipment_types (equipment_type_id, type_name) VALUES (22, 'ВР');

INSERT INTO packs (pack_id,pack_number,user_id,equipment_type_id,created_at) VALUES (41, 'pack-123', 11, 21, '2024-07-18 10:00:00');
INSERT INTO packs (pack_id,pack_number,user_id,equipment_type_id,created_at) VALUES (42, 'pack-124', 12, 22,'2024-07-18 16:00:00');

INSERT INTO base_units (base_unit_id, name) VALUES (1, 'Давление'),(2, 'Температура');

INSERT INTO units (unit_id, name, short_name, base_unit_id) VALUES (1, 'Миллиметр ртутного столба', 'мм рт. ст.', 1),(2, 'Градус Цельсия', '°C', 2);

INSERT INTO parameter_types (parameter_type_id, name, unit_id) VALUES (1, 'Давление', 1), (2, 'Температура', 2);

INSERT INTO measurement_parameters (measurement_parameter_id, pack_id, parameter_type_id, parameter_value) VALUES (1, 41, 1, 765.00), -- давление для pack-123
(2, 41, 2, 28.00),  -- температура для pack-123
(3, 42, 1, 743.00), -- давление для pack-124
(4, 42, 2, 18.00);  -- температура для pack-124

SELECT 
    p.created_at AS "Дату измерения",
    p.pack_number AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    pt.name || ', ' || un.short_name AS "Наименование параметра и ед. измерения",
    mp.parameter_value AS "Значение"
FROM 
    packs p
    JOIN users u ON u.user_id = p.user_id
    JOIN measurement_parameters mp ON mp.pack_id = p.pack_id
    JOIN parameter_types pt ON pt.parameter_type_id = mp.parameter_type_id
    JOIN units un ON un.unit_id = pt.unit_id
ORDER BY 
    p.created_at ASC,
    p.pack_id ASC,
    pt.parameter_type_id ASC;
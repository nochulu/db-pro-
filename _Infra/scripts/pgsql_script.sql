BEGIN;

-- удаление таблиц 
DROP TABLE IF EXISTS measurement_parameters CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS temperature_calculations CASCADE;
DROP TABLE IF EXISTS type_params CASCADE;
DROP TABLE IF EXISTS unit_measure CASCADE;
DROP TABLE IF EXISTS basic_unit_measure CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS packs CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS equipment_types CASCADE;

-- удаление последовательностей 
DROP SEQUENCE IF EXISTS seq_equipment_types;
DROP SEQUENCE IF EXISTS seq_positions;
DROP SEQUENCE IF EXISTS seq_packs;
DROP SEQUENCE IF EXISTS seq_users;
DROP SEQUENCE IF EXISTS seq_parameters;
DROP SEQUENCE IF EXISTS seq_calc;

-- создание последовательностей 
CREATE SEQUENCE seq_equipment_types START WITH 1;
CREATE SEQUENCE seq_positions START WITH 1;
CREATE SEQUENCE seq_packs START WITH 1;
CREATE SEQUENCE seq_users START WITH 1;
CREATE SEQUENCE seq_parameters START WITH 1;
CREATE SEQUENCE seq_calc START WITH 1;

-- создание таблиц
CREATE TABLE equipment_types (
    equipment_type_id INT DEFAULT nextval('seq_equipment_types'),
    equipment_type_name VARCHAR(30),
    PRIMARY KEY (equipment_type_id)
);

CREATE TABLE positions (
    position_id INT DEFAULT nextval('seq_positions'),
    position_name VARCHAR(30),
    PRIMARY KEY (position_id)
);

CREATE TABLE packs (
    pack_id INT DEFAULT nextval('seq_packs'),
    pack_number VARCHAR(30),
    created_date TIMESTAMP,
    PRIMARY KEY (pack_id)
);

CREATE TABLE users (
    user_id INT DEFAULT nextval('seq_users'),
    user_name VARCHAR(50),
    position_id INT,
    pack_id INT,
    PRIMARY KEY (user_id)
);

CREATE TABLE basic_unit_measure (
    id INT PRIMARY KEY,
    name TEXT
);

CREATE TABLE unit_measure (
    id INT PRIMARY KEY,
    name TEXT,
    basic_unit_measure_id INT
);

CREATE TABLE type_params (
    id INT PRIMARY KEY,
    name TEXT,
    unit_measure_id INT
);

CREATE TABLE parameters (
    parameter_id INT DEFAULT nextval('seq_parameters'),
    parameter_value VARCHAR(50),
    user_id INT,
    equipment_type_id INT,
    type_param_id INT,
    PRIMARY KEY (parameter_id)
);

-- таблица расчета температуры
CREATE TABLE temperature_calculations (
    calc_id INT DEFAULT nextval('seq_calc') PRIMARY KEY,
    pack_id INT,
    avg_temperature NUMERIC(5, 2),
    calculated_date TIMESTAMP DEFAULT current_timestamp
);

COMMIT;


-- наполнение тестовыми данными
BEGIN;

INSERT INTO equipment_types (equipment_type_name) VALUES ('ДМК'), ('ВР');

INSERT INTO positions (position_name) VALUES ('Оператор'), ('Старший оператор');

INSERT INTO packs (pack_number, created_date) VALUES 
('pack-01aa', '2026-05-11 10:00:00'), 
('pack-02ab', '2026-05-11 11:30:00');

INSERT INTO users (user_name, position_id, pack_id) VALUES 
('Иван Иванов', 1, 1),
('Иван Петров', 2, 2);

INSERT INTO basic_unit_measure (id, name) VALUES 
(1, 'Метр'), 
(2, 'Градус'), 
(3, 'Миллиметр ртутного столба');

INSERT INTO unit_measure (id, name, basic_unit_measure_id) VALUES
(1, 'м', 1), 
(2, '°', 2), 
(3, '°C', 2), 
(4, 'мм рт. ст.', 3), 
(5, 'м/с', 1);

INSERT INTO type_params (id, name, unit_measure_id) VALUES
(1, 'Высота метеопоста', 1),
(2, 'Температура', 3),
(3, 'Давление', 4),
(4, 'Направление ветра', 2),
(5, 'Скорость ветра', 5),
(6, 'Дальность сноса пуль', 1);

INSERT INTO parameters (parameter_value, user_id, equipment_type_id, type_param_id) VALUES 
('100', 1, 1, 1),
('15', 1, 1, 2),
('750', 1, 1, 3),
('00', 1, 1, 4),
('0', 1, 1, 5),
('0', 2, 2, 6);

-- заполнение расчетной таблицы средней температуры 
INSERT INTO temperature_calculations (pack_id, avg_temperature)
SELECT 
    u.pack_id,
    avg(p.parameter_value::numeric)
FROM parameters p
JOIN users u ON u.user_id = p.user_id
WHERE p.type_param_id = 2
GROUP BY u.pack_id;

COMMIT;


-- создание связей и ограничений 
BEGIN;

ALTER TABLE users
    ADD CONSTRAINT fk_users_position FOREIGN KEY (position_id) REFERENCES positions(position_id),
    ADD CONSTRAINT fk_users_pack FOREIGN KEY (pack_id) REFERENCES packs(pack_id);

ALTER TABLE unit_measure
    ADD CONSTRAINT fk_unit_measure_basic FOREIGN KEY (basic_unit_measure_id) REFERENCES basic_unit_measure(id);

ALTER TABLE type_params
    ADD CONSTRAINT fk_type_params_unit FOREIGN KEY (unit_measure_id) REFERENCES unit_measure(id);

ALTER TABLE parameters
    ADD CONSTRAINT fk_parameters_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    ADD CONSTRAINT fk_parameters_equipment FOREIGN KEY (equipment_type_id) REFERENCES equipment_types(equipment_type_id),
    ADD CONSTRAINT fk_parameters_type FOREIGN KEY (type_param_id) REFERENCES type_params(id);

ALTER TABLE temperature_calculations
    ADD CONSTRAINT fk_calc_pack FOREIGN KEY (pack_id) REFERENCES packs(pack_id);

COMMIT;
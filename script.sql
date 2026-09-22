DROP TABLE IF EXISTS packs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS parametrs;
DROP TABLE IF EXISTS equipment_types;

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
    position_id INT,
    FOREIGN KEY (position_id) REFERENCES positions(position_id)
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

--параметры
CREATE TABLE parametrs(
    parametr_id INT PRIMARY KEY,
    param_name VARCHAR,
    param_value VARCHAR
);
COMMENT ON TABLE parametrs IS 'список параметров и измерений';
COMMENT ON COLUMN parametrs.parametr_id IS 'уникальный код записи параметра';
COMMENT ON COLUMN parametrs.param_name IS 'название параметра';
COMMENT ON COLUMN parametrs.param_value IS 'значение параметра';

-- пачки
CREATE TABLE packs(
    pack_id INT PRIMARY KEY,
    pack_number VARCHAR,
    user_id INT,
    position_id INT,
    equipment_type_id INT,
    parametr_id INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (equipment_type_id) REFERENCES equipment_types(equipment_type_id),
    FOREIGN KEY (parametr_id) REFERENCES parametrs(parametr_id)
);
COMMENT ON TABLE packs IS 'список сформированных пачек данных';
COMMENT ON COLUMN packs.pack_id IS 'уникальный код пачки';
COMMENT ON COLUMN packs.pack_number IS 'учетный номер пачки';
COMMENT ON COLUMN packs.user_id IS 'ссылка на пользователя, создавшего пачку';
COMMENT ON COLUMN packs.position_id IS 'ссылка на должность ответственного сотрудника';
COMMENT ON COLUMN packs.equipment_type_id IS 'ссылка на тип используемого оборудования';
COMMENT ON COLUMN packs.parametr_id IS 'ссылка на запись параметрами';


INSERT INTO positions (position_id, title) VALUES (1, 'Инженер');
INSERT INTO positions (position_id, title) VALUES (2, 'Оператор метеопоста');

INSERT INTO users (user_id, full_name, position_id) VALUES (11, 'Сергеев Сергей Игоревич', 1);
INSERT INTO users (user_id, full_name, position_id) VALUES (12, 'Борисов АНдрей АЛександрович', 2);

INSERT INTO equipment_types (equipment_type_id, type_name) VALUES (21, 'ДМК');
INSERT INTO equipment_types (equipment_type_id, type_name) VALUES (22, 'ВР');

INSERT INTO parametrs (parametr_id, param_name,param_value) VALUES (31, 'Давление/Температура', '765 мм / 28 C');
INSERT INTO parametrs (parametr_id, param_name,param_value) VALUES (32, 'Давление/Температура', '743 мм / 18 C');

INSERT INTO packs (pack_id,pack_number,user_id,equipment_type_id,parametr_id) VALUES (41, 'pack-123', 11, 21, 31);
INSERT INTO packs (pack_id,pack_number,user_id,equipment_type_id,parametr_id) VALUES (42, 'pack-124', 12, 22, 32);


SELECT 
    p.pack_id AS "Код пачки",
    p.pack_number AS "Номер пачки",
    u.full_name AS "ФИО пользователя",
    pos.title AS "ДОлжность",
    eq.type_name AS "Тип оборудования",
    param.param_name AS "Параметр",
    param.param_value AS "Значение параметра"
FROM packs p, users u, positions pos, equipment_types eq, parametrs param
WHERE p.user_id = u.user_id
  AND u.position_id = pos.position_id
  AND p.equipment_type_id = eq.equipment_type_id
  AND p.parametr_id = param.parametr_id; 
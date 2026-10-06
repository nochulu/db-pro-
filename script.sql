DROP TABLE IF EXISTS packs CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS parametrs CASCADE;
DROP TABLE IF EXISTS equipment_types CASCADE;

-- должности
CREATE TABLE positions (
    position_id INT PRIMARY KEY,
    title VARCHAR NOT NULL
);
COMMENT ON TABLE positions IS 'Список должностей сотрудников';
COMMENT ON COLUMN positions.position_id IS 'Уникальный код должности';
COMMENT ON COLUMN positions.title IS 'Название должности';

-- пользователи
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR NOT NULL,
    position_id INT REFERENCES positions(position_id)
);
COMMENT ON TABLE users IS 'список пользователей и сотрудников';
COMMENT ON COLUMN users.user_id IS 'Уникальный код пользователя';
COMMENT ON COLUMN users.full_name IS 'ФИО сотрудника';
COMMENT ON COLUMN users.position_id IS 'ссылка на должность сотрудника';

-- типы оборудования 
CREATE TABLE equipment_types (
    equipment_type_id INT PRIMARY KEY,
    type_name VARCHAR NOT NULL
);
COMMENT ON TABLE equipment_types IS 'Список типов оборудования';
COMMENT ON COLUMN equipment_types.equipment_type_id IS 'уникальный код типа оборудования';
COMMENT ON COLUMN equipment_types.type_name IS 'название типа оборудования';

--параметры
CREATE TABLE parametrs (
    parametr_id INT PRIMARY KEY,
    param_name VARCHAR NOT NULL,
    param_value VARCHAR NOT NULL
);
COMMENT ON TABLE parametrs IS 'список параметров и измерений';
COMMENT ON COLUMN parametrs.parametr_id IS 'уникальный код записи параметра';
COMMENT ON COLUMN parametrs.param_name IS 'название параметра';
COMMENT ON COLUMN parametrs.param_value IS 'значение параметра';

-- пачки
CREATE TABLE packs (
    pack_id INT PRIMARY KEY,
    pack_number VARCHAR NOT NULL,
    user_id INT REFERENCES users(user_id),
    position_id INT REFERENCES positions(position_id),
    equipment_type_id INT REFERENCES equipment_types(equipment_type_id),
    parametr_id INT REFERENCES parametrs(parametr_id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE packs IS 'список сформированных пачек данных';
COMMENT ON COLUMN packs.pack_id IS 'уникальный код пачки';
COMMENT ON COLUMN packs.pack_number IS 'учетный номер пачки';
COMMENT ON COLUMN packs.user_id IS 'ссылка на пользователя, создавшего пачку';
COMMENT ON COLUMN packs.position_id IS 'ссылка на должность ответственного сотрудника';
COMMENT ON COLUMN packs.equipment_type_id IS 'ссылка на тип используемого оборудования';
COMMENT ON COLUMN packs.parametr_id IS 'ссылка на запись параметрами';
COMMENT ON COLUMN packs.created_at IS 'Дата и время создания пачки';


INSERT INTO positions (position_id, title) VALUES 
(1, 'Инженер'), (2, 'Оператор метеопоста');

INSERT INTO users (user_id, full_name, position_id) VALUES 
(11, 'Сергеев Сергей Игоревич', 1), (12, 'Борисов Андрей Александрович', 2);

INSERT INTO equipment_types (equipment_type_id, type_name) VALUES 
(21, 'ДМК'), (22, 'ВР');

INSERT INTO parametrs (parametr_id, param_name, param_value) VALUES 
(31, 'Метеокомплекс 1', '765 мм / 28 C / 55 % / 3.5 м/с / 180 deg'),
(32, 'Метеокомплекс 2', '743 мм / 18 C / 62 % / 5.1 м/с / 270 deg');

INSERT INTO packs (pack_id, pack_number, user_id, position_id, equipment_type_id, parametr_id) VALUES 
(41, 'pack-123', 11, 1, 21, 31),
(42, 'pack-124', 12, 2, 22, 32);


create table calculation_types (
    id serial primary key,
    code varchar(10) not null unique, 
    name varchar(100) not null        
);
comment on table calculation_types is 'справочник типов расчетов (ДМК, ВР)';
comment on column calculation_types.code is 'код метода';
comment on column calculation_types.name is 'наименование метода расчета';

insert into calculation_types (code, name) values
('DMK', 'Дальномерный метеорологический комплекс'),
('VR',  'Ветровое ружье');

create table standard_heights (
    id serial primary key,
    height int not null unique
);
comment on table standard_heights is 'Справочник стандартных высот Y';
comment on column standard_heights.height is 'Высота в метрах';

insert into standard_heights (height) values
(200), (400), (800), (1200), (1600), (2000), (2400), (3000), (4000);

create table temperature_deviations (
    id serial primary key,
    height_id int not null references standard_heights(id) on delete cascade,
    temp int not null,
    val_negative int not null,     
    val_positive int,
    constraint uk_temp_height unique (height_id, temp)
);
comment on table temperature_deviations is 'среднее отклонение температуры воздуха';
comment on column temperature_deviations.height_id is 'ссылка на стандартную высоту';
comment on column temperature_deviations.temp is 'модуль составляющей отклонения приземной виртуальной температуры';
comment on column temperature_deviations.val_negative is 'Среднее отклонение температуры при отрицательном приземном отклонении';
comment on column temperature_deviations.val_positive is 'среднее отклонение температуры при положительном приземном отклонении';

insert into temperature_deviations(height_id, temp, val_negative, val_positive) 
values
  ((select id from standard_heights where height = 200), 1, -1, 1),
  ((select id from standard_heights where height = 200), 2, -2, 2),
  ((select id from standard_heights where height = 200), 3, -3, 3);

create table wind_averages (
    id serial primary key,
    calculation_type_id int not null references calculation_types(id) on delete cascade,
    height_id int not null references standard_heights(id) on delete cascade,
    input_param int not null, 
    wind_speed int not null, 
    wind_increment varchar(8) not null 
);
comment on table wind_averages is 'скорость и приращение направления среднего ветра для ДМК и ВР';
comment on column wind_averages.calculation_type_id is 'ссылка на тип расчета';
comment on column wind_averages.height_id is 'ссылка на стандартную высоту';
comment on column wind_averages.input_param is 'сходной параметр: скорость приземного ветра V0 (для ДМК) или дальность сноса Dr (для ВР)';
comment on column wind_averages.wind_speed is 'скорость среднего ветра Wy';
comment on column wind_averages.wind_increment is 'приращение направления среднего ветра';
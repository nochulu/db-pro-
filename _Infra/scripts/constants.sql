begin;
drop table if exists meteo_constants cascade;

create table meteo_constants(
    constant_id int primary key,
    constant_value numeric,
    description text
);

comment on table meteo_constants is 'справочник констант и ограничений для параметров';
comment on column constant_id is 'уникальный код константы';
comment on column constant_value is 'значение';
comment on column description is 'описание параметра';

insert into meteo_constants (constant_id, constant_value, description) values
(1, -58.00, 'минимальная температура (°C)'),
(2, 58.00, 'максимальная температура (°C)'),
(3, 500.00, 'минимальное давление (мм рт. ст.)'),
(4, 900.00, 'максимальное давление (мм рт. ст.)'),
(5, 0.00, 'минимальное направление ветра'),
(6, 59.00, 'максимальное направление ветра'),
(7, 0.00, 'минимальная скорость ветра (м/с)'),
(8, 15.00, 'максимальная скорость ветра (м/с)'),
(9, 0.00, 'минимальная дальность сноса пуль (м)'),
(10, 150.00, 'максимальная дальность сноса пуль (м)');
commit;

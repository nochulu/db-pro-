with pivoted_params as (
    select 
        p.pack_id as N,
        et.type_name as "тип оборудования", 
        max(case when mp.parameter_type_id = 1 then mp.parameter_value end) as "высота метеопоста",
        max(case when mp.parameter_type_id = 2 then mp.parameter_value end) as "температура",
        max(case when mp.parameter_type_id = 3 then mp.parameter_value::integer end) as "давление",
        max(case when mp.parameter_type_id = 4 then mp.parameter_value::integer end) as "направление ветра",
        max(case when mp.parameter_type_id = 5 then mp.parameter_value::integer end) as "скорость ветра",
        max(case when mp.parameter_type_id = 6 then mp.parameter_value::integer end) as "дальность сноса пуль"
    from packs p
    join users u on u.user_id = p.user_id
    join equipment_types et on et.equipment_type_id = p.equipment_type_id
    join measurement_parameters mp on mp.pack_id = p.pack_id
    group by p.pack_id, et.type_name
),
checked_data as (
    select 
        N,
        "Тип оборудования",
        "Высота метеопоста",
        "Температура",
        "Давление",
        "Направление ветра",
        "Скорость ветра",
        "Дальность сноса пуль",
        check_meteo_error((
            "Высота метеопоста", 
            "Температура", 
            "Давление", 
            "Направление ветра", 
            "Скорость ветра", 
            "Дальность сноса пуль"
        )::meteo_params_type) as error_desc
    from pivoted_params
)
select 
    N as "№",
    "Тип оборудования",
    "Высота метеопоста",
    "Температура",
    "Давление",
    "Направление ветра",
    "Скорость ветра",
    "Дальность сноса пуль",
    case when error_desc <> '' then 1 else 0 end as "Флаг: Есть ошибка",
    nullif(error_desc, '') as "Описание ошибки"
from checked_data;
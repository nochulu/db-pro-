with user_packs_pivoted as (
    select 
        u.user_id,
        u.full_name as "Пользователь",
        p.pack_id,
        max(case when mp.parameter_type_id = 1 then mp.parameter_value end) as h,
        max(case when mp.parameter_type_id = 2 then mp.parameter_value end) as t,
        max(case when mp.parameter_type_id = 3 then mp.parameter_value::integer end) as prs,
        max(case when mp.parameter_type_id = 4 then mp.parameter_value::integer end) as wd,
        max(case when mp.parameter_type_id = 5 then mp.parameter_value::integer end) as ws,
        max(case when mp.parameter_type_id = 6 then mp.parameter_value::integer end) as dr
    from users u
    join packs p on p.user_id = u.user_id
    join measurement_parameters mp on mp.pack_id = p.pack_id
    group by u.user_id, u.full_name, p.pack_id
),
evaluated_errors as (
    select 
        "Пользователь",
        case when check_meteo_error((h, t, prs, wd, ws, dr)::meteo_params_type) <> '' then 1 else 0 end as error_count
    from user_packs_pivoted
)
select 
    "Пользователь",
    sum(error_count) as "Количество допущенных ошибок"
from evaluated_errors
group by "Пользователь"
order by "Количество допущенных ошибок" asc;
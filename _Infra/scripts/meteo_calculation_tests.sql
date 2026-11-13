do $$
declare
    v_input calc_input_params;
    r record;
begin
    -- дмк, высота 100, давление 765, температура 25, направление 15, скорость 6
    v_input := row(100, 25, 765, 15, 6, 0)::calc_input_params;

    raise notice 'ДМК';
    raise notice 'ДДЧЧМ = %, ВВВВ = %, БББТТ = %',
        fn_calc_header_period(now()),
        lpad(v_input.height_post::text, 4, '0'),
        fn_calc_format_pressure(fn_calc_header_pressure(v_input.pressure))
            || fn_calc_format_temperature(fn_calc_header_temperature(v_input.temperature));

    for r in select * from fn_calc_meteo(v_input, 1) loop
        raise notice 'H = %, TT = %, HH = %, CC = %', lpad((r.height_m / 100)::text, 2, '0'), r.delta_t, r.wind_dir, r.wind_speed;
    end loop;

    -- вр: дальность сноса 100, температура -5, направление 58
    v_input := row(100, -5, 750, 58, 0, 100)::calc_input_params;

    raise notice 'ВР ';
    raise notice 'БББТТ = %',
        fn_calc_format_pressure(fn_calc_header_pressure(v_input.pressure))
            || fn_calc_format_temperature(fn_calc_header_temperature(v_input.temperature));

    for r in select * from fn_calc_meteo(v_input, 2) loop
        raise notice 'H = %, TT = %, HH = %, CC = %', lpad((r.height_m / 100)::text, 2, '0'), r.delta_t, r.wind_dir, r.wind_speed;
    end loop;
end $$;

select
    lpad((height_m / 100)::text, 2, '0') as "высота",
    delta_t as "ТТ",
    wind_dir as "НН",
    wind_speed as "СС"
from fn_calc_meteo(row(100, 25, 765, 15, 6, 0)::calc_input_params, 1)
order by height_m;

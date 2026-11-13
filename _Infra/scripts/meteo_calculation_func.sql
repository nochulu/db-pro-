-- расчет приближенного метеобюллетеня
drop type if exists calc_input_params cascade;
drop function if exists fn_calc_header_pressure(numeric), fn_calc_header_temperature(numeric),
    fn_calc_header_period(timestamptz), fn_calc_format_pressure(numeric),
    fn_calc_format_temperature(numeric), fn_calc_format_direction(integer),
    fn_calc_get_amendment(integer, integer, integer);

create type calc_input_params as (
    height_post    integer,
    temperature    numeric(8,1),
    pressure       integer,
    wind_direction integer,
    wind_speed     integer,
    drift_range    integer
);
comment on type calc_input_params is 'входящие параметры для расчета приближенного метеобюллетеня';


-- отклонение давления от табличного
create or replace function fn_calc_header_pressure(p_pressure numeric)
returns numeric
language plpgsql
as $func$
declare
    c_pressure constant numeric := 750;
begin
    return p_pressure - c_pressure;
end;
$func$;
comment on function fn_calc_header_pressure(numeric) is 'отклонение наземного давления от табличного значения';


-- отклонение приземной виртуальной температуры от табличного
create or replace function fn_calc_header_temperature(p_temperature numeric)
returns numeric
language plpgsql
as $func$
declare
    c_temperature constant numeric := 15.9;
    v_tv numeric;
begin
    -- виртуальная поправка с интерполяцией
    if p_temperature < (select min(temperature) from calc_correction_temperature) then
        v_tv := 0;
    elsif p_temperature > (select max(temperature) from calc_correction_temperature) then
        select correction into v_tv from calc_correction_temperature order by temperature desc limit 1;
    else
        v_tv := fn_calc_temperature_interpolation(p_temperature);
    end if;

    return round(p_temperature + v_tv - c_temperature);
end;
$func$;
comment on function fn_calc_header_temperature(numeric) is 'отклонение приземной виртуальной температуры от табличного значения';


-- ДДЧЧМ
create or replace function fn_calc_header_period(p_date timestamptz)
returns text
language plpgsql
as $func$
begin
    return to_char(p_date, 'DDHH24') || (extract(minute from p_date)::integer / 10)::text;
end;
$func$;
comment on function fn_calc_header_period(timestamptz) is 'день, часы и десятки минут времени измерения';


-- БББ
create or replace function fn_calc_format_pressure(p_value numeric)
returns text
language plpgsql
as $func$
begin
    if p_value < 0 then
        return '5' || lpad(abs(p_value)::integer::text, 2, '0');
    end if;
    return lpad(p_value::integer::text, 3, '0');
end;
$func$;
comment on function fn_calc_format_pressure(numeric) is 'отклонение давления в формате бюллетеня';


-- ТТ (для отрицательных к модулю прибавляется 50)
create or replace function fn_calc_format_temperature(p_value numeric)
returns text
language plpgsql
as $func$
declare
    c_negative constant integer := 50;
begin
    if p_value < 0 then
        return lpad((abs(p_value)::integer + c_negative)::text, 2, '0');
    end if;
    return lpad(p_value::integer::text, 2, '0');
end;
$func$;
comment on function fn_calc_format_temperature(numeric) is 'отклонение температуры в формате бюллетеня';


-- НН (в круге 60 делений)
create or replace function fn_calc_format_direction(p_value integer)
returns text
language plpgsql
as $func$
declare
    c_circle constant integer := 60;
begin
    return lpad((p_value % c_circle)::text, 2, '0');
end;
$func$;
comment on function fn_calc_format_direction(integer) is 'направление ветра в формате бюллетеня';


-- значение из таблицы корректировок (если столбца нет в заголовке, вернет null)
create or replace function fn_calc_get_amendment(p_height_id integer, p_type_id integer, p_column integer)
returns integer
language sql
as $func$
    select c.row_values[array_position(h.header_values, p_column)]
    from calc_correction c
    join calc_correction_types t on t.id = c.type_id
    join calc_correction_headers h on h.id = t.header_id
    where c.height_id = p_height_id and c.type_id = p_type_id;
$func$;
comment on function fn_calc_get_amendment(integer, integer, integer) is 'значение из таблицы корректировок по высоте, типу таблицы и значению в заголовке';


-- расчет по каждой типовой высоте 
create or replace function fn_calc_meteo(p_input calc_input_params, p_equipment_id integer)
returns table (height_m integer, delta_t text, wind_dir text, wind_speed integer)
language plpgsql
as $func$
declare
    c_type_positive constant integer := 8;
    c_type_negative constant integer := 9;

    v_delta integer;
    v_sum integer;
    v_type integer;
    v_wind numeric;    -- скорость ветра (ДМК) или дальность сноса (ВР)
    v_speed_type integer;
    v_dir_type integer;
    v_header integer[];
    v_row integer[];
    v_i integer;
    v_speed numeric;
    r record;
begin
    v_wind := case p_equipment_id when 1 then p_input.wind_speed when 2 then p_input.drift_range end;
    if v_wind is null then
        raise exception 'неизвестный тип оборудования или не задан ветер';
    end if;

    select s.id, d.id, h.header_values
    into v_speed_type, v_dir_type, v_header
    from calc_correction_types s
    join calc_correction_types d on d.parent_id = 3 and d.measurement_equipment_id = p_equipment_id
    join calc_correction_headers h on h.id = s.header_id
    where s.parent_id = 2 and s.measurement_equipment_id = p_equipment_id;

    if v_wind > v_header[array_upper(v_header, 1)] then
        raise exception 'значение ветра % вне таблицы', v_wind;
    end if;

    v_delta := fn_calc_header_temperature(p_input.temperature);
    if v_delta > 39 or v_delta < -59 then
        raise exception 'отклонение температуры % вне таблицы 2', v_delta;
    end if;
    v_type := case when v_delta < 0 then c_type_negative else c_type_positive end;

    for r in select id, height from calc_correction_heights order by height loop
        v_sum := coalesce(fn_calc_get_amendment(r.id, v_type, abs(v_delta) / 10 * 10), 0)
               + coalesce(fn_calc_get_amendment(r.id, v_type, abs(v_delta) % 10), 0);

        height_m := r.height;
        delta_t := fn_calc_format_temperature(v_sum);

        if v_wind < v_header[1] then
            wind_speed := 0;
            wind_dir := '00';
        else
            select row_values into v_row from calc_correction where height_id = r.id and type_id = v_speed_type;

            select count(*) into v_i from unnest(v_header) as h where h <= v_wind;
            v_speed := v_row[v_i];
            if v_header[v_i] < v_wind then
                v_speed := v_speed + (v_wind - v_header[v_i]) * (v_row[v_i + 1] - v_row[v_i]) / (v_header[v_i + 1] - v_header[v_i]);
            end if;
            wind_speed := round(v_speed);

            wind_dir := fn_calc_format_direction(p_input.wind_direction +
                (select row_values[1] from calc_correction where height_id = r.id and type_id = v_dir_type));
        end if;

        return next;
    end loop;
end;
$func$;
comment on function fn_calc_meteo(calc_input_params, integer) is 'расчет приближенного метеобюллетеня по каждой типовой высоте (1 - ДМК, 2 - ВР)';

drop function if exists generate_meteo_header (numeric, numeric, numeric);
drop function if exists check_meteo_error(meteo_params_type);
drop type if exists meteo_params_type;

-- тип параметров для передачи списка парметров
create type meteo_params_type as (
    p_height numeric,
    p_temp numeric,
    p_pressure int,
    p_wind_dir int,
    p_wind_speed int,
    p_drift int
);
comment on type is 'составной тип для входных метеопарметров';

-- функция проверки параметров на ошибки 
create or replace function check_meteo_error (p meteo_params_type)
returns text as $$ 
declare
    v_errors := '';
begin
    --проверка температуры
    if p.p_temp is null or p.p_temp < -58 or p.p_temp > 58 then 
        v_errors := || 'температура вне диапазона [-58; 58];';
    end if;
    
    --проверка давления
    if p.p_pressure is null or p.p_pressure < 500 or p.p_pressure > 900 then 
        v_errors := || 'давление вне диапазона [500; 900];';
    end if;

    -- првоерка направления ветра
    if p.p_wind_dir is null or p.p_wind_dir < 0 or p.p_wind_dir > 59 then 
        v_errors := || 'направление ветра вне диапазона [0; 59];';
    end if;

    -- проверка скорости ветра (дмк)
    if p.p_wind_speed is null and (p.p_wind_speed < 0 or p.p_wind_speed > 15) then 
        v_errors := || 'скорость ветра вне диапазона [0; 15];';
    end if;

    -- проверка дальности сноса пуль (вр)
    if p.p_drift is null and (p.p_drift < 0 or p.p_drift > 150) then 
        v_errors := || 'дальность сноса пуль вне диапазона [0; 150];';
    end if;

    return trim(both ';' from v_errors);
end;
$$ language plpgsql;

-- функция для расчета метео приближенный 
create or replace function generate_meteo_header(
    p_height numeric,
    p_temp numeric,
    p_pressure int,
)
returns text as $$ 
declare 
    v_ddchm text;
    v_vvvv text;
    v_bbb text;
    v_tt text;
    v_delta_p int;
    v_virtual_temp numeric;
    v_delta_t numeric;
    v_correction numeric;
begin
    -- ДДЧЧМ: дата и время окончания зондирования
    v_ddchm := to_char(now(), 'DD') || lpad((extract(hour from now())::int)::text, 2, '0') || floor(extract(minute from now()) / 10)::text;

    -- ВВВВ: высота метеопоста
    v_vvvv := lpad(greatest(round(p_height), 0)::text, 4, '0');

    -- БББ: разность давления (H0 - 750)
    v_delta_p := p_pressure - 750;
    if v_delta_p >= 0 then
        v_bbb := lpad(v_delta_p::text, 3, '0');
    else
        v_bbb := '5' || lpad(abs(v_delta_p)::text, 2, '0');
    end if;

    -- виртуальная поправка 
    if p_temp < 0 then v_correction := 0;
    elsif p_temp <= 5 then v_correction := 0.5;
    elsif p_temp <= 15 then v_correction := 1.0;
    elsif p_temp <= 20 then v_correction := 1.5;
    elsif p_temp <= 25 then v_correction := 2.0;
    elsif p_temp <= 30 then v_correction := 3.5;
    else v_correction := 4.5;
    end if;

    -- отклонение приземной виртуальной температуры 
    v_virtual_temp := p_temp + v_correction;
    v_delta_t := round(v_virtual_temp - 15.9);
    
    if v_delta_t >= 0 then
        v_tt := lpad(v_delta_t::text, 2, '0');
    else
        v_tt := '5' || lpad(ABS(v_delta_t)::text, 1, '0');
    end if;
    
    return v_ddchm || ' ' || v_vvvv || ' ' || v_bbb || v_tt;
end;
$$ language plpgsql;
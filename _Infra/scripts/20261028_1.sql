-- //////////////////////////////////////////////////////////////////////////////
-- Проверка расчета
do $$
declare
        var_pressure_value numeric(8,2) default 0;
        var_temperature_value numeric(8,2) default 0;

        var_period text;
        var_pressure text;
        var_height text;
        var_temperature text;
begin

        var_pressure_value :=  round(public.fn_calc_header_pressure(757));
        var_temperature_value := round( public.fn_calc_header_temperature(23));

        select
                -- Дата
                public.fn_calc_header_period(now()) as "ДДЧЧМ",
                --Высота расположения метеопоста над уровнем моря.
            lpad( 60::text, 4, '0' ) as "ВВВВ",
                -- Отклонение наземного давления атмосферы
                lpad(
                                case when var_pressure_value < 0 then
                                        '5' 
                                else ''
                                end ||
                                lpad ( abs((var_pressure_value)::int)::text,2,'0')
                        , 3, '0') as "БББ",
                -- Отклонение приземной виртуальной температуры
                lpad( 
                                case when var_temperature_value < 0 then
                                        '5'
                                else
                                        ''
                                end ||
                                (abs(var_temperature_value)::int)::text
                        , 2,'0') as "TT"
                into
                        var_period, var_height, var_pressure, var_temperature;

                raise notice '==============================';
                raise notice 'Пример расчета метео приближенный';
                raise notice 'ДДЧЧМ: %, ВВВВ: %,  БББ: %, TT: %',  var_period, var_height, var_pressure, var_temperature;

end $$;

-- Домашняя работа от 2026-10-28
do $$
begin

	begin
	
		-- Тип для входных параметров
		drop type if exists input_params_type cascade;
		create type input_params_type as
		(
		        height numeric(8,2),
		        temperature numeric(8,2),
		        pressure numeric(8,2),
		        wind_direction numeric(8,2),
		        wind_speed numeric(8,2),
		        bullet_demolition_range numeric(8,2)
		);
		
		-- Тип с результатами проверки
		drop type if exists check_result_type cascade;
		create type check_result_type as
		(
		        is_check boolean,
		        error_message text,
		        params input_params_type
		);
	
		comment on type input_params_type is 'Тип для входных параметров';
		comment on type check_result_type is 'Тип с результатами проверки';
		
	end;

	
	begin
		
		-- Функция для формирования даты в специальном формате
		drop function if exists public.fn_calc_header_period;
		
		create function public.fn_calc_header_period(
		        par_period timestamp with time zone)
		    returns text
		    language 'plpgsql'
		AS $body$
		declare 
			  var_result text;
		begin	
		  			var_result := (select
		                -- ДД
		                case when (extract(day from par_period) < 10::numeric) then '0'::text else ''::text end || 
		                extract(day from par_period)::text || 
		                -- ЧЧ
		                case when (extract(hour from par_period) < 10::numeric) then '0'::text else ''::text end || 
		                extract(hour from par_period)::text || 
		                -- Десятки минут
		                case when (extract(minute from par_period) < 10::numeric) then '0'::text
		                                else 
		                left(extract(minute from par_period)::text, 1) 
		                end);
	
					return 	var_result;
	
		end;
		$body$;

		comment on function public.fn_calc_header_period(timestamp with time zone)
	    is 'Функция для формирования даты в специальном формате';

	end;

	begin
		
		-- Таблица с настройками
		drop table if exists measurment_settings;
		
		create table measurment_settings
		(
		        key character varying(100) primary key not null,
		        value  character varying(255) ,
		        description text
		);
		
		
		insert into measurment_settings(key, value, description)
		values('min_temperature', '-10', 'Минимальное значение температуры'), 
		('max_temperature', '50', 'Максимальное значение температуры'),
		('min_pressure','500','Минимальное значение давления'),
		('max_pressure','900','Максимальное значение давления'),
		('min_wind_direction','0','Минимальное значение направления ветра'),
		('max_wind_direction','59','Максимальное значение направления ветра'),
		('calc_table_temperature','15.9','Табличное значение температуры'),
		('calc_table_pressure','750','Табличное значение наземного давления'),
		('min_height','0','Минимальная высота'),
		('max_height','400','Максимальная высота');
	
	
		comment on table public.measurment_settings is 'Таблица с настройками';
	
 	 end;

	 begin

		-- Функция для расчета отклонения приземной виртуальной температуры
		drop function if exists   public.fn_calc_header_temperature;
		
		create function public.fn_calc_header_temperature(
		        par_temperature numeric(8,2)
		)
		returns numeric(8,2)
		language 'plpgsql'
		as $body$
		declare
		        default_temperature numeric(8,2) default 15.9;
		        default_temperature_key character varying default 'calc_table_temperature' ;
		        virtual_temperature numeric(8,2) default 0;
		        deltaTv numeric(8,2) default 0;
		        var_result numeric(8,2) default 0;
		begin   
		
		        raise notice 'Расчет отклонения приземной виртуальной температуры по температуре %', par_temperature;
		
		        -- Определим табличное значение температуры
		        Select coalesce(value::numeric(8,2), default_temperature) 
		        from public.measurment_settings 
		        into virtual_temperature
		        where 
		                key = default_temperature_key;
		
		    -- Вирутальная поправка
		        deltaTv := par_temperature + 
		                public.fn_calc_temperature_interpolation(par_temperature => par_temperature);
		                
		        -- Отклонение приземной виртуальной температуры
		        var_result := deltaTv - virtual_temperature;
		        
		        return var_result;
		end;
		$body$;

		comment on function public.fn_calc_header_temperature(numeric(8,2))
	    is 'Функция для расчета отклонения приземной виртуальной температуры';

	end;
	
	begin
			
		-- Функция для расчета отклонения наземного давления
		drop function if exists public.fn_calc_header_pressure;
		create function public.fn_calc_header_pressure
		(
		        par_pressure numeric(8,2))
		        returns numeric(8,2)
		        language 'plpgsql'
		as $body$
		declare
		        default_pressure numeric(8,2) default 750;
		        table_pressure numeric(8,2) default null;
		        default_pressure_key character varying default 'calc_table_pressure' ;
		begin
		
		        raise notice 'Расчет отклонения наземного давления для %', par_pressure;
		
		        -- Определяем граничное табличное значение
		        if not exists (select 1 from public.measurment_settings where key = default_pressure_key ) then
		        Begin
		                table_pressure :=  default_pressure;
		        end;
		        else
		        begin
		                select value::numeric(18,2) 
		                into table_pressure
		                from  public.measurment_settings where key = default_pressure_key;
		        end;
		        end if;
		
		
		        -- Результат
		        return par_pressure - coalesce(table_pressure,table_pressure) ;
		
		end;
		$body$;

		comment on function public.fn_calc_header_pressure(numeric(8,2))
	    is 'Функция для расчета отклонения наземного давления';

	end;

	begin
			
		-- Функция для проверки входных параметров
		drop function if exists public.fn_check_input_params(numeric(8,2), numeric(8,2),   numeric(8,2), numeric(8,2), numeric(8,2), numeric(8,2));
		
		create function public.fn_check_input_params(
		        par_height numeric,
		        par_temperature numeric,
		        par_pressure numeric,
		        par_wind_direction numeric,
		        par_wind_speed numeric,
		        par_bullet_demolition_range numeric)
		    returns check_result_type
		    language 'plpgsql'
		as $body$
		declare
		        var_result public.check_result_type;
		begin
		        var_result.is_check := False;
		
		        -- Температура
		        if not exists (
		                select 1 from (
		                                select 
		                                                coalesce(min_temperature , '0')::numeric(8,2) as min_temperature, 
		                                                coalesce(max_temperature, '0')::numeric(8,2) as max_temperature
		                                from 
		                                (select 1 ) as t
		                                        cross join
		                                        ( select value as  min_temperature from public.measurment_settings where key = 'min_temperature' ) as t1
		                                        cross join 
		                                        ( select value as  max_temperature from public.measurment_settings where key = 'max_temperature' ) as t2
		                                ) as t
		                        where
		                                par_temperature between min_temperature and max_temperature
		                        ) then
		
		                        var_result.error_message := format('Температура % не укладывает в диаппазон!', par_temperature);
		        end if;
		
		        var_result.params.temperature := par_temperature;
		
		
		        -- Давление
		        if not exists (
		                select 1 from (
		                        select 
		                                        coalesce(min_pressure , '0')::numeric(8,2) as min_pressure, 
		                                        coalesce(max_pressure, '0')::numeric(8,2) as max_pressure
		                        from 
		                        (select 1 ) as t
		                                cross join
		                                ( select value as  min_pressure from public.measurment_settings where key = 'min_pressure' ) as t1
		                                cross join 
		                                ( select value as  max_pressure from public.measurment_settings where key = 'max_pressure' ) as t2
		                        ) as t
		                        where
		                                par_pressure between min_pressure and max_pressure
		                                ) then
		
		                        var_result.error_message := format('Давление %s не укладывает в диаппазон!', par_pressure);
		        end if;
		
		        var_result.params.pressure := par_pressure;
		
		                -- Высота
		                if not exists (
		                        select 1 from (
		                                select 
		                                                coalesce(min_height , '0')::numeric(8,2) as min_height, 
		                                                coalesce(max_height, '0')::numeric(8,2) as  max_height
		                                from 
		                                (select 1 ) as t
		                                        cross join
		                                        ( select value as  min_height from public.measurment_settings where key = 'min_height' ) as t1
		                                        cross join 
		                                        ( select value as  max_height from public.measurment_settings where key = 'max_height' ) as t2
		                                ) as t
		                                where
		                                par_height between min_height and max_height
		                                ) then
		
		                                var_result.error_message := format('Высота  %s не укладывает в диаппазон!', par_height);
		                end if;
		
		                var_result.params.height := par_height;
		
		                -- Напрвление ветра
		                if not exists (
		                        select 1 from (
		                                select 
		                                                coalesce(min_wind_direction , '0')::numeric(8,2) as min_wind_direction, 
		                                                coalesce(max_wind_direction, '0')::numeric(8,2) as max_wind_direction
		                                from 
		                                (select 1 ) as t
		                                        cross join
		                                        ( select value as  min_wind_direction from public.measurment_settings where key = 'min_wind_direction' ) as t1
		                                        cross join 
		                                        ( select value as  max_wind_direction from public.measurment_settings where key = 'max_wind_direction' ) as t2
		                        )
		                                where
		                                        par_wind_direction between min_wind_direction and max_wind_direction
		                        ) then
		
		                        var_result.error_message := format('Направление ветра %s не укладывает в диаппазон!', par_wind_direction);
		        end if;
		
		        var_result.params.wind_direction := par_wind_direction;
		        var_result.params.wind_speed := par_wind_speed;
		
		        if coalesce(var_result.error_message,'') = ''  then
		                var_result.is_check = True;
		        end if;
		
		        return var_result;
		
		end;
		$body$;
		
		comment on function public.fn_check_input_params(numeric(8,2), numeric(8,2),   numeric(8,2), numeric(8,2), numeric(8,2), numeric(8,2))
		is 'Функция для проверки входных параметров';

		
		-- Функция для проверки параметров
		drop function if exists public.fn_check_input_params(input_params);
		
		create function public.fn_check_input_params(
		        par_param input_params_type
		)
		returns public.input_params_type
		language 'plpgsql'
		as $body$
		declare
		        var_result check_result_type;
		begin
		
		        var_result := fn_check_input_params(
		                par_param.height, par_param.temperature, par_param.pressure, par_param.wind_direction,
		                par_param.wind_speed, par_param.bullet_demolition_range
		        );
		
		        if var_result.is_check = False then
		                raise exception 'Ошибка %', var_result.error_message;
		        end if;
		
		        return var_result.params;
		end ;
		$body$;

		comment on function fn_check_input_params(input_params_type)
		is 'Функция для проверки параметров';

	end;

	begin
			
		-- Функция для расчета интерполяции для метео приближенный
		drop function if exists public.fn_calc_temperature_interpolation;
		
		create function public.fn_calc_temperature_interpolation(
		                par_temperature numeric(8,2))
		                returns numeric
		                language 'plpgsql'
		as $body$
		        declare 
		                        var_interpolation interpolation_type;
		                var_result numeric(8,2) default 0;
		                var_min_temparure numeric(8,2) default 0;
		                var_max_temperature numeric(8,2) default 0;
		                var_denominator numeric(8,2) default 0;
		        begin
		
		                                raise notice 'Расчет интерполяции для температуры %', par_temperature;
		
		                -- Проверим, возможно температура совпадает со значением в справочнике
		                if exists (select 1 from public.calc_temperature_correction where temperature = par_temperature ) then
		                begin
		                        select correction 
		                        into  var_result 
		                        from  public.calc_temperature_correction
		                        where 
		                                temperature = par_temperature;
		                end;
		                else    
		                begin
		                        -- Получим диапазон в котором работают поправки
		                        select min(temperature), max(temperature) 
		                        into var_min_temparure, var_max_temperature
		                        from public.calc_temperature_correction;
		
		                        if par_temperature < var_min_temparure or   
		                           par_temperature > var_max_temperature then
		
		                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
		                                        var_min_temparure, var_max_temperature;
		                        end if;   
		
		                        -- Получим граничные параметры
		
		                        select x0, y0, x1, y1 
		                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
		                        from
		                        (
		                                select t1.temperature as x0, t1.correction as y0
		                                from public.calc_temperature_correction as t1
		                                where t1.temperature <= par_temperature
		                                order by t1.temperature desc
		                                limit 1
		                        ) as leftPart
		                        cross join
		                        (
		                                select t1.temperature as x1, t1.correction as y1
		                                from public.calc_temperature_correction as t1
		                                where t1.temperature >= par_temperature
		                                order by t1.temperature 
		                                limit 1
		                        ) as rightPart;
		
		                        raise notice 'Граничные значения %', var_interpolation;
		
		                                                 var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);
		                                                 
		                end;
		                end if;
		
		                                return var_result;
		
		end;
		$body$;

		comment on function public.fn_calc_temperature_interpolation
		is 'Функция для расчета интерполяции для метео приближенный';
		
	end;

end $$;	

	

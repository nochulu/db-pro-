do $$
begin
	drop table if exists calc_correction cascade;
	drop table if exists calc_correction_types cascade;
	drop table if exists calc_correction_headers cascade;
	drop table if exists calc_correction_heights cascade;
	drop sequence if exists calc_correction_seq;
	drop sequence if exists calc_correction_types_seq;
	drop sequence if exists calc_correction_headers_seq;
	drop sequence if exists calc_correction_height_seq;

	-- создаем новые структуры
	begin
		-- таблица стандартных высот
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
			id integer primary key not null default nextval('public.calc_correction_height_seq'),
			height integer not null unique
		);

		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);

		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';

		-- отдельный справочник заголовков таблиц
		create sequence calc_correction_headers_seq;
		create table calc_correction_headers
		(
			id integer primary key not null default nextval('public.calc_correction_headers_seq'),
			description text not null,
			header_values integer[] not null
		);

		comment on table calc_correction_headers is 'Справочник заголовков таблиц корректировок';
		comment on column calc_correction_headers.id is 'Уникальный код';
		comment on column calc_correction_headers.description is 'Описание заголовка';
		comment on column calc_correction_headers.header_values is 'Значения в заголовке таблицы (входные значения столбцов)';

		-- справочник типов таблиц корректировок 
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
			id integer not null primary key default nextval('public.calc_correction_types_seq'),
			parent_id integer references calc_correction_types(id),
			measurement_equipment_id integer,
			header_id integer references calc_correction_headers(id),
			description text not null
		);

		comment on table calc_correction_types is 'Справочник типов таблиц корректировок';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurement_equipment_id is 'Тип оборудования (1 - ДМК, 2 - ВР)';
		comment on column calc_correction_types.header_id is 'Код заголовка таблицы (пусто, если значение одно на высоту)';
		comment on column calc_correction_types.description is 'Описание к таблице';

		-- универсальная таблица корректировкко
		create sequence calc_correction_seq;
		create table calc_correction
		(
			id integer not null primary key default nextval('public.calc_correction_seq'),
			height_id integer not null references calc_correction_heights(id),
			type_id integer not null references calc_correction_types(id),
			row_values integer[] not null,
			constraint uk_calc_correction unique (height_id, type_id)
		);

		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками (порядок как в заголовке)';

	end;

	-- добавляем данные
	begin
		-- заголовки
		insert into calc_correction_headers(id, description, header_values)
		values
		(1, 'Таблица 2, отрицательные отклонения', array[1,2,3,4,5,6,7,8,9,10,20,30,40,50]),
		(2, 'Таблица 2, положительные отклонения', array[1,2,3,4,5,6,7,8,9,10,20,30]),
		(3, 'Таблица 3, ДМК, скорость приземного ветра V0', array[3,4,5,6,7,8,9,10,11,12,13,14,15]),
		(4, 'Таблица 3, ВР, дальность сноса пуль Дг',       array[40,50,60,70,80,90,100,110,120,130,140,150]);
		perform setval('calc_correction_headers_seq', 4);

		-- типы таблиц 
		insert into calc_correction_types(id, parent_id, measurement_equipment_id, header_id, description)
		values
		(1, null, null, null, 'Таблица 2, среднее отклонение температуры'),
		(2, null, null, null, 'Таблица 3, скорость среднего ветра'),
		(3, null, null, null, 'Таблица 3, приращение направления среднего ветра'),
		(4, 2, 2, 4,    'Таблица 3, Скорость среднего ветра (ВР)'),
		(5, 3, 2, null, 'Таблица 3, Направление среднего ветра (ВР)'),
		(6, 2, 1, 3,    'Таблица 3, Скорость среднего ветра (ДМК)'),
		(7, 3, 1, null, 'Таблица 3, Направление среднего ветра (ДМК)'),
		(8, 1, null, 2, 'Таблица 2, Положительные отклонения'),
		(9, 1, null, 1, 'Таблица 2, Отрицательные отклонения');
		perform setval('calc_correction_types_seq', 9);

		-- данные таблиц(высота, тип, значения)
		insert into calc_correction(height_id, type_id, row_values)
		select h.id, v.type_id, v.row_values
		from (values
			(200,  9, array[-1,-2,-3,-4,-5,-6,-7,-8,-8,-9,-20,-29,-39,-49]),
			(400,  9, array[-1,-2,-3,-4,-5,-6,-6,-7,-8,-9,-19,-29,-38,-48]),
			(800,  9, array[-1,-2,-3,-4,-5,-6,-6,-7,-7,-8,-18,-28,-37,-46]),
			(1200, 9, array[-1,-2,-3,-4,-4,-5,-5,-6,-7,-8,-17,-26,-35,-44]),
			(1600, 9, array[-1,-2,-3,-3,-4,-4,-5,-6,-7,-7,-17,-25,-34,-42]),
			(2000, 9, array[-1,-2,-3,-3,-4,-4,-5,-6,-6,-7,-16,-24,-32,-40]),
			(2400, 9, array[-1,-2,-2,-3,-4,-4,-5,-5,-6,-7,-15,-23,-31,-38]),
			(3000, 9, array[-1,-2,-2,-3,-4,-4,-4,-5,-5,-6,-15,-22,-30,-37]),
			(4000, 9, array[-1,-2,-2,-3,-4,-4,-4,-4,-5,-6,-14,-20,-27,-34]),

			(200,  4, array[3,4,5,6,7,7,8,9,10,11,12,12]),
			(400,  4, array[4,5,6,7,8,9,10,11,12,13,14,15]),
			(800,  4, array[4,5,6,7,8,9,10,11,13,14,15,16]),
			(1200, 4, array[4,5,7,8,8,9,11,12,13,15,15,16]),
			(1600, 4, array[4,6,7,8,9,10,11,13,14,15,17,17]),
			(2000, 4, array[4,6,7,8,9,10,11,13,14,16,17,18]),
			(2400, 4, array[4,6,8,9,9,10,12,14,15,16,18,19]),
			(3000, 4, array[5,6,8,9,10,11,12,14,15,17,18,19]),
			(4000, 4, array[5,6,8,9,10,11,12,14,16,18,19,20]),

			(200,  5, array[0]),
			(400,  5, array[1]),
			(800,  5, array[2]),
			(1200, 5, array[2]),
			(1600, 5, array[3]),
			(2000, 5, array[3]),
			(2400, 5, array[3]),
			(3000, 5, array[4]),
			(4000, 5, array[4]),

			(200,  6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]),
			(400,  6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]),
			(800,  6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]),
			(1200, 6, array[5,8,11,12,13,16,19,20,22,24,26,28,30]),
			(1600, 6, array[6,8,11,13,14,17,20,21,23,25,27,29,32]),
			(2000, 6, array[6,9,11,13,14,17,20,21,24,26,28,30,32]),
			(2400, 6, array[6,9,12,14,15,18,21,22,25,27,29,32,34]),
			(3000, 6, array[6,9,12,14,15,18,21,23,25,28,30,32,36]),
			(4000, 6, array[6,10,12,14,16,19,22,24,26,29,32,34,36]),

			(200,  7, array[1]),
			(400,  7, array[2]),
			(800,  7, array[3]),
			(1200, 7, array[3]),
			(1600, 7, array[4]),
			(2000, 7, array[4]),
			(2400, 7, array[4]),
			(3000, 7, array[5]),
			(4000, 7, array[5])
		) as v(height, type_id, row_values)
		join calc_correction_heights h on h.height = v.height;

		insert into calc_correction(height_id, type_id, row_values)
		select id, 8, array[1,2,3,4,5,6,7,8,9,10,20,30] from calc_correction_heights;

	end;

	begin
		if to_regclass('public.calc_temperature_correction') is not null then
			alter table public.calc_temperature_correction rename to calc_correction_temperature;
		end if;

		create table if not exists public.calc_correction_temperature
		(
			temperature numeric(8,2),
			correction numeric(8,2)
		);

		delete from public.calc_correction_temperature;
		insert into public.calc_correction_temperature(temperature, correction)
		values (0, 0.5), (5, 0.5), (10, 1), (15, 1), (20, 1.5), (25, 2), (30, 3.5), (40, 4.5);

		if not exists (select 1 from pg_type where typname = 'interpolation_type') then
			create type public.interpolation_type as (x0 numeric(8,2), y0 numeric(8,2), x1 numeric(8,2), y1 numeric(8,2));
		end if;

		if not exists (select 1 from pg_proc where proname = 'fn_calc_interpolation') then
			create function public.fn_calc_interpolation(par_x numeric, par_i public.interpolation_type)
			returns numeric language plpgsql as $F$
			begin
				if par_i.x1 = par_i.x0 then return par_i.y0; end if;
				return par_i.y0 + (par_x - par_i.x0) * (par_i.y1 - par_i.y0) / (par_i.x1 - par_i.x0);
			end;
			$F$;
		end if;

		create or replace function public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    returns numeric
		    language 'plpgsql'
		    cost 100
		    volatile parallel unsafe
		as $BODY$
			declare
				var_interpolation interpolation_type;
				var_result numeric(8,2) default 0;
				var_min_temparure numeric(8,2) default 0;
				var_max_temperature numeric(8,2) default 0;
			begin

				if exists (select 1 from public.calc_correction_temperature where temperature = par_temperature ) then
				begin
					select correction
					into  var_result
					from  public.calc_correction_temperature
					where
						temperature = par_temperature;
				end;
				else
				begin
					select min(temperature), max(temperature)
					into var_min_temparure, var_max_temperature
					from public.calc_correction_temperature;

					if par_temperature < var_min_temparure or
					   par_temperature > var_max_temperature then

						raise exception 'некорректно передан параметр!',
							var_min_temparure, var_max_temperature;
					end if;

					select x0, y0, x1, y1
					into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
					from
					(
						select t1.temperature as x0, t1.correction as y0
						from public.calc_correction_temperature as t1
						where t1.temperature <= par_temperature
						order by t1.temperature desc
						limit 1
					) as leftPart
					cross join
					(
						select t1.temperature as x1, t1.correction as y1
						from public.calc_correction_temperature as t1
						where t1.temperature >= par_temperature
						order by t1.temperature
						limit 1
					) as rightPart;

					raise notice 'граничные значения %', var_interpolation;
					var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);

				end;
				end if;

				return var_result;

			end;
		$BODY$;

		alter function public.fn_calc_temperature_interpolation(numeric)
		    owner to postgres;

		comment on function public.fn_calc_temperature_interpolation(numeric)
		    is 'функция для расчета интерполяции для метео приближенный';
	end;
	commit;
end $$;

-- Скрипт миграции PL/pgSQL
do $$
declare
	   max_base_units integer;
	   max_employees integer;
	   max_measurement_parameter_types integer;
	   max_measurment_batchs integer;
	   max_measurment_equipment integer;
	   max_measurment_input_params integer;
	   max_military_positions integer;
	   max_units integer;
begin

	-- Вложенная транзакция
	-- Данные из файла 20260923.sql
	begin
		drop table if exists military_ranks;
		drop table if exists employees;
		drop table if exists measurment_types;
		drop table if exists measurment_input_params;
		drop table if exists measurment_baths;
		
		-- 1. Справочник должностей
		create table military_ranks
		(
			id integer,
			description character varying(255)
		);
		
		comment on table military_ranks is 'Справочник должностей';
		comment on column military_ranks.id is 'Уникальный код';
		comment on column military_ranks.description is 'Описание';
		
		-- Заполняем данные
		insert into military_ranks(id, description)
		values(1,'Рядовой'),(2,'Лейтенант');
		
		-- 2. Пользователя
		create table employees
		(
		    id integer,
			name text,
			birthday timestamp ,
			military_rank_id integer
		);
		
		comment on table employees is 'Пользователи';
		comment on column employees.id is 'Уникальный код';
		comment on column employees.name is 'Наименование';
		comment on column employees.birthday is 'Дата рождения';
		comment on column employees.military_rank_id is 'Уникальный код должности';
		
		-- Заполняем данные
		insert into employees(id, name, birthday,military_rank_id )  
		values(1, 'Воловиков Александр Сергеевич','1978-06-24', 2);
		
		-- 3. Устройства для измерения
		create table measurment_types
		(
		   id integer,
		   short_name  character varying(50),
		   description text 
		);
		
		comment on table measurment_types is 'Измерительное оборудование';
		comment on column measurment_types.id is 'Уникальный код';
		comment on column measurment_types.short_name is 'Краткое наименование';
		comment on column measurment_types.description is 'Описание';
		
		-- Заполняем данные
		insert into measurment_types(id, short_name, description)
		values(1, 'ДМК', 'Десантный метео комплекс'),
		(2,'ВР','Ветровое ружье');
		
		
		-- 3. Таблица с параметрами
		create table measurment_input_params
		(
		    id integer,
			measurment_bath_id integer,
			height numeric(8,2) default 0,
			temperature numeric(8,2) default 0,
			pressure numeric(8,2) default 0,
			wind_direction numeric(8,2) default 0,
			wind_speed numeric(8,2) default 0
		);
		
		comment on table measurment_input_params is 'Таблица с параметрами';
		comment on column measurment_input_params.id is 'Уникальный код';
		comment on column measurment_input_params.measurment_bath_id is 'Уникальный код пачки';
		comment on column measurment_input_params.height is 'Высота';
		comment on column measurment_input_params.temperature is 'Температура';
		comment on column measurment_input_params.pressure is 'Давление';
		comment on column measurment_input_params.wind_direction is 'Направление ветка';
		comment on column measurment_input_params.wind_speed is 'Скорость ветра';
		
		-- Заполняем данные
		insert into measurment_input_params(id, measurment_bath_id, height, temperature, pressure, wind_direction,wind_speed )
		values(1, 1, 100,12,34,0.2,45);
		
		
		
		-- 4. Таблица с историей
		create table measurment_baths
		(
			id integer ,
			emploee_id integer,
			measurment_type_id integer,
			started timestamp default now()
		);
		
		comment on table measurment_baths is 'Пачки';
		comment on column measurment_baths.emploee_id is 'Уникальный код пользователя';
		comment on column measurment_baths.measurment_type_id is 'Уникальный код оборудования';
		comment on column measurment_baths.started is 'Дата измерения';
		
		-- Заполняем данные
		insert into measurment_baths(id, emploee_id, measurment_type_id, started)
		values(1, 1, 1, '2026-09-01'),(2,1,2, '2026-09-02');
	end;
	commit;

	-- Вложенная транзакция 20260930.sql
	begin
		-- Исправляем наименования
		alter table military_ranks rename to military_positions;
		alter table employees rename column military_rank_id to military_position_id;
		alter table measurment_types rename to measurment_equipment;
		alter table measurment_baths rename column measurment_type_id to measurment_equipment_id;
		alter table measurment_baths rename to measurment_batchs;
		alter table measurment_input_params rename column measurment_bath_id to measurment_batch_id;
		
		
		
		-- Справочник базовых единиц измерений
		create table base_units
		(
		    id integer,
			name text
		);
		
		comment on table base_units is 'Базовые единицы измерения';
		comment on column base_units.id is 'Уникальный код';
		comment on column base_units.name is 'Наименование';
		
		insert into base_units (id, name)
		values 
			(1, 'Метр'),
			(2 ,'Градус'),
			(3, 'Паскаль');
		
		
		-- 	Справочник единиц измерения
		create table units
		(
		    id integer,
			name text,
			base_unit_id integer,
			convert_factor integer
		);
		
		comment on table units is 'Единицы измерения';
		comment on column units.id is 'Уникальный код';
		comment on column units.name is 'Наименование';
		comment on column units.base_unit_id is 'Уникальный код базовой единицы измерения';
		comment on column units.convert_factor is 'Коэффициент пересчета';
		
		insert into units(id, name, base_unit_id, convert_factor)
		values
		   (1, 'Киллометр', 1, 1000),
		   (2, 'Градус', 2, 1),
		   (3, 'Паскаль', 3, 1),
		   (4, 'Метр', 1, 1),
		   (5, 'Миллиметры ртутного столба', null, null),
		   (6, 'Метр в секунду', null, null);
		
		-- Справочник типов параметров
		create table measurement_parameter_types
		(
		   id integer,
		   name text,
		   unit_id integer,
		   measurment_equipment_id integer
		);
		
		comment on table measurement_parameter_types is 'Справочник типов параметров';
		comment on column measurement_parameter_types.id is 'Уникальный код';
		comment on column measurement_parameter_types.name is 'Наименование';
		comment on column measurement_parameter_types.unit_id is 'Уникальный код единицы измерения';
		comment on column measurement_parameter_types.measurment_equipment_id is 'Уникальный код оборудования';
		
		insert into measurement_parameter_types(id, name, unit_id, measurment_equipment_id)
		values
		   (1, 'Высота метеопаста', 4, null),
		   (2, 'Температура', 2, null),
		   (3, 'Давление', 5, null),
		   (4, 'Направление ветра', null, null),
		   (5, 'Скорость ветра', 6, 1),
		   (6, 'Дальность сноса пуль', null, 2);
		
		-- Меняем данные в основной таблицы параметров
		alter table measurment_input_params add measurement_parameter_type_id integer;
		alter table measurment_input_params add measurement_value numeric(10,2);
		
	
		-- Высота
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		select 2, measurment_batch_id, 1, height as measurement_value
		from	measurment_input_params where id = 1;
		
		-- Температура
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		select 3, measurment_batch_id, 2, temperature as measurement_value
		from	measurment_input_params where id = 1;
		
		-- Давление
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		select 4, measurment_batch_id, 3, pressure as measurement_value
		from	measurment_input_params where id = 1;
		
		-- Направление ветра
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		select 5, measurment_batch_id, 4, wind_direction as measurement_value
		from	measurment_input_params where id = 1;
		
		-- Скорость ветка
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		select 6, measurment_batch_id, 5, wind_speed as measurement_value
		from	measurment_input_params where id = 1;
		
		-- Дальность сноса пуль
		insert into public.measurment_input_params(id, measurment_batch_id, measurement_parameter_type_id, measurement_value)
		values (7, 1, 6, 0);
		
		-- Удаляем старые данные и колонки
		delete from measurment_input_params where id = 1;
		alter table measurment_input_params drop column height;
		alter table measurment_input_params drop column temperature;
		alter table measurment_input_params drop column pressure;
		alter table measurment_input_params drop column wind_direction;
		alter table measurment_input_params drop column wind_speed;
	end;
    commit;

	-- Вложенная транзакция
	-- Создаем счетчики
	begin
		max_base_units := (select max(id)  from public.base_units );
		max_employees = (select max(id) from public.employees);
		max_measurement_parameter_types = (select max(id) from public.measurement_parameter_types);
		max_measurment_batchs = (select max(id) from public.measurment_batchs);
		max_measurment_equipment = (select max(id) from public.measurment_equipment);
		max_measurment_input_params = (select max(id) from public.measurment_input_params);
		max_military_positions = (select max(id) from public.military_positions);
		max_units = (select max(id) from public.units);

		create sequence seq_base_units;
		create sequence seq_employees;
		create sequence seq_measurement_parameter_types; 
		create sequence seq_measurment_batchs; 
		create sequence seq_measurment_equipment ; 
		create sequence seq_measurment_input_params; 
		create sequence seq_military_positions; 
		create sequence seq_units ; 

		PERFORM setval('seq_base_units', max_base_units);
		PERFORM setval('seq_employees', max_employees);
		PERFORM setval('seq_measurement_parameter_types', max_measurement_parameter_types);
		PERFORM setval('seq_measurment_batchs', max_measurment_batchs);
		PERFORM setval('seq_measurment_equipment', max_measurment_equipment);
		PERFORM setval('seq_measurment_input_params', max_measurment_input_params);
		PERFORM setval('seq_military_positions', max_military_positions);
		PERFORM setval('seq_units', max_units);

	end;
	commit;

	-- Вложенная транзакция
	-- Создаем ограничения
	begin

		-- Подключаем счетчики
		alter table public.base_units alter column id set default(nextval('public.seq_base_units'));
		alter table public.employees alter column id set default(nextval('public.seq_employees'));
		alter table public.measurement_parameter_types alter column id set default(nextval('public.seq_measurement_parameter_types'));
		alter table public.measurment_batchs alter column id set default(nextval('public.seq_measurment_batchs'));
		alter table public.measurment_equipment alter column id set default(nextval('public.seq_measurment_equipment'));
		alter table public.measurment_input_params alter column id set default(nextval('public.seq_measurment_input_params'));
		alter table public.military_positions alter column id set default(nextval('public.seq_military_positions'));
		alter table public.units alter column id set default(nextval('public.seq_units'));

		-- Подключаем ограничения
		alter table public.base_units add constraint pk_base_units primary key (id);
		alter table public.employees add constraint pk_employees primary key (id);
		alter table public.measurement_parameter_types add constraint pk_measurement_parameter_types primary key (id);
		alter table public.measurment_batchs add constraint pk_measurment_batchs primary key (id);
		alter table public.measurment_equipment add constraint pk_measurment_equipment primary key (id);
		alter table public.measurment_input_params add constraint pk_measurment_input_params primary key (id);
		alter table public.military_positions add constraint pk_military_positions primary key (id);
		alter table public.units add constraint pk_units primary key (id);

	end;
	commit;

	-- Вложенная транзакция
	-- Добавляем связи
	begin

		alter table units add constraint  fk_units_base_unit 
		foreign key (base_unit_id) 
		references public.base_units (id);

		alter table employees add constraint  fk_employees_military_positions
		foreign key (military_position_id) 
		references public.military_positions(id);

		alter table public.measurement_parameter_types add constraint  fk_measurement_parameter_types_units
		foreign key (unit_id) 
		references public.units(id);

		alter table public.measurement_parameter_types add constraint  fk_measurement_parameter_types_measurment_equipment
		foreign key (measurment_equipment_id) 
		references public.measurment_equipment (id);

		alter table public.measurment_batchs add constraint  fk_measurment_batchs_employees
		foreign key (emploee_id) 
		references public.employees(id);

		alter table measurment_batchs add constraint  fk_measurment_batchs_measurment_equipment
		foreign key (measurment_equipment_id) 
		references public.measurment_equipment(id);
		

		alter table public.measurment_input_params add constraint  fk_measurment_input_params_measurment_batchs
		foreign key (measurment_batch_id) 
		references public.measurment_batchs(id);

		alter table measurment_input_params add constraint  fk_measurment_input_params_measurement_parameter_types
		foreign key (measurement_parameter_type_id) 
		references public.measurement_parameter_types(id);

	end;
	commit;

	-- Вложенная транзакция
	-- Добавляем рассчетную таблицу
	begin
	
		create table calc_temperature_correction
		(
		   temperature numeric(8,2) not null primary key,
		   correction numeric(8,2) not null
		);
		
		insert into public.calc_temperature_correction(temperature, correction)
		values(0, 0.5),(5, 0.5),(10, 1), (20,1), (25, 2), (30, 3.5), (40, 4.5);

	end;
	

end $$;

	

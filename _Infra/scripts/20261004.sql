-- 1. Каждый пользователь имеет одинаковое количество измерений?
select 
	name, min(cnt_measurment) as min_cnt_measurment, max(cnt_measurment) as max_cnt_measurment from 
(
	-- Получаем полный список всех пользователей и количество измерений
	select name, coalesce(cnt_measurment, 0) as cnt_measurment from public.employees as t1
	left join
	(
		-- Получаем список всех пользователей и количество измерений
		select   employee_id, cnt_measurment from public.measurement_batchs as t1
		inner join 
		(
			-- Получаем список всех пачек задействованных в измерениях
			select measurement_batch_id, count(*) as cnt_measurment from public.measurement_input_params
			group by measurement_batch_id
		) as t2 on t1.id = t2.measurement_batch_id
	) as t2 on t1.id = 	employee_id
) as t1
where 
	-- Показываем только пользователей 
	-- У которых количество измерений не верное
	t1.cnt_measurment != 5
group by name	


-- 2. У нас нет пустых пачек измерения?
select * from public.measurement_batchs as t1
left join public.measurement_input_params as t2
on
    t1.id = t2.measurement_batch_id
where
    t2.measurement_batch_id is null

-- 3. Каждая пачка измерений содержит полное количеситво параметров (5 шт)?	
select id, coalesce(cnt_measurment, 0) as  cnt_measurment
from public.measurement_batchs as t1
left join
(
	select measurement_batch_id, count(*)  as cnt_measurment
	from measurement_input_params as t1
	group by measurement_batch_id
	having count(*) != 5
) as t2 on t1.id = t2.measurement_batch_id	

-- 4 Все значения который сформировал корректны и в рамках нужного нам диаппазонов?
select * from public.measurement_input_params as t1
inner join public.measurement_parameter_types as t2 
on t1.measurement_parameter_type_id = t2.id
where
    0 = case 
	    -- Высота метеопоста
		when measurement_parameter_type_id = 1 
		and measurement_value between 200 and 750
		then 1
		-- Темпераьура
		when measurement_parameter_type_id = 2
		and measurement_value between -58 and 58
		then 1
		-- Давление
		when measurement_parameter_type_id = 3 
		and measurement_value between 500 and 900
		then 1
		-- И так далее
		else
		     0
	end

-- 5. Все единицы измерения верны и корректны по отношению к указанным параметрам?	
select * from public.measurement_input_params as t1
inner join public.measurement_parameter_types as t2 
	on t1.measurement_parameter_type_id = t2.id
inner join 	public.base_units as t3 
	on t3.id  = t2.unit_id
where
	0 = case 
		-- Температура
		when measurement_parameter_type_id = 2 
		and t3.id = 2
		then 1
		-- И так далее
		else 0 
		end
	





	
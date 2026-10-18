DROP FUNCTION IF EXISTS get_interpolation_params(numeric) CASCADE;
DROP FUNCTION IF EXISTS calculate_interpolation(numeric, interpolations_type) CASCADE;
DROP TABLE IF EXISTS calc_temperature_correction CASCADE;
DROP TYPE IF EXISTS public.interpolations_type CASCADE;

-- создание пользовательского типа данных 
CREATE TYPE public.interpolations_type as (
    x0 numeric(8,2),
    y0 numeric(8,2),
    x1 numeric(8,2),
    y1 numeric(8,2)
);

-- создание таблицы и наполнение тестовыми данными
CREATE TABLE calc_temperature_correction (
    temperature numeric(8,2),
    correction numeric(8,2)
);

INSERT INTO public.calc_temperature_correction(temperature, correction)
VALUES (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5);

-- функция для определения параметров интерполяции
CREATE OR REPLACE FUNCTION get_interpolation_params(par_temperature numeric)
returns interpolations_type AS $func$
DECLARE
    v_result interpolations_type;
BEGIN
    SELECT temperature, correction
    INTO v_result.x0, v_result.y0
    FROM calc_temperature_correction
    WHERE temperature <= par_temperature
    ORDER BY temperature DESC
    LIMIT 1;

    SELECT temperature, correction
    INTO v_result.x1, v_result.y1
    FROM calc_temperature_correction
    WHERE temperature >= par_temperature
    ORDER BY temperature ASC
    LIMIT 1;

    IF v_result.x0 IS NULL then
        v_result.x0 := v_result.x1;
        v_result.y0 := v_result.y1;
    END IF;
    
    IF v_result.x1 IS NULL then
        v_result.x1 := v_result.x0;
        v_result.y1 := v_result.y0;
    END IF;

    RETURN v_result;
END;
$func$ language plpgsql;

-- функция расчета линейной интерполяции
CREATE OR REPLACE FUNCTION calculate_interpolation(p_x numeric, p_struct interpolations_type)
returns numeric AS $func$
BEGIN
    IF p_struct.x1 = p_struct.x0 then
        RETURN p_struct.y0;
    END IF;
    
    RETURN p_struct.y0 + (p_x - p_struct.x0) * (p_struct.y1 - p_struct.y0) / (p_struct.x1 - p_struct.x0);
END;
$func$ language plpgsql;
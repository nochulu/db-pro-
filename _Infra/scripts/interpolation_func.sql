DO $$
BEGIN
    --удаление существующих объектов
    DROP FUNCTION IF EXISTS get_interpolation_params(numeric) CASCADE;
    DROP FUNCTION IF EXISTS calculate_interpolation(numeric, interpolations_type) CASCADE;
    DROP TABLE IF EXISTS calc_temperature_correction CASCADE;
    DROP TYPE IF EXISTS public.interpolations_type CASCADE;
    COMMIT;

    --создание пользовательского типа данных
    CREATE TYPE public.interpolations_type AS (
        x0 numeric(8,2),
        y0 numeric(8,2),
        x1 numeric(8,2),
        y1 numeric(8,2)
    );

    COMMENT ON TYPE public.interpolations_type IS
        'структура параметров для линейной интерполяции: две точки (x0,y0) и (x1,y1)';
    COMMIT;

    --создание таблицы и наполнение тестовыми данными
    CREATE TABLE calc_temperature_correction (
        temperature numeric(8,2),
        correction  numeric(8,2)
    );

    COMMENT ON TABLE calc_temperature_correction IS
        'таблица поправок температуры';

    COMMENT ON COLUMN calc_temperature_correction.temperature IS 'значение температуры';
    COMMENT ON COLUMN calc_temperature_correction.correction  IS 'поправка для данной температуры';

    INSERT INTO public.calc_temperature_correction(temperature, correction)
    VALUES (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5);
    COMMIT;

    --функция для определения параметров интерполяции
    CREATE OR REPLACE FUNCTION get_interpolation_params(par_temperature numeric)
    RETURNS interpolations_type
    LANGUAGE plpgsql
    AS $func$
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

        IF v_result.x0 IS NULL THEN
            v_result.x0 := v_result.x1;
            v_result.y0 := v_result.y1;
        END IF;

        IF v_result.x1 IS NULL THEN
            v_result.x1 := v_result.x0;
            v_result.y1 := v_result.y0;
        END IF;

        RETURN v_result;
    END;
    $func$;

    COMMENT ON FUNCTION get_interpolation_params(numeric) IS
        'возвращает две ближайшие точки (x0,y0) и (x1,y1) из таблицы поправок для заданной температуры. используется для последующей линейной интерполяции.';
    COMMIT;

    --функция расчёта линейной интерполяции
    CREATE OR REPLACE FUNCTION calculate_interpolation(p_x numeric, p_struct interpolations_type)
    RETURNS numeric
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        IF p_struct.x1 = p_struct.x0 THEN
            RETURN p_struct.y0;
        END IF;

        RETURN p_struct.y0 + (p_x - p_struct.x0) * (p_struct.y1 - p_struct.y0) / (p_struct.x1 - p_struct.x0);
    END;
    $func$;

    COMMENT ON FUNCTION calculate_interpolation(numeric, interpolations_type) IS
        'вычисляет значение линейной интерполяции в точке px по двум точкам, переданным в структуре interpolations_type.';
END;
$$;
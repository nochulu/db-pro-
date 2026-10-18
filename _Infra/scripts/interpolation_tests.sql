DO $$ 
BEGIN
    RAISE NOTICE 'x = -5, y = %', calculate_interpolation(-5, get_interpolation_params(-5));
    RAISE NOTICE 'x = 12, y = %', calculate_interpolation(12, get_interpolation_params(12));
    RAISE NOTICE 'x = 26, y = %', calculate_interpolation(26, get_interpolation_params(26));
    RAISE NOTICE 'x = 35, y = %', calculate_interpolation(35, get_interpolation_params(35));
    RAISE NOTICE 'x = 25, y = %', calculate_interpolation(25, get_interpolation_params(25));
    RAISE NOTICE 'x = 45, y = %', calculate_interpolation(45, get_interpolation_params(45));
END $$;
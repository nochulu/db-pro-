SELECT 
    ROW_NUMBER() OVER (ORDER BY table_name) AS "№",
    table_name AS "Наименование",
    'Таблица' AS "Тип"
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';
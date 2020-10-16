CREATE OR REPLACE FUNCTION drop_tables() RETURNS void as $do$
DECLARE
   _sql text;
   _schema information_schema.sql_identifier = 'public'::information_schema.sql_identifier;
BEGIN
   SELECT INTO _sql
          string_agg(format('DROP TABLE IF EXISTS %s CASCADE;', t.table_name), E'\n')
   FROM   information_schema.tables t
   WHERE  t.table_schema = _schema;

   IF _sql IS NOT NULL THEN
      RAISE NOTICE E'\n\n%', _sql;  -- debug / check first
      EXECUTE _sql;            -- uncomment payload once you are sure
   END IF;
END;
$do$ language plpgsql;


DO $$ BEGIN
    PERFORM drop_tables();
END $$;
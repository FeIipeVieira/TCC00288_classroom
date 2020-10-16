DO $$
DECLARE
   _sql text;
   _schema regnamespace = 'public'::regnamespace;
BEGIN
   SELECT INTO _sql
          string_agg(format('DROP %s %s CASCADE;'
                          , CASE prokind
                              WHEN 'f' THEN 'FUNCTION'
                              WHEN 'a' THEN 'AGGREGATE'
                              WHEN 'p' THEN 'PROCEDURE'
                              WHEN 'w' THEN 'FUNCTION'
                            END
                          , oid::regprocedure)
                   , E'\n')
   FROM   pg_proc
   WHERE  pronamespace = _schema;

   IF _sql IS NOT NULL THEN
      RAISE NOTICE E'\n\n%', _sql;
      EXECUTE _sql;
   END IF;
END$$;

CREATE OR REPLACE FUNCTION drop_functions() RETURNS void as $do$
DECLARE
   _sql text;
   _schema regnamespace = 'public'::regnamespace;
BEGIN
   SELECT INTO _sql
          string_agg(format('DROP %s %s CASCADE;'
                          , CASE prokind
                              WHEN 'f' THEN 'FUNCTION'
                              WHEN 'a' THEN 'AGGREGATE'
                              WHEN 'p' THEN 'PROCEDURE'
                              WHEN 'w' THEN 'FUNCTION'  -- window function (rarely applicable)
                              -- ELSE NULL              -- not possible in pg 11
                            END
                          , oid::regprocedure)
                   , E'\n')
   FROM   pg_proc
   WHERE  pronamespace = _schema
   AND not array[proname] <@ '{"drop_functions","drop_tables"}';

   IF _sql IS NOT NULL THEN
      RAISE NOTICE E'\n\n%', _sql;
      EXECUTE _sql;
   END IF;
END$do$ language plpgsql;


DO $$ BEGIN
    PERFORM drop_functions();
END $$;
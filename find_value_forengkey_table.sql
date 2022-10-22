CREATE OR REPLACE FUNCTION get_references_values_catalogo(table_name_ text, out_table ANYELEMENT)
--RETURNS SETOF car_portal_app.account 
RETURNS SETOF  anyelement   
--RETURNS SETOF ANYELEMENT 
LANGUAGE plpgsql AS
$$
	DECLARE sql_ TEXT;
	DECLARE sql_union TEXT;
	DECLARE count_ INTEGER;
	DECLARE data_ RECORD;
	BEGIN
		sql_ = '';
		sql_union = '';
		count_ = 0;
		FOR data_ IN SELECT DISTINCT tc.table_schema, tc.table_name, kcu.column_name, ccu.table_schema AS foreign_table_schema,
    	ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name 
		FROM information_schema.table_constraints AS tc 
		JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
		JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
		WHERE tc.constraint_type = 'FOREIGN KEY' AND ccu.table_name = table_name_ order by 1,2,3 LOOP 
			if count_ > 0 then
				sql_union = 'UNION ';
			end if;
			--sql_ = CONCAT(sql_, chr(10), sql_union, 'SELECT DISTINCT ', data_.column_name, ' FROM ', data_.table_schema, '.', data_.table_name);
			RETURN QUERY EXECUTE CONCAT(chr(10), sql_union, 'SELECT DISTINCT ', data_.column_name, ' FROM ', data_.table_schema, '.', data_.table_name);
			--count_ = count_ + 1;
			--RETURN out_table;
		END LOOP;
	 /*EXECUTE sql_ INTO out_table;
	 RETURN out_table;*/
	END;
$$;

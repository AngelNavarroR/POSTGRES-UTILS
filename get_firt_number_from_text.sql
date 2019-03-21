-- LA CADENA DE TEXTO LA CONVIERTE A UN ARRAY SEPARANDO LOS NUMEROS DE LOS CHARACTERS DEVUELVE LOS NUMEROS MAYORES A OCHO DIGITOS
CREATE OR REPLACE FUNCTION get_firt_number_from_text(to_text_with_number text) RETURNS INTEGER AS $$
DECLARE 
	text_array text[];
	text_ text;
    BEGIN
		IF to_text_with_number ~ '\d$' THEN 
			--RAISE NOTICE 'TEXT IS NUMBER';
			return to_text_with_number;
		END IF;
		text_array = regexp_matches(to_text_with_number, '(?:(\d+)){1,1}');
		IF ARRAY_LENGTH(text_array, 1) > 0 THEN 
        FOREACH text_ IN ARRAY text_array
				LOOP
				--RAISE NOTICE '% TEXT IS NUMBER %', text_, text_ ~ '\d$';
				IF text_ ~ '\d$' THEN 
					text_ = regexp_replace(text_, '\.', '');
					text_ = regexp_replace(text_, E'[ tnr]+', '', 'g');
					RETURN text_;
				END IF;
				END LOOP;
		END IF;
		RETURN NULL;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT get_firt_number_from_text('321315A');


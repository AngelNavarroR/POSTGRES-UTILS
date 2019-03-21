-- LA CADENA DE TEXTO LA CONVIERTE A UN ARRAY SEPARANDO LOS NUMEROS DE LOS CHARACTERS DEVUELVE LOS NUMEROS MAYORES A OCHO DIGITOS
CREATE OR REPLACE FUNCTION get_number_from_text(to_text_with_number text) RETURNS text AS $$
DECLARE 
	text_array text[];
	text_ text;
    BEGIN
		text_array = regexp_matches(to_text_with_number, '(^.*?)([+-]?\d*\.?\d+)(.*$)');
		--SELECT ARRAY_LENGTH(array[1], 1);
		IF ARRAY_LENGTH(text_array, 1) > 1 THEN 
        FOREACH text_ IN ARRAY text_array
				LOOP
				--RAISE NOTICE '% TEXT IS NUMBER %', text_, text_ ~ '\d$';      -- single quotes!
				IF text_ ~ '\d$' THEN 
					text_ = regexp_replace(text_, '\.', '');
					text_ = regexp_replace(text_, E'[ tnr]+', '', 'g');
					IF LENGTH(text_) >= 8 THEN 
						RETURN text_;
					END IF;
				END IF;
				END LOOP;
		END IF;
		RETURN NULL;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

EJEMPLOS
-- SELECT get_number_text('XXXXX ANGEL ANIBAL C.C. 1100224771');
-- SELECT get_number_text('XXXXX CARPETA 2018-00005');
-- SELECT get_number_text('XXXX MERCANTIL XXXXX PICHINCHA 8 FIMUPO 8');
-- SELECT get_number_text(NULL);

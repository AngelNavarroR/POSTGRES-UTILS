
CREATE OR REPLACE FUNCTION esNumero(to_text_with_number text) RETURNS boolean AS $$
DECLARE 
    BEGIN
		RETURN to_text_with_number ~ '^[0-9\.]+$';
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

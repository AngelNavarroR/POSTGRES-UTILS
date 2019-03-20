CREATE OR REPLACE FUNCTION clean_whitespace(to_clean text) RETURNS text AS $$
    BEGIN
        RETURN regexp_replace(to_clean, E'[ tnr]+', ' ', 'g');
    END;
$$ LANGUAGE plpgsql IMMUTABLE;
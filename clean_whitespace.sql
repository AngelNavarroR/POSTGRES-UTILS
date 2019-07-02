CREATE OR REPLACE FUNCTION clean_whitespace(to_clean text) RETURNS text AS $$
    BEGIN
        to_clean = regexp_replace(to_clean, E'[ \t]+', ' ', 'g');
        RETURN regexp_replace(to_clean, E'[ tnr]+', ' ', 'g');
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

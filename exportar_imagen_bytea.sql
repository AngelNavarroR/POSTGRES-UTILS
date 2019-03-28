CREATE OR REPLACE FUNCTION exportar_imagen(cod_reg_ BIGINT)
    RETURNS integer LANGUAGE 'plpgsql' COST 100 VOLATILE 
AS $BODY$

DECLARE 
	l_lob_id OID;
	l_lob_id2 OID;
   r record;
BEGIN
	  for r in
			SELECT cod_imag, imagen, anota, cod_reg idBLob FROM imag_dia_dia WHERE cod_reg = cod_reg_
		LOOP
			l_lob_id:=lo_from_bytea(0,r.imagen);
			PERFORM lo_export(l_lob_id,'D:'||r.cod_imag||'imagen.tiff');
			PERFORM lo_unlink(l_lob_id); 
			
			l_lob_id2:=lo_from_bytea(0,r.anota);
			PERFORM lo_export(l_lob_id2,'D:'||r.cod_imag||'anota.tiff');
			PERFORM lo_unlink(l_lob_id2);   
    END LOOP;
	RETURN 0;
END;

$BODY$;
-- USO 
-- SELECT exportar_imagen(45947)
-- SELECT exportar_imagen(45948)
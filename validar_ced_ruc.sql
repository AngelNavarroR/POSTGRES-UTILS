CREATE OR REPLACE FUNCTION public.validar_ced_ruc(ced_ruc TEXT)
  RETURNS BOOLEAN AS
$BODY$

DECLARE 
	estado BOOLEAN;
	provincia int;
	ced_ruc_array TEXT[];

BEGIN
	estado = FALSE;
	SELECT array_agg(x) INTO ced_ruc_array FROM regexp_split_to_table(ced_ruc, E'\\s*') x;
	
	IF LENGTH(ced_ruc) >= 10 THEN -- CEDULA
		provincia = CAST(ced_ruc_array[1] AS INT) + CAST(ced_ruc_array[2] AS INT);
		IF (provincia > 0 AND provincia <= 25) THEN
			IF (CAST(ced_ruc_array[3] AS INT) < 6) THEN -- PERSONA 
				estado = varificar_cedula(ced_ruc);
			ELSIF (CAST(ced_ruc_array[3] AS INT) = 6) THEN -- SECTOR PULICO 
				estado = varificar_sector_publico(ced_ruc);
			ELSIF (CAST(ced_ruc_array[3] AS INT) = 9) THEN -- RUC 
				estado = varificar_persona_juridica(ced_ruc);
			END IF;
		END IF;
	ELSE -- MENOR A 10 EL NUMERO DE IDENTIFICACION 
		estado = FALSE;
	END IF;
	RETURN estado;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;


CREATE OR REPLACE FUNCTION varificar_cedula(cedl TEXT) RETURNS BOOLEAN AS
$BODY$

DECLARE 
	valido BOOLEAN = false;
	aux int = 0;
	par int = 0;
	impar int = 0;
	i int = 1;
	verifi int;
	provincia int;
	ced_array TEXT[];

BEGIN
	i = 1;
	SELECT array_agg(x) INTO ced_array FROM regexp_split_to_table(cedl, E'\\s*') x;
	FOR i IN 1..9 BY 2 LOOP
		aux = 2 * CAST(ced_array[i] AS INT);
		IF (aux > 9) THEN 
				aux = aux - 9;
		END IF;
		par = par + aux;
	END LOOP;
-- VERIFICACION 
	i = 2;
	FOR i IN 2..9 BY 2 LOOP
		impar = impar + CAST(ced_array[i] AS INT);
	END LOOP;

	aux = par + impar;
	IF ((aux % 10) <> 0) THEN
		verifi = 10 - (aux % 10);
	ELSE
		verifi = 0;
	END IF;
	IF (verifi = CAST(ced_array[LENGTH(cedl)] AS INT)) THEN  
		valido = true;
	ELSE 
		valido = false;
	END IF;
	RETURN valido;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;

CREATE OR REPLACE FUNCTION varificar_persona_juridica(cedl TEXT) RETURNS BOOLEAN AS
$BODY$

DECLARE 
	valido BOOLEAN = false;
	aux int = 0;
	prod int = 0;
	i int = 1;
	verifi int;
	provincia int;
	ced_array TEXT[];
	coeficiente int[9] = ARRAY[4, 3, 2, 7, 6, 5, 4, 3, 2];

BEGIN
	-- CONVERTIMOS EN ARRAY EL NUMERO
	i = 1;
	SELECT array_agg(x) INTO ced_array FROM regexp_split_to_table(cedl, E'\\s*') x;
	verifi = CAST(ced_array[11] AS INT) + CAST(ced_array[12] AS INT) + CAST(ced_array[13] AS INT);
	IF (verifi > 0) THEN  
		FOR i IN 1..9 LOOP
			prod = CAST(ced_array[i] AS INT) * coeficiente[i];
			aux = aux + prod;
		END LOOP;
		IF (aux % 11 = 0) THEN 
			verifi = 0;
		ELSIF (aux % 11 = 1) THEN 
			valido = FALSE;
		ELSE
			aux = aux % 11;
            verifi = 11 - aux;
		END IF;
		IF (verifi = CAST(ced_array[10] AS INT)) THEN
			valido = TRUE;
		ELSE 
			valido = FALSE;
		END IF;
	ELSE 
        valido = FALSE;        
	END IF;
	RETURN valido;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;

CREATE OR REPLACE FUNCTION varificar_sector_publico(cedl TEXT) RETURNS BOOLEAN AS
$BODY$

DECLARE 
	valido BOOLEAN = false;
	aux int = 0;
	prod int = 0;
	i int = 1;
	verifi int;
	provincia int;
	ced_array TEXT[];
	coeficiente int[8] = ARRAY[3, 2, 7, 6, 5, 4, 3, 2 ];

BEGIN
	-- CONVERTIMOS EN ARRAY EL NUMERO
	i = 1;
	SELECT array_agg(x) INTO ced_array FROM regexp_split_to_table(cedl, E'\\s*') x;
	verifi = CAST(ced_array[10] AS INT) + CAST(ced_array[11] AS INT) + CAST(ced_array[12] AS INT) + CAST(ced_array[13] AS INT);
	IF (verifi > 0) THEN  
		FOR i IN 1..8 LOOP
			prod = CAST(ced_array[i] AS INT) * coeficiente[i];
			aux = aux + prod;
		END LOOP;
		IF (aux % 11 = 0) THEN 
			verifi = 0;
		ELSIF (aux % 11 = 1) THEN 
			valido = FALSE;
		ELSE
			aux = aux % 11;
            verifi = 11 - aux;
		END IF;
		IF (verifi = CAST(ced_array[9] AS INT)) THEN
			valido = TRUE;
		ELSE 
			valido = FALSE;
		END IF;
	ELSE 
        valido = FALSE;        
	END IF;
	RETURN valido;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;


-- Colindantes de un poligono
SELECT ptemp.gid, ptemp.codigo, ROUND(CAST(degrees(ST_Azimuth(ST_Centroid(p.geom), ST_Centroid(ptemp.geom))) AS NUMERIC), 4) area 
FROM geodata.predios_tx p 
INNER JOIN geodata.predios_tx ptemp ON st_intersects(p.geom, ptemp.geom)
WHERE p.codigo = '100154570101621900000000' AND p.codigo <> ptemp.codigo 
ORDER BY area

-- Calles colindantes de un poligono
SELECT CAST(mz.gid AS bigint) AS gid,mz.nombre,mz.clave_cata "claveCata"  FROM geodata.predios_tx pt 
INNER JOIN geodata.geo_vias mz ON ST_intersects(ST_BUFFER(mz.geom, 30), pt.geom) 
WHERE pt.codigo = '100154570101621900000000' LIMIT 5

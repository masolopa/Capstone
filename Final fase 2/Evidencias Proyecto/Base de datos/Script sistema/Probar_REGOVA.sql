-- REGOVA: pruebas de integridad sobre el esquema ya creado.
-- Abrir en Query Tool conectado a REGOVA_BD y ejecutar TODO el archivo.
-- No abre ni crea imagenes, modelos o archivos reales.
-- Los INSERT/UPDATE y objetos temporales se descartan al terminar con ROLLBACK.
-- Las secuencias de ID pueden avanzar; sus saltos son normales.
-- Si aparece ERROR antes del final, ejecutar ROLLBACK; en esta misma pestana.
-- No ejecutar mientras otras personas o procesos esten modificando datos.
BEGIN;
SET LOCAL search_path TO regova, public;
-- Default solo de esta transaccion para las filas ficticias; ROLLBACK lo revierte.
ALTER TABLE regova.analisis ALTER COLUMN pasillo SET DEFAULT 'P-PRUEBA';
CREATE TEMP TABLE informe_pruebas (numero integer GENERATED ALWAYS AS IDENTITY, prueba text, resultado text) ON COMMIT DROP;

CREATE FUNCTION pg_temp.esperar_rechazo(nombre text, sentencia text, estado_esperado text, mensaje_esperado text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE estado_real text; mensaje_real text; rechazo boolean := false;
BEGIN
 BEGIN
  EXECUTE sentencia;
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS estado_real = RETURNED_SQLSTATE, mensaje_real = MESSAGE_TEXT;
  rechazo := true;
 END;
 IF NOT rechazo THEN
  RAISE EXCEPTION 'FALLO: % fue aceptada y debia rechazarse', nombre;
 END IF;
 IF estado_real <> estado_esperado OR
    (mensaje_esperado IS NOT NULL AND position(mensaje_esperado in mensaje_real)=0) THEN
  RAISE EXCEPTION 'FALLO en %: rechazo inesperado [%] %',nombre,estado_real,mensaje_real;
 END IF;
 INSERT INTO informe_pruebas(prueba,resultado) VALUES(nombre,'OK: rechazo esperado');
END $$;

DO $$
DECLARE
 l bigint; otro_local bigint; admin_id bigint; supervisor_id bigint; reponedor_id bigint; externo_id bigint;
 g bigint; otra_g bigint; cfg bigint; modelo bigint; foto bigint; a bigint; r bigint; alerta bigint;
 nueva_ejecucion bigint; nuevo_resultado bigint; caso record; marca text;
BEGIN
 IF current_database() <> 'REGOVA_BD' THEN
  RAISE EXCEPTION 'Abra este archivo conectado a REGOVA_BD. Conexion actual: %',current_database();
 END IF;
 IF (SELECT count(*) FROM information_schema.tables WHERE table_schema='regova' AND table_type='BASE TABLE' AND table_name<>'sesiones') <> 13 THEN
  RAISE EXCEPTION 'Se esperaban las 13 tablas del esquema regova';
 END IF;
 INSERT INTO informe_pruebas(prueba,resultado) VALUES('Esquema de 13 tablas presente','OK');
 marca := 'PRUEBA-' || txid_current()::text;
 INSERT INTO locales(codigo,nombre) VALUES(marca,'Local temporal de prueba') RETURNING id INTO l;
 INSERT INTO locales(codigo,nombre) VALUES(marca||'-OTRO','Segundo local temporal') RETURNING id INTO otro_local;
 INSERT INTO usuarios(local_id,codigo,nombre,password_hash,rol) VALUES(l,marca||'-ADM','Administrador de prueba','HASH_FICTICIO_NO_USAR','administrador') RETURNING id INTO admin_id;
 INSERT INTO usuarios(local_id,codigo,nombre,password_hash,rol) VALUES(l,marca||'-SUP','Supervisor de prueba','HASH_FICTICIO_NO_USAR','supervisor') RETURNING id INTO supervisor_id;
 INSERT INTO usuarios(local_id,codigo,nombre,password_hash,rol) VALUES(l,marca||'-REP','Reponedor de prueba','HASH_FICTICIO_NO_USAR','reponedor') RETURNING id INTO reponedor_id;
 INSERT INTO usuarios(local_id,codigo,nombre,password_hash,rol) VALUES(otro_local,marca||'-EXT','Usuario de otro local','HASH_FICTICIO_NO_USAR','supervisor') RETURNING id INTO externo_id;
 INSERT INTO gondolas(local_id,codigo,pasillo) VALUES(l,'G-PRUEBA','P-01') RETURNING id INTO g;
 INSERT INTO gondolas(local_id,codigo,pasillo) VALUES(otro_local,'G-PRUEBA','P-02') RETURNING id INTO otra_g;
 INSERT INTO configuraciones_analisis(local_id,version,umbral_critico,umbral_bajo,max_carga_mb,lado_minimo_px,creado_por)
 VALUES(l,1,30,70,10,200,admin_id) RETURNING id INTO cfg;
 INSERT INTO configuraciones_vigentes(local_id,configuracion_id) VALUES(l,cfg);
 INSERT INTO modelos_vision(nombre,version,metodo) VALUES(marca,'prueba','heuristic') RETURNING id INTO modelo;
 INSERT INTO imagenes(local_id,gondola_id,cargada_por,uri,nombre_original,mime,sha256,bytes,ancho_px,alto_px)
 VALUES(l,g,supervisor_id,'prueba/imagen_ficticia.jpg','prueba.jpg','image/jpeg',repeat('a',64),1000,800,600) RETURNING id INTO foto;
 INSERT INTO analisis(imagen_id,gondola_id,local_id,ejecutado_por,configuracion_id,modelo_id)
 VALUES(foto,g,l,supervisor_id,cfg,modelo) RETURNING id INTO a;
 INSERT INTO resultados(analisis_id,disponibilidad_pct,estado_operacional,area_evaluable_px)
 VALUES(a,25,'critica',1000) RETURNING id INTO r;
 UPDATE analisis SET estado='exitoso',iniciado_en=current_timestamp,finalizado_en=current_timestamp,duracion_ms=0 WHERE id=a;
 INSERT INTO archivos_analisis(analisis_id,tipo,uri,sha256,bytes) VALUES(a,'overlay','prueba/overlay_ficticio.jpg',repeat('b',64),1000);
 INSERT INTO revisiones(resultado_id,analisis_id,revisor_id,decision,comentario) VALUES(r,a,supervisor_id,'confirmado','Revision temporal');
 INSERT INTO alertas(resultado_id,analisis_id,motivo,responsable_id) VALUES(r,a,'Prueba de reposicion',reponedor_id) RETURNING id INTO alerta;
 UPDATE alertas SET estado='atendida',cerrada_por=reponedor_id,cerrada_en=current_timestamp WHERE id=alerta;
 INSERT INTO eventos_auditoria(actor_id,accion,entidad,entidad_id) VALUES(supervisor_id,'prueba.crear','analisis',a);
 INSERT INTO informe_pruebas(prueba,resultado) VALUES('Flujo valido: supervisor analiza, reponedor atiende alerta, auditoria y archivos referenciados','OK');

 -- Limites exactos y nueva ejecucion de la misma imagen, alternando autores validos.
 FOR caso IN SELECT * FROM (VALUES
  (0::numeric,'critica'::text),(30,'critica'),(30.01,'baja'),(69.99,'baja'),(70,'aceptable'),(100,'aceptable'),(NULL::numeric,'no_evaluable')
 ) AS casos(pct,clasificacion) LOOP
  INSERT INTO analisis(imagen_id,gondola_id,local_id,ejecutado_por,configuracion_id,modelo_id)
  VALUES(foto,g,l,admin_id,cfg,modelo) RETURNING id INTO nueva_ejecucion;
  INSERT INTO resultados(analisis_id,disponibilidad_pct,estado_operacional,area_evaluable_px)
  VALUES(nueva_ejecucion,caso.pct,caso.clasificacion,CASE WHEN caso.pct IS NULL THEN 0 ELSE 1000 END)
  RETURNING id INTO nuevo_resultado;
  UPDATE analisis SET estado='exitoso',iniciado_en=current_timestamp,finalizado_en=current_timestamp,duracion_ms=0 WHERE id=nueva_ejecucion;
  INSERT INTO informe_pruebas(prueba,resultado) VALUES('Clasificacion '||coalesce(caso.pct::text,'NULL')||' = '||caso.clasificacion,'OK');
 END LOOP;

 PERFORM pg_temp.esperar_rechazo('Codigo de gondola duplicado dentro del mismo local',
  format('INSERT INTO regova.gondolas(local_id,codigo,pasillo) VALUES(%s,%L,%L)',l,'G-PRUEBA','P-01'),'23505');
 PERFORM pg_temp.esperar_rechazo('Imagen atribuida a usuario de otro local',
  format('INSERT INTO regova.imagenes(local_id,gondola_id,cargada_por,uri,nombre_original,mime,sha256,bytes,ancho_px,alto_px) VALUES(%s,%s,%s,%L,%L,%L,%L,1000,800,600)',l,g,externo_id,'prueba/invalida.jpg','x.jpg','image/jpeg',repeat('a',64)),'23503');
 PERFORM pg_temp.esperar_rechazo('Analisis con ejecutor de otro local',
  format('INSERT INTO regova.analisis(imagen_id,gondola_id,local_id,ejecutado_por,configuracion_id,modelo_id) VALUES(%s,%s,%s,%s,%s,%s)',foto,g,l,externo_id,cfg,modelo),'23503');
 PERFORM pg_temp.esperar_rechazo('Analisis que mezcla imagen y otra gondola',
  format('INSERT INTO regova.analisis(imagen_id,gondola_id,local_id,ejecutado_por,configuracion_id,modelo_id) VALUES(%s,%s,%s,%s,%s,%s)',foto,otra_g,l,supervisor_id,cfg,modelo),'23503');
 PERFORM pg_temp.esperar_rechazo('Umbrales invertidos',
  format('INSERT INTO regova.configuraciones_analisis(local_id,version,umbral_critico,umbral_bajo,max_carga_mb,lado_minimo_px,creado_por) VALUES(%s,2,80,30,10,200,%s)',l,admin_id),'23514');
 PERFORM pg_temp.esperar_rechazo('Segundo resultado para la misma ejecucion',
  format('INSERT INTO regova.resultados(analisis_id,disponibilidad_pct,estado_operacional,area_evaluable_px) VALUES(%s,25,%L,1000)',a,'critica'),'23505');
 -- Una ejecucion adicional sin resultado para verificar rechazos de porcentaje y clasificacion.
 INSERT INTO analisis(imagen_id,gondola_id,local_id,ejecutado_por,configuracion_id,modelo_id)
 VALUES(foto,g,l,admin_id,cfg,modelo) RETURNING id INTO nueva_ejecucion;
 PERFORM pg_temp.esperar_rechazo('Porcentaje superior a 100',
  format('INSERT INTO regova.resultados(analisis_id,disponibilidad_pct,estado_operacional,area_evaluable_px) VALUES(%s,120,%L,1000)',nueva_ejecucion,'aceptable'),'23514');
 PERFORM pg_temp.esperar_rechazo('Clasificacion incompatible con los umbrales',
  format('INSERT INTO regova.resultados(analisis_id,disponibilidad_pct,estado_operacional,area_evaluable_px) VALUES(%s,25,%L,1000)',nueva_ejecucion,'aceptable'),'P0001','Clasificacion incompatible');
 PERFORM pg_temp.esperar_rechazo('Revision humana realizada por usuario de otro local',
  format('INSERT INTO regova.revisiones(resultado_id,analisis_id,revisor_id,decision) VALUES(%s,%s,%s,%L)',r,a,externo_id,'confirmado'),'P0001','El usuario debe pertenecer');
 PERFORM pg_temp.esperar_rechazo('Correccion humana sin datos de correccion',
  format('INSERT INTO regova.revisiones(resultado_id,analisis_id,revisor_id,decision) VALUES(%s,%s,%s,%L)',r,a,supervisor_id,'corregido'),'23514');
 PERFORM pg_temp.esperar_rechazo('Alerta atendida sin fecha ni usuario de cierre',
  format('INSERT INTO regova.alertas(resultado_id,analisis_id,motivo,estado) VALUES(%s,%s,%L,%L)',r,a,'Prueba invalida','atendida'),'23514');
 PERFORM pg_temp.esperar_rechazo('Responsable de alerta perteneciente a otro local',
  format('INSERT INTO regova.alertas(resultado_id,analisis_id,motivo,responsable_id) VALUES(%s,%s,%L,%s)',r,a,'Prueba invalida',externo_id),'P0001','El usuario debe pertenecer');
 PERFORM pg_temp.esperar_rechazo('Sobrescritura de configuracion historica',
  format('UPDATE regova.configuraciones_analisis SET umbral_bajo=75 WHERE id=%s',cfg),'P0001','conserva evidencia inmutable');
 PERFORM pg_temp.esperar_rechazo('Sobrescritura de resultado original',
  format('UPDATE regova.resultados SET disponibilidad_pct=80 WHERE id=%s',r),'P0001','conserva evidencia inmutable');
 PERFORM pg_temp.esperar_rechazo('Eliminacion de gondola con evidencia relacionada',
  format('DELETE FROM regova.gondolas WHERE id=%s',g),'23001');
 RAISE NOTICE 'PRUEBAS COMPLETADAS: % verificaciones correctas. Se descartaran los registros con ROLLBACK.',(SELECT count(*) FROM informe_pruebas);
END $$;

-- El resultado queda visible en Data Output antes de descartar las filas.
SELECT numero,prueba,resultado FROM informe_pruebas ORDER BY numero;
ROLLBACK;

-- IMPORTANTE: esto NO prueba el login ni que el endpoint rechace reponedores.
-- La restriccion por rol para ejecutar analisis aun debe implementarse en FastAPI.
-- Las referencias de imagen/modelo/overlay son ficticias: no prueba el detector
-- ni la lectura de archivos, que se verificaran al integrar el backend.

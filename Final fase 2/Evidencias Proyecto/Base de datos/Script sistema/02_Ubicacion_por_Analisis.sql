-- Ubicación por captura: local de sesión + pasillo + referencia opcional.
-- No borra tablas ni evidencia. Gondolas queda solo para compatibilidad histórica.
BEGIN;
SELECT pg_advisory_xact_lock(724613209);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='regova' AND table_name='analisis' AND column_name='origen') THEN
  RAISE EXCEPTION 'Esta base contiene la adaptación histórica opcional: revisar antes de cambiar ubicación.';
 END IF;
END $$;
ALTER TABLE regova.imagenes ALTER COLUMN gondola_id DROP NOT NULL;
ALTER TABLE regova.analisis ALTER COLUMN gondola_id DROP NOT NULL;
ALTER TABLE regova.analisis ADD COLUMN IF NOT EXISTS pasillo varchar(50);
-- Conservar la ubicación de capturas existentes, si las hubiera.
UPDATE regova.analisis a SET pasillo=g.pasillo FROM regova.gondolas g
 WHERE a.gondola_id=g.id AND a.pasillo IS NULL;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM regova.analisis WHERE pasillo IS NULL OR btrim(pasillo)='') THEN
  RAISE EXCEPTION 'Hay capturas antiguas sin pasillo identificable. Asignar su ubicación antes de continuar; no se inventó ninguna.';
 END IF;
END $$;
ALTER TABLE regova.analisis ALTER COLUMN pasillo SET NOT NULL;
ALTER TABLE regova.analisis DROP CONSTRAINT IF EXISTS analisis_pasillo_no_vacio;
ALTER TABLE regova.analisis ADD CONSTRAINT analisis_pasillo_no_vacio CHECK(btrim(pasillo)<>'');
-- La FK triple original ya no basta cuando gondola_id es NULL. Mantener el local.
CREATE UNIQUE INDEX IF NOT EXISTS imagen_id_local_uq ON regova.imagenes(id,local_id);
ALTER TABLE regova.analisis DROP CONSTRAINT IF EXISTS analisis_imagen_local_fk;
ALTER TABLE regova.analisis ADD CONSTRAINT analisis_imagen_local_fk
 FOREIGN KEY(imagen_id,local_id) REFERENCES regova.imagenes(id,local_id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS analisis_local_pasillo_fecha_idx
 ON regova.analisis(local_id,pasillo,creado_en DESC,id DESC) WHERE eliminado_en IS NULL;
COMMENT ON COLUMN regova.analisis.pasillo IS 'Ubicación declarada en cada captura; no requiere catálogo ni alta previa.';
COMMENT ON TABLE regova.gondolas IS 'Compatibilidad con el diseño anterior. El flujo actual no exige ni registra góndolas.';
COMMIT;

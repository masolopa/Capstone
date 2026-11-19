-- REGOVA: analisis por pasillo, sin catalogo obligatorio de gondolas.
-- Tabla gondolas y enlaces opcionales: compatibilidad con el diseño previo.
-- REGOVA: propuesta de esquema inicial para PostgreSQL 15 o superior.
-- Ejecutar UNA VEZ en una base de desarrollo nueva. No migra SQLite.
-- No elimina ni reemplaza tablas existentes. Un conflicto revierte la transaccion.
BEGIN;
CREATE SCHEMA regova;
SET LOCAL search_path TO regova, public;

CREATE TABLE locales (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 codigo varchar(50) NOT NULL UNIQUE CHECK (btrim(codigo) <> ''),
 nombre varchar(150) NOT NULL CHECK (btrim(nombre) <> ''),
 direccion text,
 activo boolean NOT NULL DEFAULT true,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);

-- Un usuario tiene un rol operativo y un local. No se modelan aun administradores
-- globales/regionales. El administrador protegido es una regla de la aplicacion.
CREATE TABLE usuarios (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 local_id bigint NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
 codigo varchar(50) NOT NULL UNIQUE,
 nombre varchar(150) NOT NULL CHECK (btrim(nombre) <> ''),
 email varchar(254),
 password_hash text NOT NULL CHECK (btrim(password_hash) <> ''),
 rol varchar(20) NOT NULL CHECK (rol IN ('administrador','supervisor','reponedor')),
 activo boolean NOT NULL DEFAULT true,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 eliminado_en timestamptz,
 UNIQUE (id,local_id),
 CHECK (eliminado_en IS NULL OR NOT activo)
);
CREATE UNIQUE INDEX usuarios_email_uq ON usuarios(lower(email)) WHERE email IS NOT NULL;
CREATE INDEX usuarios_local_idx ON usuarios(local_id);

CREATE TABLE gondolas (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 local_id bigint NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
 codigo varchar(50) NOT NULL CHECK (btrim(codigo) <> ''),
 pasillo varchar(50) NOT NULL,
 descripcion text,
 activo boolean NOT NULL DEFAULT true,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 UNIQUE(local_id,codigo), UNIQUE(id,local_id)
);
-- Version completa de umbrales: evita intervalos solapados y conserva el pasado.
-- Critica: disponibilidad <= critico; baja: > critico y < bajo;
-- aceptable: >= bajo. No evaluable es una condicion distinta, sin porcentaje.
CREATE TABLE configuraciones_analisis (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 local_id bigint NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
 version integer NOT NULL CHECK(version > 0),
 umbral_critico numeric(5,2) NOT NULL CHECK(umbral_critico > 0),
 umbral_bajo numeric(5,2) NOT NULL CHECK(umbral_bajo <= 100),
 max_carga_mb numeric(6,2) NOT NULL CHECK(max_carga_mb > 0 AND max_carga_mb <= 50),
 lado_minimo_px integer NOT NULL CHECK(lado_minimo_px >= 50),
 creado_por bigint NOT NULL,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 CHECK(umbral_critico < umbral_bajo),
 FOREIGN KEY(creado_por,local_id) REFERENCES usuarios(id,local_id) ON DELETE RESTRICT,
 UNIQUE(local_id,version), UNIQUE(id,local_id)
);
-- Puntero a la configuracion vigente; cambiarlo no modifica las versiones previas.
CREATE TABLE configuraciones_vigentes (
 local_id bigint PRIMARY KEY REFERENCES locales(id) ON DELETE RESTRICT,
 configuracion_id bigint NOT NULL,
 FOREIGN KEY(configuracion_id,local_id) REFERENCES configuraciones_analisis(id,local_id) ON DELETE RESTRICT
);
CREATE INDEX configuraciones_autor_idx ON configuraciones_analisis(creado_por,local_id);

CREATE TABLE modelos_vision (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 nombre varchar(100) NOT NULL,
 version varchar(60) NOT NULL,
 metodo varchar(20) NOT NULL CHECK(metodo IN ('heuristic','yolo')),
 artefacto_uri text,
 sha256 varchar(64) CHECK(sha256 ~ '^[0-9a-f]{64}$'),
 metricas jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(metricas)='object'),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 UNIQUE(nombre,version),
 CHECK(metodo <> 'yolo' OR (artefacto_uri IS NOT NULL AND sha256 IS NOT NULL))
);

-- Archivo original inmutable en carpetas locales administradas por FastAPI.
-- uri es una clave relativa a REGOVA_STORAGE_ROOT; nunca una ruta del usuario.
-- La misma imagen puede analizarse varias veces sin duplicar el archivo.
CREATE TABLE imagenes (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 local_id bigint NOT NULL,
 gondola_id bigint,
 cargada_por bigint NOT NULL,
 uri text NOT NULL CHECK(btrim(uri) <> ''),
 nombre_original text NOT NULL,
 mime varchar(30) NOT NULL CHECK(mime IN ('image/jpeg','image/png','image/webp')),
 sha256 varchar(64) NOT NULL CHECK(sha256 ~ '^[0-9a-f]{64}$'),
 bytes bigint NOT NULL CHECK(bytes > 0),
 ancho_px integer NOT NULL CHECK(ancho_px > 0),
 alto_px integer NOT NULL CHECK(alto_px > 0),
 capturada_en timestamptz,
 cargada_en timestamptz NOT NULL DEFAULT current_timestamp,
 FOREIGN KEY(gondola_id,local_id) REFERENCES gondolas(id,local_id) ON DELETE RESTRICT,
 FOREIGN KEY(cargada_por,local_id) REFERENCES usuarios(id,local_id) ON DELETE RESTRICT,
 UNIQUE(id,gondola_id,local_id), CONSTRAINT imagen_id_local_uq UNIQUE(id,local_id)
);
CREATE INDEX imagenes_gondola_fecha_idx ON imagenes(gondola_id,cargada_en DESC,id DESC);
CREATE INDEX imagenes_autor_idx ON imagenes(cargada_por,local_id);
CREATE INDEX imagenes_hash_idx ON imagenes(sha256);

CREATE TABLE analisis (
 pasillo varchar(50) NOT NULL CHECK(btrim(pasillo)<>''),
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 imagen_id bigint NOT NULL,
 gondola_id bigint,
 local_id bigint NOT NULL,
 ejecutado_por bigint NOT NULL,
 configuracion_id bigint NOT NULL,
 modelo_id bigint NOT NULL REFERENCES modelos_vision(id) ON DELETE RESTRICT,
 estado varchar(20) NOT NULL DEFAULT 'pendiente'
   CHECK(estado IN ('pendiente','procesando','exitoso','fallido')),
 referencia varchar(100) NOT NULL DEFAULT '',
 observaciones varchar(500) NOT NULL DEFAULT '',
 -- Incluye ROI, exclusiones y estructura como poligonos de esta ejecucion.
 parametros jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(parametros)='object'),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 iniciado_en timestamptz,
 finalizado_en timestamptz,
 duracion_ms bigint CHECK(duracion_ms >= 0),
 error_detalle text,
 eliminado_en timestamptz,
 FOREIGN KEY(imagen_id,local_id) REFERENCES imagenes(id,local_id) ON DELETE RESTRICT,
 FOREIGN KEY(imagen_id,gondola_id,local_id) REFERENCES imagenes(id,gondola_id,local_id) ON DELETE RESTRICT,
 FOREIGN KEY(ejecutado_por,local_id) REFERENCES usuarios(id,local_id) ON DELETE RESTRICT,
 FOREIGN KEY(configuracion_id,local_id) REFERENCES configuraciones_analisis(id,local_id) ON DELETE RESTRICT,
 UNIQUE(id,gondola_id),
 CHECK(finalizado_en IS NULL OR (iniciado_en IS NOT NULL AND finalizado_en >= iniciado_en)),
 CHECK(estado NOT IN ('exitoso','fallido') OR finalizado_en IS NOT NULL),
 CHECK(estado <> 'fallido' OR error_detalle IS NOT NULL)
);
CREATE INDEX analisis_local_fecha_idx ON analisis(local_id,creado_en DESC,id DESC) WHERE eliminado_en IS NULL;
CREATE INDEX analisis_gondola_fecha_idx ON analisis(gondola_id,creado_en DESC,id DESC);
CREATE INDEX analisis_local_pasillo_fecha_idx ON analisis(local_id,pasillo,creado_en DESC,id DESC) WHERE eliminado_en IS NULL;
CREATE INDEX analisis_imagen_idx ON analisis(imagen_id,gondola_id,local_id);
CREATE INDEX analisis_autor_idx ON analisis(ejecutado_por,local_id);
CREATE INDEX analisis_configuracion_idx ON analisis(configuracion_id,local_id);
CREATE INDEX analisis_modelo_idx ON analisis(modelo_id);

-- Un resultado global por ejecucion. Filas y detecciones quedan en detalle JSONB.
CREATE TABLE resultados (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 analisis_id bigint NOT NULL UNIQUE REFERENCES analisis(id) ON DELETE RESTRICT,
 disponibilidad_pct numeric(5,2) CHECK(disponibilidad_pct BETWEEN 0 AND 100),
 estado_operacional varchar(20) NOT NULL CHECK(estado_operacional IN ('aceptable','baja','critica','no_evaluable')),
 requiere_revision boolean NOT NULL DEFAULT false,
 area_evaluable_px bigint NOT NULL CHECK(area_evaluable_px >= 0),
 detalle jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(detalle)='object'),
 UNIQUE(id,analisis_id),
 CHECK((estado_operacional='no_evaluable' AND disponibilidad_pct IS NULL) OR
       (estado_operacional<>'no_evaluable' AND disponibilidad_pct IS NOT NULL AND area_evaluable_px>0))
);
CREATE TABLE archivos_analisis (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 analisis_id bigint NOT NULL REFERENCES analisis(id) ON DELETE RESTRICT,
 tipo varchar(20) NOT NULL CHECK(tipo IN ('overlay','reporte_pdf','mascara')),
 uri text NOT NULL CHECK(btrim(uri) <> ''),
 sha256 varchar(64) NOT NULL CHECK(sha256 ~ '^[0-9a-f]{64}$'),
 bytes bigint NOT NULL CHECK(bytes>0),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);
CREATE INDEX archivos_analisis_idx ON archivos_analisis(analisis_id,tipo);

-- Correcciones humanas separadas de la prediccion original; base para futuros datasets.
CREATE TABLE revisiones (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 resultado_id bigint NOT NULL,
 analisis_id bigint NOT NULL,
 revisor_id bigint NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
 decision varchar(20) NOT NULL CHECK(decision IN ('confirmado','corregido','descartado')),
 correccion jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(correccion)='object'),
 comentario text,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 FOREIGN KEY(resultado_id,analisis_id) REFERENCES resultados(id,analisis_id) ON DELETE RESTRICT,
 CHECK(decision <> 'corregido' OR correccion <> '{}'::jsonb)
);
CREATE INDEX revisiones_resultado_idx ON revisiones(resultado_id,analisis_id,creado_en DESC);
CREATE INDEX revisiones_revisor_idx ON revisiones(revisor_id);

CREATE TABLE alertas (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 resultado_id bigint NOT NULL,
 analisis_id bigint NOT NULL,
 motivo text NOT NULL,
 estado varchar(20) NOT NULL DEFAULT 'pendiente' CHECK(estado IN ('pendiente','en_atencion','atendida','descartada')),
 responsable_id bigint REFERENCES usuarios(id) ON DELETE RESTRICT,
 cerrada_por bigint REFERENCES usuarios(id) ON DELETE RESTRICT,
 creada_en timestamptz NOT NULL DEFAULT current_timestamp,
 cerrada_en timestamptz,
 FOREIGN KEY(resultado_id,analisis_id) REFERENCES resultados(id,analisis_id) ON DELETE RESTRICT,
 CHECK((estado IN ('atendida','descartada') AND cerrada_en IS NOT NULL AND cerrada_por IS NOT NULL)
    OR (estado IN ('pendiente','en_atencion') AND cerrada_en IS NULL AND cerrada_por IS NULL)),
 CHECK(cerrada_en IS NULL OR cerrada_en>=creada_en)
);
CREATE INDEX alertas_resultado_idx ON alertas(resultado_id,analisis_id);
CREATE INDEX alertas_pendientes_idx ON alertas(creada_en,id) WHERE estado IN ('pendiente','en_atencion');
CREATE INDEX alertas_responsable_idx ON alertas(responsable_id,estado);
CREATE INDEX alertas_cierre_idx ON alertas(cerrada_por);

CREATE TABLE eventos_auditoria (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 actor_id bigint REFERENCES usuarios(id) ON DELETE RESTRICT,
 accion varchar(60) NOT NULL,
 entidad varchar(60) NOT NULL,
 entidad_id bigint NOT NULL,
 detalle jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(detalle)='object'),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);
CREATE INDEX auditoria_entidad_idx ON eventos_auditoria(entidad,entidad_id,creado_en DESC);
CREATE INDEX auditoria_actor_idx ON eventos_auditoria(actor_id,creado_en DESC);

-- Las versiones usadas como evidencia no se sobrescriben: crear otra version.
CREATE FUNCTION impedir_modificacion() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 RAISE EXCEPTION 'La tabla % conserva evidencia inmutable; inserte una nueva version', TG_TABLE_NAME;
END $$;
CREATE TRIGGER configuracion_inmutable BEFORE UPDATE OR DELETE ON configuraciones_analisis FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();
CREATE TRIGGER modelo_inmutable BEFORE UPDATE OR DELETE ON modelos_vision FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();
CREATE TRIGGER imagen_inmutable BEFORE UPDATE OR DELETE ON imagenes FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();
CREATE TRIGGER resultado_inmutable BEFORE UPDATE OR DELETE ON resultados FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();
CREATE TRIGGER revision_inmutable BEFORE UPDATE OR DELETE ON revisiones FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();
CREATE TRIGGER auditoria_inmutable BEFORE UPDATE OR DELETE ON eventos_auditoria FOR EACH ROW EXECUTE FUNCTION impedir_modificacion();

-- Comprueba clasificacion con los umbrales historicos de la ejecucion.
CREATE FUNCTION validar_resultado() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE crit numeric; bajo numeric; esperado text;
BEGIN
 SELECT c.umbral_critico,c.umbral_bajo INTO crit,bajo
 FROM regova.analisis a JOIN regova.configuraciones_analisis c ON c.id=a.configuracion_id
 WHERE a.id=NEW.analisis_id;
 esperado := CASE WHEN NEW.disponibilidad_pct IS NULL THEN 'no_evaluable'
  WHEN NEW.disponibilidad_pct<=crit THEN 'critica'
  WHEN NEW.disponibilidad_pct<bajo THEN 'baja' ELSE 'aceptable' END;
 IF NEW.estado_operacional<>esperado THEN RAISE EXCEPTION 'Clasificacion incompatible con los umbrales del analisis'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER resultado_validar BEFORE INSERT ON resultados FOR EACH ROW EXECUTE FUNCTION validar_resultado();

-- Integridad territorial adicional. La autorizacion por rol corresponde al backend.
CREATE FUNCTION validar_actores() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE local_analisis bigint; actor bigint; actores bigint[];
BEGIN
 SELECT local_id INTO local_analisis FROM regova.analisis WHERE id=NEW.analisis_id;
 IF TG_TABLE_NAME='revisiones' THEN actores:=ARRAY[NEW.revisor_id];
 ELSE actores:=ARRAY[NEW.responsable_id,NEW.cerrada_por]; END IF;
 FOREACH actor IN ARRAY actores LOOP
  IF actor IS NOT NULL AND NOT EXISTS(SELECT 1 FROM regova.usuarios WHERE id=actor AND local_id=local_analisis)
  THEN RAISE EXCEPTION 'El usuario debe pertenecer al local del analisis'; END IF;
 END LOOP;
 RETURN NEW;
END $$;
CREATE TRIGGER revision_actores BEFORE INSERT ON revisiones FOR EACH ROW EXECUTE FUNCTION validar_actores();
CREATE TRIGGER alerta_actores BEFORE INSERT OR UPDATE ON alertas FOR EACH ROW EXECUTE FUNCTION validar_actores();

COMMENT ON COLUMN imagenes.uri IS 'Clave relativa a REGOVA_STORAGE_ROOT. El backend resuelve y valida la ruta dentro de esa raiz.';
COMMENT ON COLUMN modelos_vision.artefacto_uri IS 'Clave relativa del modelo dentro del almacenamiento local administrado.';
COMMENT ON COLUMN archivos_analisis.uri IS 'Clave relativa del archivo generado; no almacenar enlaces temporales ni rutas personales.';
COMMENT ON SCHEMA regova IS 'Propuesta REGOVA: operacion, evidencia de analisis y revisiones humanas';
COMMENT ON COLUMN resultados.detalle IS 'Detalle variable de vision: filas, cajas, areas, calidad, advertencias. No reemplaza campos consultados habitualmente.';
COMMENT ON COLUMN eventos_auditoria.detalle IS 'No registrar contrasenas, hashes de contrasena ni tokens. La aplicacion inserta estos eventos en la misma transaccion que la operacion.';
COMMIT;

-- Ejecutar UNA VEZ sobre REGOVA_BD, luego de crear el esquema inicial.
-- No importa datos antiguos ni modifica regova_legacy.
BEGIN;
CREATE TABLE IF NOT EXISTS regova.sesiones (
 token_hash varchar(64) PRIMARY KEY CHECK(token_hash ~ '^[0-9a-f]{64}$'),
 usuario_id bigint NOT NULL REFERENCES regova.usuarios(id) ON DELETE RESTRICT,
 creada_en timestamptz NOT NULL DEFAULT current_timestamp,
 expira_en timestamptz NOT NULL,
 CHECK(expira_en > creada_en)
);
CREATE INDEX IF NOT EXISTS sesiones_usuario_idx ON regova.sesiones(usuario_id);
CREATE INDEX IF NOT EXISTS sesiones_expiracion_idx ON regova.sesiones(expira_en);
COMMIT;

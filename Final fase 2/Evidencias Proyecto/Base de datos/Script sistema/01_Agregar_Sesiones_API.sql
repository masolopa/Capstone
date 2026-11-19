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

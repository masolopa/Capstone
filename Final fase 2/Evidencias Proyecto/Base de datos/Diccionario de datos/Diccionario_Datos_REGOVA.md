# Diccionario de datos REGOVA — ubicación por análisis

Versión vigente: ID de análisis + local de sesión + pasillo obligatorio + referencia opcional. No requiere registrar góndolas. Incluye sesiones y conserva la tabla de góndolas solo por compatibilidad.

Local.estado, Usuario.estado y Góndola.estado significan activo/inactivo; no son divisiones territoriales. Las FK representan las relaciones del MER. NULL significa ausencia de dato. Las fechas se presentan en America/Santiago.

## Local — `locales`

Identifica el establecimiento al que pertenecen las góndolas y los usuarios.

**Justificación:** Separar locales permite ampliar el prototipo sin cambiar la identidad de las góndolas.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_local | bigint | No | Automático | Identificador interno único del registro. | 1 |
| codigo | codigo | varchar(50) | No | — | Código legible de identificación; no sustituye la clave interna. | G-023 |
| nombre | nombre | varchar(150) | No | — | Nombre legible para identificar el registro. | Local piloto Maipú |
| direccion | direccion | text | Sí | — | Dirección del establecimiento en Chile; puede incluir comuna, ciudad y región en texto. No se normalizan divisiones territoriales en esta etapa. | Maipú, Región Metropolitana, Chile |
| activo | estado | boolean | No | true | Estado operativo: true significa activo; false, inactivo. No es una división geográfica. | true |
| creado_en | creado_en | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**


**Definición PostgreSQL:**

```sql
CREATE TABLE regova.locales (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 codigo varchar(50) NOT NULL UNIQUE CHECK (btrim(codigo) <> ''),
 nombre varchar(150) NOT NULL CHECK (btrim(nombre) <> ''),
 direccion text,
 activo boolean NOT NULL DEFAULT true,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);
```

## Usuario — `usuarios`

Identifica a las personas que operan REGOVA y su rol.

**Justificación:** Permite autoría, asignación de responsabilidades y baja sin perder historial.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_usuario | bigint | No | Automático | Identificador interno único del registro. | 1 |
| local_id | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| codigo | codigo_acceso | varchar(50) | No | — | Identificador de acceso del usuario, único en todo el sistema. | USR-018 |
| nombre | nombre | varchar(150) | No | — | Nombre de la persona que opera el sistema. | Usuario de ejemplo |
| email | correo | varchar(254) | Sí | — | Correo opcional; único sin distinguir mayúsculas cuando se informa. | usuario@example.com |
| password_hash | password_hash | text | No | — | Hash seguro de contraseña generado por el backend. Nunca la contraseña en texto plano. | Hash generado por una biblioteca de autenticación |
| rol | rol | varchar(20) | No | — | Función operativa asignada a la cuenta. | supervisor |
| activo | estado | boolean | No | true | Estado operativo: true significa activo; false, inactivo. No es una división geográfica. | true |
| creado_en | fecha_creacion | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |
| eliminado_en | eliminado_en | timestamptz | Sí | — | Fecha y hora de baja lógica; NULL indica que no se ha dado de baja. | NULL |

**Relaciones:**

- `(local_id)` → `locales(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.usuarios (
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
```

## Góndola (compatibilidad histórica) — `gondolas`

Tabla conservada del diseño anterior, sin uso obligatorio en la operación actual.

**Justificación:** No se crean góndolas desde la interfaz ni se requiere esta relación para analizar; se conserva para no destruir datos existentes.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_gondola | bigint | No | Automático | Identificador interno único del registro. | 1 |
| local_id | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| codigo | codigo | varchar(50) | No | — | Código legible de identificación; no sustituye la clave interna. | G-023 |
| pasillo | pasillo | varchar(50) | No | — | Identificador o descripción del pasillo donde se ubica la góndola. | P-04 |
| descripcion | descripcion | text | Sí | — | Descripción opcional que ayuda a reconocer la góndola. | Góndola de abarrotes |
| activo | estado | boolean | No | true | Estado operativo: true significa activo; false, inactivo. No es una división geográfica. | true |
| creado_en | creado_en | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(local_id)` → `locales(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.gondolas (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 local_id bigint NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
 codigo varchar(50) NOT NULL CHECK (btrim(codigo) <> ''),
 pasillo varchar(50) NOT NULL,
 descripcion text,
 activo boolean NOT NULL DEFAULT true,
 creado_en timestamptz NOT NULL DEFAULT current_timestamp,
 UNIQUE(local_id,codigo), UNIQUE(id,local_id)
);
```

## Configuración de análisis — `configuraciones_analisis`

Conserva una versión de umbrales y requisitos de entrada.

**Justificación:** Versionar evita reclasificar silenciosamente resultados históricos.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_configuracion | bigint | No | Automático | Identificador interno único del registro. | 1 |
| local_id | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| version | version | integer | No | — | Número positivo de versión de configuración, único dentro de su local. | 1 |
| umbral_critico | umbral_critico | numeric(5,2) | No | — | Límite superior incluido de la disponibilidad clasificada como crítica. | 30.00 |
| umbral_bajo | umbral_bajo | numeric(5,2) | No | — | Límite desde el que la disponibilidad pasa a aceptable; entre ambos límites se clasifica baja. | 70.00 |
| max_carga_mb | max_carga_mb | numeric(6,2) | No | — | Límite de carga expresado en unidades de 1024 × 1024 bytes, para mantener el comportamiento del backend actual. | 10.00 |
| lado_minimo_px | lado_minimo_px | integer | No | — | Dimensión mínima permitida del lado más corto de una imagen, en píxeles. | 200 |
| creado_por | Relación: creado_por | bigint | No | — | Usuario que registró la versión de configuración; debe pertenecer al mismo local. | 18 |
| creado_en | fecha_creacion | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(local_id)` → `locales(id)` (eliminación restringida).
- `(creado_por,local_id)` → `usuarios(id,local_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.configuraciones_analisis (
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
```

## Selección de configuración vigente — `configuraciones_vigentes`

Relaciona un local con su configuración actual.

**Justificación:** Es una relación auxiliar del modelo lógico, no una nueva entidad del negocio.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| local_id (PK) | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| configuracion_id | Relación: configuracion_id | bigint | No | — | Identificador de la versión de configuración utilizada o seleccionada. | 3 |

**Relaciones:**

- `(local_id)` → `locales(id)` (eliminación restringida).
- `(configuracion_id,local_id)` → `configuraciones_analisis(id,local_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.configuraciones_vigentes (
 local_id bigint PRIMARY KEY REFERENCES locales(id) ON DELETE RESTRICT,
 configuracion_id bigint NOT NULL,
 FOREIGN KEY(configuracion_id,local_id) REFERENCES configuraciones_analisis(id,local_id) ON DELETE RESTRICT
);
```

## Versión de modelo — `modelos_vision`

Identifica la versión del detector utilizada en una ejecución.

**Justificación:** Permite comparar ejecuciones y rastrear los pesos que produjeron un resultado.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_modelo | bigint | No | Automático | Identificador interno único del registro. | 1 |
| nombre | nombre | varchar(100) | No | — | Nombre de la familia del detector. | Detector de góndolas |
| version | version | varchar(60) | No | — | Etiqueta de versión del modelo, única en combinación con su nombre. | v1 |
| metodo | metodo | varchar(20) | No | — | Método de procesamiento registrado para esta versión. | yolo |
| artefacto_uri | referencia_pesos | text | Sí | — | Clave relativa de los pesos del modelo; puede ser NULL para el método heurístico. | modelos/detector/v1/pesos.pt |
| sha256 | hash | varchar(64) | Sí | — | Huella SHA-256 del contenido del archivo; permite verificar su integridad. | 64 caracteres hexadecimales en minúscula |
| metricas | metricas | jsonb | No | '{}'::jsonb | Objeto JSON con métricas de evaluación del modelo, no resultados de una captura operacional. | {} |
| creado_en | fecha_registro | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**


**Definición PostgreSQL:**

```sql
CREATE TABLE regova.modelos_vision (
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
```

## Imagen — `imagenes`

Fotografía original cargada por un usuario de un local.

**Justificación:** Conservar el archivo y su contexto; el pasillo declarado pertenece al análisis.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_imagen | bigint | No | Automático | Identificador interno único del registro. | 1 |
| local_id | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| gondola_id | Relación: gondola_id | bigint | Sí | — | Relación opcional de compatibilidad con el diseño anterior. El flujo actual la deja NULL; no identifica el análisis ni sustituye al pasillo. | NULL |
| cargada_por | Relación: cargada_por | bigint | No | — | Usuario que cargó la imagen; puede ser distinto del ejecutor del análisis. | 18 |
| uri | referencia_archivo | text | No | — | Clave relativa del archivo dentro de la raíz de almacenamiento administrada por FastAPI. | originales/2026/11/8f32.jpg |
| nombre_original | nombre_original | text | No | — | Nombre original del archivo recibido; se conserva como metadato, no se usa directamente para construir rutas. | gondola_023.jpg |
| mime | formato | varchar(30) | No | — | Tipo de contenido admitido de la imagen. | image/jpeg |
| sha256 | hash | varchar(64) | No | — | Huella SHA-256 del contenido del archivo; permite verificar su integridad. | 64 caracteres hexadecimales en minúscula |
| bytes | tamano_bytes | bigint | No | — | Tamaño del archivo en bytes. | 2400000 |
| ancho_px | ancho_px | integer | No | — | Ancho de la fotografía original en píxeles. | 1920 |
| alto_px | alto_px | integer | No | — | Alto de la fotografía original en píxeles. | 1080 |
| capturada_en | fecha_captura | timestamptz | Sí | — | Fecha y hora de captura si se conoce; distinta de la fecha de carga. | 2026-11-14T15:20:00-03:00 |
| cargada_en | fecha_carga | timestamptz | No | current_timestamp | Fecha y hora en que se registró la carga. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(gondola_id,local_id)` → `gondolas(id,local_id)` (eliminación restringida).
- `(cargada_por,local_id)` → `usuarios(id,local_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.imagenes (
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
```

## Análisis — `analisis`

Ejecución identificada por ID, usuario y local de sesión, pasillo obligatorio y referencia opcional.

**Justificación:** La ubicación se registra al cargar cada foto, sin alta previa de mobiliario.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| pasillo | pasillo | varchar(50) | No | — | Pasillo declarado para esta captura. Obligatorio, hasta 50 caracteres y no vacío; no requiere un catálogo previo. | P-04 |
| id (PK) | id_analisis | bigint | No | Automático | Identificador interno único del registro. | 1 |
| imagen_id | Relación: imagen_id | bigint | No | — | Identificador de la imagen original procesada. | 1542 |
| gondola_id | Relación: gondola_id | bigint | Sí | — | Relación opcional de compatibilidad con el diseño anterior. El flujo actual la deja NULL; no identifica el análisis ni sustituye al pasillo. | NULL |
| local_id | Relación: local_id | bigint | No | — | Identificador del local al que pertenece el registro. | 1 |
| ejecutado_por | Relación: ejecutado_por | bigint | No | — | Usuario que solicitó la ejecución del procesamiento. | 18 |
| configuracion_id | Relación: configuracion_id | bigint | No | — | Identificador de la versión de configuración utilizada o seleccionada. | 3 |
| modelo_id | Relación: modelo_id | bigint | No | — | Identificador de la versión del detector utilizada. | 2 |
| estado | estado_procesamiento | varchar(20) | No | 'pendiente' | Estado técnico del procesamiento, independiente de la disponibilidad detectada. | pendiente |
| referencia | referencia | varchar(100) | No | '' | Referencia operacional libre para facilitar la búsqueda del análisis. | Control de apertura G-023 |
| observaciones | observaciones | varchar(500) | No | '' | Notas ingresadas sobre la captura o ejecución. | Fotografía tomada antes de la reposición |
| parametros | parametros | jsonb | No | '{}'::jsonb | Objeto JSON con entradas específicas de la ejecución, como ROI, exclusiones y filas solicitadas. Las zonas no son regiones físicas administradas. | {"filas":4} |
| creado_en | fecha_creacion | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |
| iniciado_en | fecha_inicio | timestamptz | Sí | — | Fecha y hora de inicio del procesamiento. | 2026-11-14T15:31:00-03:00 |
| finalizado_en | fecha_fin | timestamptz | Sí | — | Fecha y hora de finalización de la ejecución, exitosa o fallida. | 2026-11-14T15:31:12-03:00 |
| duracion_ms | duracion | bigint | Sí | — | Duración medida del procesamiento en milisegundos; no en segundos. | 12000 |
| error_detalle | detalle_error | text | Sí | — | Descripción del fallo técnico cuando la ejecución falla. | Detector no disponible |
| eliminado_en | eliminado_en | timestamptz | Sí | — | Fecha y hora de baja lógica; NULL indica que no se ha dado de baja. | NULL |

**Relaciones:**

- `(modelo_id)` → `modelos_vision(id)` (eliminación restringida).
- `(imagen_id,local_id)` → `imagenes(id,local_id)` (eliminación restringida).
- `(imagen_id,gondola_id,local_id)` → `imagenes(id,gondola_id,local_id)` (eliminación restringida).
- `(ejecutado_por,local_id)` → `usuarios(id,local_id)` (eliminación restringida).
- `(configuracion_id,local_id)` → `configuraciones_analisis(id,local_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.analisis (
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
```

## Resultado de análisis — `resultados`

Conserva la predicción global de una ejecución.

**Justificación:** La predicción original se mantiene separada de las correcciones humanas.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_resultado | bigint | No | Automático | Identificador interno único del registro. | 1 |
| analisis_id | Relación: analisis_id | bigint | No | — | Identificador de la ejecución de análisis relacionada. | 2010 |
| disponibilidad_pct | disponibilidad_pct | numeric(5,2) | Sí | — | Porcentaje estimado de disponibilidad global; NULL si la imagen no es evaluable. | 65.20 |
| estado_operacional | clasificacion | varchar(20) | No | — | Clasificación de disponibilidad calculada con los umbrales históricos de la ejecución. | baja |
| requiere_revision | requiere_revision | boolean | No | false | Indica que el resultado necesita revisión humana; puede coexistir con cualquier clasificación. | true |
| area_evaluable_px | area_evaluable | bigint | No | — | Cantidad de píxeles del área evaluable en el espacio de imagen utilizado por el algoritmo. El detalle debe conservar dimensiones y transformaciones. | 500000 |
| detalle | detalle_vision | jsonb | No | '{}'::jsonb | Objeto JSON para filas, detecciones, calidad, áreas y advertencias; no reemplaza atributos consultados habitualmente. | {"advertencias":[]} |

**Relaciones:**

- `(analisis_id)` → `analisis(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.resultados (
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
```

## Archivo de análisis — `archivos_analisis`

Referencia archivos generados y archivados de una ejecución.

**Justificación:** Evita almacenar archivos pesados como base64 dentro de los resultados.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_archivo | bigint | No | Automático | Identificador interno único del registro. | 1 |
| analisis_id | Relación: analisis_id | bigint | No | — | Identificador de la ejecución de análisis relacionada. | 2010 |
| tipo | tipo | varchar(20) | No | — | Clase de archivo generado y archivado. | overlay |
| uri | referencia_archivo | text | No | — | Clave relativa del archivo dentro de la raíz de almacenamiento administrada por FastAPI. | originales/2026/11/8f32.jpg |
| sha256 | hash | varchar(64) | No | — | Huella SHA-256 del contenido del archivo; permite verificar su integridad. | 64 caracteres hexadecimales en minúscula |
| bytes | tamano_bytes | bigint | No | — | Tamaño del archivo en bytes. | 2400000 |
| creado_en | fecha_creacion | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(analisis_id)` → `analisis(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.archivos_analisis (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 analisis_id bigint NOT NULL REFERENCES analisis(id) ON DELETE RESTRICT,
 tipo varchar(20) NOT NULL CHECK(tipo IN ('overlay','reporte_pdf','mascara')),
 uri text NOT NULL CHECK(btrim(uri) <> ''),
 sha256 varchar(64) NOT NULL CHECK(sha256 ~ '^[0-9a-f]{64}$'),
 bytes bigint NOT NULL CHECK(bytes>0),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);
```

## Revisión de resultado — `revisiones`

Conserva la evaluación humana de una predicción.

**Justificación:** Mantiene trazabilidad y permite preparar futuras anotaciones validadas.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_revision | bigint | No | Automático | Identificador interno único del registro. | 1 |
| resultado_id | Relación: resultado_id | bigint | No | — | Identificador del resultado original relacionado. | 2010 |
| analisis_id | Relación: analisis_id | bigint | No | — | Identificador de la ejecución de análisis relacionada. | 2010 |
| revisor_id | Relación: revisor_id | bigint | No | — | Usuario que revisó la predicción; debe pertenecer al local del análisis. | 18 |
| decision | decision | varchar(20) | No | — | Indica si la predicción se confirmó, corrigió o descartó. | corregido |
| correccion | correccion | jsonb | No | '{}'::jsonb | Objeto JSON con la corrección propuesta; obligatorio no vacío cuando la decisión es corregido. El contrato detallado lo valida el backend. | {"disponibilidad_pct":72.00} |
| comentario | comentario | text | Sí | — | Justificación o comentario opcional de la revisión humana. | Se corrigió una detección sobre una etiqueta |
| creado_en | fecha_revision | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(revisor_id)` → `usuarios(id)` (eliminación restringida).
- `(resultado_id,analisis_id)` → `resultados(id,analisis_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.revisiones (
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
```

## Alerta — `alertas`

Registra el seguimiento operacional de un resultado.

**Justificación:** Separa la detección del problema de su atención por una persona.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_alerta | bigint | No | Automático | Identificador interno único del registro. | 1 |
| resultado_id | Relación: resultado_id | bigint | No | — | Identificador del resultado original relacionado. | 2010 |
| analisis_id | Relación: analisis_id | bigint | No | — | Identificador de la ejecución de análisis relacionada. | 2010 |
| motivo | motivo | text | No | — | Descripción de la condición que originó la alerta. | Disponibilidad crítica |
| estado | estado | varchar(20) | No | 'pendiente' | Etapa de atención de la alerta; no es la clasificación del resultado. | pendiente |
| responsable_id | Relación: responsable_id | bigint | Sí | — | Usuario asignado a atender la alerta, opcional hasta su asignación. | NULL |
| cerrada_por | Relación: cerrada_por | bigint | Sí | — | Usuario que registró el cierre de la alerta. | 25 |
| creada_en | fecha_generacion | timestamptz | No | current_timestamp | Fecha y hora de generación de la alerta. | 2026-11-14T15:32:00-03:00 |
| cerrada_en | fecha_cierre | timestamptz | Sí | — | Fecha y hora de cierre; debe existir para alertas atendidas o descartadas. | NULL |

**Relaciones:**

- `(responsable_id)` → `usuarios(id)` (eliminación restringida).
- `(cerrada_por)` → `usuarios(id)` (eliminación restringida).
- `(resultado_id,analisis_id)` → `resultados(id,analisis_id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.alertas (
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
```

## Evento de auditoría — `eventos_auditoria`

Registra acciones relevantes sobre los registros del sistema.

**Justificación:** Permite reconstruir quién realizó una acción y cuándo, sin guardar secretos.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| id (PK) | id_evento | bigint | No | Automático | Identificador interno único del registro. | 1 |
| actor_id | Relación: actor_id | bigint | Sí | — | Usuario autor de la acción; puede ser NULL para un evento automático. | 18 |
| accion | accion | varchar(60) | No | — | Código de la acción registrada; el catálogo se definirá en el backend. | usuario.suspender |
| entidad | entidad_afectada | varchar(60) | No | — | Nombre de la entidad o tabla afectada por la acción. | usuarios |
| entidad_id | id_registro_afectado | bigint | No | — | Identificador del registro afectado; referencia genérica sin clave foránea. | 25 |
| detalle | detalle | jsonb | No | '{}'::jsonb | Contexto de la acción sin contraseñas, hashes de contraseña ni tokens. | {"motivo":"suspensión administrativa"} |
| creado_en | fecha | timestamptz | No | current_timestamp | Fecha y hora de creación o registro, con zona horaria. | 2026-11-14T15:30:00-03:00 |

**Relaciones:**

- `(actor_id)` → `usuarios(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.eventos_auditoria (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 actor_id bigint REFERENCES usuarios(id) ON DELETE RESTRICT,
 accion varchar(60) NOT NULL,
 entidad varchar(60) NOT NULL,
 entidad_id bigint NOT NULL,
 detalle jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(detalle)='object'),
 creado_en timestamptz NOT NULL DEFAULT current_timestamp
);
```

## Sesión de API — `sesiones`

Acceso autenticado temporal de un usuario.

**Justificación:** Permite revocar acceso y conservar solo la huella del token.

| Campo | Atributo MER / relación | Tipo | Admite NULL | Predeterminado | Significado | Ejemplo |
|---|---|---|---|---|---|---|
| token_hash (PK) | token_hash | varchar(64) | No | — | SHA-256 del token de sesión; no almacenar el token original. | 64 caracteres hexadecimales |
| usuario_id | Relación: usuario_id | bigint | No | — | Usuario al que pertenece la sesión. | 18 |
| creada_en | creada_en | timestamptz | No | current_timestamp | Fecha de creación de la sesión. | 2026-11-14T15:30:00-03:00 |
| expira_en | expira_en | timestamptz | No | — | Fecha de expiración, posterior a la creación. La API emite sesiones de ocho horas. | 2026-11-14T23:30:00-03:00 |

**Relaciones:**

- `(usuario_id)` → `usuarios(id)` (eliminación restringida).

**Definición PostgreSQL:**

```sql
CREATE TABLE regova.sesiones (
 token_hash varchar(64) PRIMARY KEY CHECK(token_hash ~ '^[0-9a-f]{64}$'),
 usuario_id bigint NOT NULL REFERENCES regova.usuarios(id) ON DELETE RESTRICT,
 creada_en timestamptz NOT NULL DEFAULT current_timestamp,
 expira_en timestamptz NOT NULL,
 CHECK(expira_en > creada_en)
);
```

## Reglas del flujo vigente

- El pasillo pertenece a cada análisis y es obligatorio, incluso si no existe ningún registro en gondolas. El backend toma local y autor de la sesión.
- Las FK a góndolas son opcionales por compatibilidad; una FK adicional entre imagen y local evita mezclar locales cuando gondola_id es NULL.
- Referencia y observaciones son opcionales. Editar metadatos no sobrescribe la predicción.
- Se mantienen versiones de modelo/umbrales, revisiones separadas, evidencia inmutable y permisos por rol.
- Local, imagen y análisis son entidades distintas. El ID de análisis no identifica por sí solo una góndola física estable.
- La selección de configuración vigente y sesiones son estructuras auxiliares del ML.
- No se inventan originales ni se importa el historial antiguo al flujo nuevo.

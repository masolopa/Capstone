# REGOVA — Construcción de la API y diseño final de datos

Fecha de revisión: 15 de noviembre de 2026. Estado: implementación local funcional; estructura contrastada con REGOVA_BD. Este documento describe el sistema construido, sus decisiones y sus límites.

## 1. Propósito y alcance

REGOVA recibe fotografías de exhibiciones, ejecuta un detector de productos y espacios vacíos, calcula indicadores y conserva evidencia para consulta y seguimiento. El prototipo funciona en un PC con Windows: FastAPI, PostgreSQL y los archivos permanecen localmente. La precisión del detector se evalúa por separado de la persistencia y de la corrección del flujo de la API.

La unidad de registro es cada análisis. Se identifica mediante un ID automático, su usuario ejecutor, el local de su sesión y un pasillo obligatorio declarado al cargar la foto. La referencia de ubicación y las observaciones son opcionales. No se exige registrar previamente cada góndola o pasillo.

## 2. Construcción de la API

Se mantuvo FastAPI y el procesamiento OpenCV/YOLO existente. La integración provisional con SQLite y cuentas de localStorage se reemplazó para las operaciones nuevas por PostgreSQL y autenticación del servidor. La organización sigue una aplicación única por responsabilidades; no requiere microservicios ni servicios de nube.

| Componente | Responsabilidad |
|---|---|
| app/main.py | Crear la aplicación, configurar CORS, asociar middleware, registrar rutas, manejar errores y servir dist. |
| app/api/routes.py | Definir el contrato HTTP, validar permisos y delegar operaciones. |
| app/api/schemas.py | Validar cuerpos de entrada y la respuesta principal de análisis mediante Pydantic. |
| app/core/config.py | Leer la configuración privada y resolver las rutas del almacenamiento. |
| app/core/database.py | Abrir conexiones PostgreSQL con transacciones cortas, cierre y rollback ante errores. |
| app/core/security.py | Hash Argon2, sesiones opacas, permisos, límite local de intentos y protección de mutaciones. |
| app/repositories.py | Ejecutar consultas parametrizadas y limitadas por local; registrar auditoría. |
| app/services/analysis.py | Validar imágenes y polígonos, conservar evidencia y coordinar inferencia y persistencia. |
| app/services/vision.py | Ejecutar el cálculo de visión existente sin acceso a sesiones o base de datos. |
| app/services/storage.py | Guardar y recuperar archivos mediante claves relativas, evitando rutas fuera de la raíz. |
| app/services/historical.py | Presentar el historial de prueba en modo lectura, separado del flujo operacional. |
| app/bootstrap.py | Preparar local, administrador, configuración inicial y versiones de modelos de forma reejecutable. |
| preparar_local.py | Configurar credenciales locales, permisos PostgreSQL y datos iniciales. |
| equipo.py | Preparación de entornos, restauración en una base vacía y comprobaciones previas al inicio. |

La interfaz usa un cliente HTTP común que adjunta la cookie de sesión y la cabecera de mutación. Ya no obtiene permisos efectivos ni contraseñas desde localStorage. La interfaz oculta las acciones que no corresponden al rol; el backend vuelve a comprobarlas y no confía en esa ocultación como mecanismo de seguridad.

## 3. Autenticación y autorización

Las contraseñas se conservan como hashes Argon2. Después del login, el servidor crea un token aleatorio y guarda solo su SHA-256 en sesiones. El navegador recibe una cookie HttpOnly, SameSite=Strict y con ruta /api. La sesión expira en ocho horas; logout elimina la sesión. Cambiar el rol, suspender o eliminar una cuenta revoca sus sesiones. En cada solicitud se comprueba además que la cuenta y su local sigan activos.

| Operación | Administrador | Supervisor | Reponedor |
|---|---|---|---|
| Consultar panel y reportes del local | Sí | Sí | Sí |
| Ejecutar análisis | Sí | Sí | No |
| Editar pasillo, referencia y observaciones | Sí | Sí | No |
| Registrar revisión de una predicción mediante API | Sí | Sí | No |
| Dar de baja un análisis | Sí | No | No |
| Gestionar cuentas y umbrales | Sí | No | No |
| Consultar alertas | Sí | Sí | Sí |
| Tomar y cerrar la atención de una alerta | No | No | Sí |

ADM-001 está protegida contra cambios y baja mediante la administración de cuentas. Los administradores secundarios no pueden crear o modificar administradores pares. La aplicación se conecta con un rol PostgreSQL sin permisos globales de administración y con permisos DML limitados. No utiliza la contraseña del propietario de la base para operar diariamente.

Las mutaciones exigen X-Regova-Request: 1; se rechazan orígenes ajenos a la lista local. El límite de intentos es por proceso y no se presenta como protección distribuida. Secure permanece desactivado para HTTP local; un despliegue externo exige HTTPS y otra revisión de configuración.

## 4. Flujo de un análisis nuevo

1. El usuario autenticado carga una imagen, indica el pasillo y opcionalmente agrega referencia, observaciones, fecha, filas y polígonos.
2. La API comprueba rol, tamaño de carga, formato real, dimensiones, fecha y geometría. Las coordenadas deben ser normalizadas y los polígonos no deben cruzarse.
3. Selecciona una configuración versionada del local y una versión registrada del modelo. Verifica el hash de sus pesos.
4. Conserva los bytes originales del archivo y registra imagen, usuario y ejecución en estado procesando mediante una transacción corta.
5. Ejecuta la visión fuera del hilo asíncrono. El proceso local admite una inferencia simultánea y responde 429 a otra solicitud de análisis mientras esté ocupado.
6. En una transacción final guarda resultado, referencia de la imagen procesada, alerta si corresponde, auditoría y estado exitoso. Una excepción controlada registra estado fallido y conserva el original, sin un resultado parcial.
7. La aplicación consulta el registro guardado; los PDF se generan a demanda. Una revisión humana se agrega por separado de la predicción.

El filesystem y PostgreSQL no comparten una transacción. Se compensan fallos normales al guardar archivos; un apagado abrupto puede requerir conciliación de archivos huérfanos o ejecuciones procesando. No hay una cola persistente de trabajos ni recuperación automática después de una interrupción.

## 5. Diseño final de la base

La revisión del esquema instalado encontró 14 tablas, 115 campos y 22 claves foráneas. Se contrastaron nombres, tipos y nulabilidad de todos los campos con el SQL de referencia, y tabla/campos de origen y destino de todas las claves foráneas. No se encontraron diferencias en esas comparaciones.

| Tabla | Finalidad |
|---|---|
| locales | Identificar el establecimiento y su estado operativo. |
| usuarios | Cuentas, roles, contraseña protegida y bajas lógicas. |
| imagenes | Original, autor de carga, local, fechas, dimensiones, tamaño y hash. |
| analisis | Ejecución, autor, pasillo, metadatos, versiones, tiempos y estado. |
| configuraciones_analisis | Versiones de umbrales y requisitos de entrada. |
| configuraciones_vigentes | Selección de la versión actual de cada local. |
| modelos_vision | Versiones de detector, referencia de pesos, huella y métricas. |
| resultados | Predicción global original de una ejecución y detalle de visión. |
| archivos_analisis | Overlays y otras evidencias generadas que se archiven. |
| revisiones | Confirmaciones, correcciones o descartes humanos, sin sobrescribir la predicción. |
| alertas | Seguimiento operacional y usuarios responsables de atención/cierre. |
| eventos_auditoria | Acciones relevantes, registro afectado, actor y fecha. |
| sesiones | Tokens opacos representados por su hash y fecha de expiración. |
| gondolas | Compatibilidad con la estructura anterior; no es un catálogo exigido por el flujo actual. |

Gondola_id es opcional en imágenes y análisis. No se crean góndolas ficticias para completar claves. Una FK adicional entre analisis(imagen_id,local_id) e imagenes(id,local_id) conserva la pertenencia al local incluso cuando no existe góndola asociada. El pasillo pertenece a la captura, no es un catálogo separado. El ID de análisis no identifica una góndola física permanente: dos fotos del mismo pasillo pueden corresponder a exhibiciones diferentes.

En Local.estado, Usuario.estado y el antiguo Góndola.estado, el término representa activo/inactivo y no una división territorial. El diccionario detalla las correspondencias entre nombres descriptivos del MER y nombres concretos de SQL.

## 6. Reglas de integridad y trazabilidad

- La disponibilidad está entre 0 y 100. Un resultado no evaluable conserva NULL, sin transformarlo en disponibilidad cero.
- Configuración: 0 < umbral crítico < umbral bajo <= 100. Crítica incluye el primer límite; baja es mayor que el crítico y menor que el bajo; aceptable comienza en el límite bajo.
- Cada análisis conserva su versión de configuración y modelo. Cambiar criterios no reclasifica automáticamente resultados antiguos.
- Existe como máximo un resultado global por ejecución. Confirmar un análisis exitoso y su resultado conjuntamente es responsabilidad transaccional de la aplicación.
- Los triggers protegen evidencia versionada frente a UPDATE/DELETE ordinarios y comprueban clasificación y pertenencia de los actores de revisiones/alertas al local.
- Las bajas de cuentas y análisis conservan su evidencia. Sesiones no son evidencia de visión y pueden eliminarse al cerrar acceso.
- Auditoría no contiene contraseñas ni tokens. Las operaciones implementadas insertan el evento dentro de la misma transacción de sus datos.
- Los índices apoyan referencias, historial por local/pasillo/fecha, consultas de usuarios y alertas pendientes. No se introdujeron particiones sin medir una necesidad.

## 7. Imágenes y modelos en almacenamiento local

PostgreSQL conserva metadatos y claves relativas a storage; los archivos se guardan fuera de las tablas. Se conserva el original recibido y una imagen procesada independiente. El servidor puede convertir el original a JPEG para la vista, sin reemplazar la evidencia original en disco. No se guardan imágenes base64 dentro del JSON de resultados nuevos.

Los pesos se copian por contenido y se identifican con SHA-256. El detector usa la ruta de la versión seleccionada, no un archivo reemplazado silenciosamente. Las nuevas inferencias pueden usar CPU si no hay CUDA disponible; el tiempo de respuesta depende del equipo. El cambio de dispositivo no equivale a entrenamiento ni modifica pesos.

## 8. Historial de prueba para el panel

Los 124 registros antiguos siguen conservados en regova_legacy y en el respaldo SQLite. Para poblar el panel se genera un índice de solo lectura en storage/historico/indice.json y se conservan sus 124 overlays. Solo 7 tienen fotografía original. No se reconstruyen autores reales, pasillos, versiones exactas del modelo o segundos umbrales que no se registraron.

GET /api/dashboard/history combina los resúmenes actuales de PostgreSQL con esta proyección histórica y devuelve hasta 200 capturas recientes. El panel etiqueta las antiguas como Histórico de prueba y permite excluirlas. Sus identificadores visuales H-N no colisionan con los operacionales; los IDs negativos son una convención de la respuesta del panel, no claves guardadas en analisis.

GET /api/dashboard/historical/{id}/report.pdf entrega el PDF de lectura con las ausencias indicadas. Los históricos no crean análisis nuevos ni alertas actuales de reposición. GET /api/history, GET /api/metrics y la sección Reportes mantienen el flujo operacional nuevo. La API limita el archivo histórico al local piloto del que procede.

Se conservan fechas y resultados originales. La combinación sirve para presentar el panel con datos de prueba; no demuestra evolución de una única góndola ni uniformidad de criterios históricos.

## 9. Migraciones y correspondencia de entregables

- 000_esquema_inicial.sql: creación en una base vacía. No debe repetirse sobre una instalación existente.
- 001_sesiones_api.sql: infraestructura de sesiones.
- 002_ubicacion_por_analisis.sql: ubicación por pasillo y relaciones de góndolas opcionales; conserva datos existentes.
- migrations/historico/01_Conservar_Historial_PostgreSQL.sql: conservación separada de los datos originales.

El MER representa 11 entidades de negocio. El ML añade selección de configuración vigente, sesiones y la tabla anterior de compatibilidad, por lo que incluye las 14 tablas físicas. Los atributos derivados de relaciones se materializan como FK en el ML y se explican en el diccionario. El historial del panel es una proyección de lectura: no agrega entidades operacionales.

Los diagramas ya se actualizaron con el flujo por pasillo; esta revisión no exigió regenerarlos nuevamente. La evidencia de comparación se encuentra en docs/modelado/03_Documentacion/Verificacion_Modelado.md y Esquema_Instalado_PostgreSQL.json. El diccionario, ML y MER se encuentran en las carpetas numeradas del mismo directorio.

## 10. Validación y límites

Las pruebas automatizadas cubren autenticación, permisos, sesiones, separación por local, datos y evidencia de análisis, metadatos, umbrales versionados, fallos, reportes, alertas e historial de prueba. Se verificó la generación de PDF para los 124 registros antiguos. Se efectuó además una inferencia real del checkpoint disponible y una inferencia en CPU sin guardar resultados adicionales en la base operacional.

El respaldo PostgreSQL del esquema operacional se restauró en una instancia separada, recuperando cinco análisis, cinco resultados y cuatro usuarios presentes al tomarlo. Se conserva por separado el respaldo antiguo y sus archivos. Este ensayo verifica la restauración de esa copia; no convierte automáticamente cualquier futura copia de carpetas en un respaldo coordinado mientras existen escrituras.

El entrenamiento y la evaluación del detector son actividades independientes de la migración. No hay aprendizaje continuo, catálogo SKU, predicción de demanda ni notificación externa implementados. Esta copia incluye pesos para inferencia, no los datasets completos para reentrenamiento. La interfaz aún no tiene un editor completo de correcciones humanas; la API sí registra revisiones separadas.

La operación externa o con múltiples procesos necesitará revisar HTTPS, límites, recuperación de trabajos, almacenamiento compartido y administración de credenciales. La estructura puede evolucionar mediante migraciones versionadas, con respaldo y pruebas previas.

## 11. Ubicación de archivos del proyecto

Código en backend/app y src; migraciones en backend/migrations; frontend compilado en dist; documentación en docs; evidencia/modelos en backend/storage; configuración privada en backend/.env; respaldos en backend/backups. Los directorios privados están excluidos de Git.

Los archivos de datos activos del motor PostgreSQL los administra su servicio fuera de la carpeta del proyecto. Para conservar una copia transportable se incluye un respaldo lógico .dump dentro de backend/backups/postgresql; no se debe copiar en caliente el directorio interno de PostgreSQL.

## Referencias técnicas

- FastAPI, seguridad y Argon2: https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/
- Psycopg 3, transacciones: https://www.psycopg.org/psycopg3/docs/basic/transactions.html
- PostgreSQL, restricciones: https://www.postgresql.org/docs/18/ddl-constraints.html
- PyTorch, versiones e instalación CPU: https://docs.pytorch.org/get-started/previous-versions/
- Ultralytics, selección de dispositivo de inferencia: https://docs.ultralytics.com/modes/predict/

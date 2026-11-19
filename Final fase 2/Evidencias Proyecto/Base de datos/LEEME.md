# REGOVA — modelo y diccionario vigentes

Flujo corregido: ID de análisis + local de sesión + pasillo obligatorio + referencia opcional. No se exige un catálogo de góndolas.

- 01_ML: modelo lógico completo y vistas por sección en PNG; versión completa editable en draw.io. Incluye las estructuras auxiliares y la tabla anterior de góndolas marcada como compatibilidad histórica.
- 02_MER: entidades de negocio y atributos dentro de cuadros, con cardinalidades. Vista completa editable y vistas de operación/seguimiento. No incluye góndolas como entidad operativa.
- 03_Documentacion: justificaciones, reglas de negocio, flujo y guía de la API.
- 04_Diccionario: significado, tipos, nulabilidad, ejemplos y restricciones de los 115 campos de las 14 tablas físicas. Góndolas es opcional y se conserva por compatibilidad; sesiones es infraestructura de autenticación.
- 05_SQL_referencia: creación para una BASE VACÍA y migraciones separadas. Para tu base ya creada, aplicar SOLO 02_Ubicacion_por_Analisis.sql o usar ejecutables/ACTUALIZAR_UBICACION.bat del backend. No volver a ejecutar la creación completa.

La corrección se probó con PostgreSQL real, análisis sin registros de góndolas, autenticación y permisos. La actualización de tu REGOVA_BD requiere la contraseña del propietario, introducida localmente en el asistente; no fue aplicada por Codex. No se cambian cuentas ni contraseñas.

Los identificadores se marcan con # en el MER. 1 significa exactamente uno, 0..1 opcional y 0..N ninguno o muchos; se leen en el extremo de cada entidad. PK y FK son claves del ML. Local.estado significa activo/inactivo, no región geográfica.

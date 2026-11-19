# REGOVA API — PostgreSQL y operación local

## Puesta en marcha en este PC

La estructura inicial de REGOVA_BD ya se creó en pgAdmin. No volver a ejecutar migrations/000_esquema_inicial.sql sobre ella.

1. Cerrar la ventana del backend anterior si sigue ejecutándose en el puerto 8011.
2. Ejecutar ejecutables/PREPARAR_POSTGRESQL.bat. Elegir REGOVA_BD y el propietario postgres. Ingresar su contraseña en el asistente; no se guarda esa contraseña de propietario.
3. Definir una contraseña nueva de al menos 10 caracteres para ADM-001. No usar la antigua clave de demostración. Si la cuenta ya existe, el asistente conserva su contraseña.
4. El asistente aplica migrations/001_sesiones_api.sql, prepara un rol regova_app sin privilegios administrativos, guarda su configuración privada en backend/.env y registra el local piloto, umbrales iniciales 30/70 y el modelo YOLO disponible. No crea góndolas ficticias ni importa análisis antiguos.
5. Ejecutar ejecutables/EJECUTAR.bat. Para desarrollo, iniciar también ejecutables/INICIAR_FRONTEND.bat. Como alternativa, el backend sirve la interfaz compilada desde http://127.0.0.1:8011.
6. Ingresar como ADM-001, crear cuentas de supervisor y reponedor en Gestión de usuarios sin registrar góndolas ni pasillos previamente.
7. Iniciar sesión como administrador o supervisor, indicar el pasillo de la fotografía y realizar un análisis nuevo. La referencia de ubicación es opcional. El reponedor consulta reportes y atiende las alertas en Estado y alertas.

La contraseña de aplicación PostgreSQL se genera automáticamente y queda en .env, excluido de Git. La contraseña del propietario solo se utiliza durante la preparación. No compartir ni adjuntar .env. El asistente no elimina datos de regova_legacy y no utiliza la segunda migración histórica opcional.

## Organización

```text
backend/app/
  main.py                 Fábrica FastAPI, errores, CORS, logs y archivos estáticos
  api/routes.py           Contrato HTTP y permisos por operación
  api/schemas.py          Validación de entradas y respuesta de análisis
  core/config.py          Configuración local y raíz de archivos
  core/database.py        Conexiones y transacciones PostgreSQL
  core/security.py        Sesiones, Argon2, permisos y protección de mutaciones
  repositories.py         Consultas parametrizadas limitadas al local y auditoría
  services/analysis.py    Guardado de evidencia, ejecución y estados
  services/vision.py      Procesamiento existente OpenCV/YOLO
  services/storage.py     Archivos privados con nombres únicos
  bootstrap.py            Datos iniciales reejecutables
backend/migrations/
  000_esquema_inicial.sql  Solo para una base vacía
  001_sesiones_api.sql     Extensión técnica para sesiones
  002_ubicacion_por_analisis.sql  Pasillo por captura, sin catálogo obligatorio
```

La aplicación usa una sola instancia local y un worker Uvicorn. La inferencia se ejecuta fuera del hilo asíncrono del servidor, con una sola ejecución simultánea; otra solicitud de análisis recibe 429 para reintentar después. No hay cola persistente de trabajos ni microservicios.

## Autenticación y permisos

- Cookie de sesión HttpOnly y SameSite=Strict; el token es opaco y solo su SHA-256 se guarda en sesiones. Expira en ocho horas y se elimina en logout.
- Contraseñas Argon2; ningún inicio de sesión se valida con localStorage. Las viejas cuentas del navegador no se importan automáticamente.
- Se comprueban cuenta activa, baja lógica y local activo en cada solicitud autenticada. Cambiar rol, suspender o eliminar una cuenta revoca sus sesiones.
- Administrador y supervisor ejecutan análisis y editan sus metadatos. Solo administrador da de baja análisis, gestiona cuentas, configura umbrales.
- Reponedor no ejecuta análisis; consulta evidencia y puede tomar/cerrar su propia atención de alerta. No puede cerrar una alerta asignada a otra persona.
- ADM-001 está protegida frente a modificación o baja desde las rutas de administración. Otros administradores no pueden crear ni modificar administradores pares.
- Todas las mutaciones requieren X-Regova-Request: 1 y se rechazan orígenes ajenos a la lista local configurada. El frontend agrega la cabecera; los enlaces PDF funcionan mediante la cookie de sesión.
- El límite de intentos de login es local al proceso. No es un servicio distribuido de protección; suficiente para el alcance de un único PC.

## Datos y archivos

PostgreSQL conserva los 13 grupos de datos del esquema original y añade la tabla técnica sesiones (14 tablas en regova). Sus cuatro campos son token_hash (varchar(64), PK), usuario_id (bigint, FK a usuarios), creada_en y expira_en (timestamptz). Se puede eliminar una sesión sin afectar la evidencia ni la auditoría.

Las fotografías originales se conservan como los bytes recibidos, con MIME, dimensiones y SHA-256. La interfaz recibe una vista JPEG por compatibilidad. Los overlays son archivos separados. El campo uri es una clave relativa a backend/storage; no se publica el directorio como carpeta estática.

Cada análisis registra su ID, usuario real, local de sesión, pasillo declarado, referencia opcional, imagen, versión de configuración y versión de modelo. No requiere identificar previamente una góndola. El modelo usa pesos copiados por contenido y comprueba su hash antes de ejecutar. Los polígonos se validan en el backend; no se convierten en regiones físicas administradas.

El procesamiento usa transacciones cortas: primero registra original y análisis procesando; después ejecuta visión; finalmente confirma resultado, archivo, alerta y estado exitoso conjuntamente. En un fallo conserva el original y registra el estado fallido sin un resultado parcial. No se conservan base64 en el JSON de resultados.

Los umbrales se versionan. Editarlos no modifica predicciones antiguas. Las revisiones humanas se agregan sin sobrescribir el resultado original. Los reportes PDF se generan a demanda, también agrupados. La API permite registrar revisiones; la interfaz actual de resultados conserva edición de metadatos y consulta, sin un editor completo de correcciones humanas.

El endpoint de historial acepta limit (1–200) y before_id para paginar. Las métricas de la API se agregan sobre todo el historial no eliminado del local. La vista actual del dashboard sigue trabajando con su lote de hasta 200 registros para gráficos y filtros; ampliar esos gráficos a agregaciones por período queda como mejora de interfaz.

## Contrato HTTP

Documentación interactiva: http://127.0.0.1:8011/api/docs

- GET /api/health: proceso disponible; GET /api/ready: conexión y esquema básico.
- POST /api/auth/login, GET /api/auth/me, POST /api/auth/logout.
- GET/POST /api/users, PATCH/DELETE /api/users/{codigo}, GET /api/users/activity.
- GET/PUT /api/settings.
- POST /api/analyze: multipart con file, pasillo y parámetros. El autor se toma de la sesión, nunca de un campo enviado por el cliente.
- GET /api/history, GET /api/metrics, GET/PATCH/DELETE /api/analyze/{id}.
- POST /api/analyze/{id}/reviews: revisión humana separada.
- GET /api/analyze/{id}/report.pdf, POST /api/reports/grouped.pdf.
- GET /api/alerts, PATCH /api/alerts/{id}.
- GET /api/training/status: estado existente del detector/dataset; no entrena.

En Swagger, indicar X-Regova-Request=1 para mutaciones e iniciar sesión con el endpoint de login. El navegador conserva la cookie HttpOnly. Códigos principales: 401 sesión inválida, 403 permiso denegado, 404 registro fuera de alcance/no encontrado, 409 conflicto, 422 entrada inválida, 429 límite o detector ocupado, 503 base/detector no disponible. Los errores internos no devuelven rutas, credenciales ni stderr. X-Request-ID permite relacionar una respuesta con el log.

## Validación

Se probaron en una instancia separada PostgreSQL 18 las rutas reales, el guardado de originales, PDFs, permisos, aislamiento por local, sesiones, fallos, versiones y almacenamiento. Las pruebas se ejecutan solo con REGOVA_TEST_DSN apuntando a una base desechable cuyo nombre termine en _TEST. La prueba usa TRUNCATE para limpiar esa base de pruebas: nunca usar REGOVA_BD.

Las pruebas anteriores del contrato SQLite sin autenticación se conservan en backend/tests_legacy como referencia. Las pruebas vigentes de visión se mantienen en backend/tests. pytest.ini limita la ejecución normal a tests.

También se probó una inferencia real del checkpoint YOLO disponible, con guardado en PostgreSQL y generación de PDF, y el asistente con un rol de aplicación sin permisos globales.

## Límites y conservación

- La nueva API todavía requiere ejecutar la preparación con las credenciales locales del usuario. Las verificaciones realizadas no activaron la nueva API sobre su REGOVA_BD.
- Se mantiene regova_legacy como conservación separada de los 124 análisis antiguos. El funcionamiento nuevo empieza sin importarlos.
- Un apagado abrupto puede dejar un análisis procesando o un archivo huérfano. Se necesita conciliación manual/controlada; no hay recuperación automática de trabajos. Los errores capturados sí registran estado fallido.
- El filesystem y PostgreSQL no comparten una transacción. Se limpian archivos en fallos normales y se conserva evidencia cuando ya existe una ejecución. Respaldar juntos base, storage, modelo y configuración privada; probar restauración.
- El cookie Secure permanece desactivado para HTTP local. Un despliegue externo requiere HTTPS y revisar orígenes, permisos, almacenamiento, recuperación de contraseñas y operación multiusuario.
- No se ha implementado aprendizaje continuo, catálogo SKU, predicción de demanda ni un sistema externo de notificaciones. Las alertas representan resultados operacionales, no una predicción de demanda.

Referencias técnicas consultadas: documentación de FastAPI sobre seguridad y Argon2 (https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/) y transacciones de Psycopg 3 (https://www.psycopg.org/psycopg3/docs/basic/transactions.html).

## Corrección de ubicación para instalaciones ya preparadas

Ejecutar ejecutables/ACTUALIZAR_UBICACION.bat e ingresar la contraseña PostgreSQL del propietario (postgres). Aplica únicamente la migración 002. No cambia cuentas ni contraseñas y no borra evidencia. Luego reiniciar ejecutables/EJECUTAR.bat y recargar el navegador con Ctrl+F5.

El pasillo se escribe en el formulario existente de captura, junto a la referencia y la fecha. Se muestra en resultados, PDF y alertas. Las rutas de registro de góndolas se retiraron. La tabla gondolas se conserva solo por compatibilidad; sus relaciones son opcionales. No se crean registros ficticios para satisfacer claves foráneas. Una FK de imagen y local mantiene el aislamiento aunque no exista góndola asociada.

Instalación nueva: el asistente aplica 001 y 002. No volver a ejecutar 000 en una base existente. La guía, el diccionario y los diagramas de la carpeta de modelado se actualizaron a este flujo.

## Historial de prueba en el panel

El panel usa /api/dashboard/history para combinar hasta 200 registros nuevos e históricos identificados. Los antiguos se leen desde storage/historico/indice.json y sus overlays preservados; son de solo lectura y no generan tareas de reposición actuales. /api/dashboard/historical/{id}/report.pdf permite consultar su evidencia. /api/history y /api/metrics continúan representando la operación nueva.

La documentación de construcción y la comprobación del esquema están en docs/CONSTRUCCION_API_Y_BD.md y docs/modelado/03_Documentacion/Verificacion_Modelado.md.

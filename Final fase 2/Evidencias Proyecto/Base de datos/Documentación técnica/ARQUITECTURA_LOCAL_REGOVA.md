# Arquitectura local de REGOVA

Todo se ejecuta en el PC del tesista: navegador, FastAPI, PostgreSQL y detector. PostgreSQL conserva datos y referencias; backend/storage conserva originales, procesadas, modelos y reportes archivados. No se requiere nube.

El usuario carga una fotografía indicando pasillo y una referencia opcional. Local y autor se toman de su sesión. No hay registro previo obligatorio de góndolas ni pasillos.

Cada ejecución conserva su ID, imagen, configuración y versión de modelo. Un original puede procesarse de nuevo, y una revisión humana no reemplaza la predicción original. Los archivos se identifican por claves relativas y hashes; el backend limita su acceso al local autorizado.

El modelo de datos anterior se actualiza mediante 002_ubicacion_por_analisis.sql. Las tablas y vínculos opcionales de góndolas se conservan únicamente por compatibilidad histórica; las rutas y el formulario de administración se retiraron.

Los 124 análisis antiguos siguen conservados en regova_legacy y no se importan al flujo nuevo. Respaldar base y archivos conjuntamente, y probar restauración. Un respaldo en el mismo disco no protege frente a su pérdida.

Para aplicar la corrección sobre una instalación ya preparada: ejecutar ejecutables/ACTUALIZAR_UBICACION.bat con la contraseña PostgreSQL del propietario, reiniciar ejecutables/EJECUTAR.bat y recargar la interfaz con Ctrl+F5. No cambia la contraseña de ADM-001 y no requiere repetir PREPARAR_POSTGRESQL.

Detalle de permisos, pruebas y funcionamiento: API_REGOVA.md.

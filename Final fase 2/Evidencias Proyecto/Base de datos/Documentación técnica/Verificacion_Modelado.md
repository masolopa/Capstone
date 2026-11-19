# Verificación del modelado contra PostgreSQL instalado

Revisión realizada el 15 de noviembre de 2026 sobre REGOVA_BD, sin modificar sus datos.

- 14 tablas en el esquema regova y 115 campos.
- Coincidencia de nombres, tipos y nulabilidad entre el SQL de referencia y la base instalada: sin diferencias.
- El archivo Esquema_Instalado_PostgreSQL.json registra las columnas, restricciones, índices y triggers observados para su revisión.
- Pasillo es obligatorio en analisis. Las referencias a gondolas son opcionales y de compatibilidad; la FK adicional imagen/local conserva aislamiento territorial.
- El MER representa 11 entidades de negocio. El ML incluye además configuraciones_vigentes, sesiones y la tabla histórica de compatibilidad gondolas. Por eso no tienen el mismo número de cuadros.
- Los datos históricos que alimentan el panel son una proyección de lectura, marcada historical_test. No se insertan como análisis nuevos ni añaden columnas a las tablas operacionales. Los identificadores H corresponden al origen antiguo y no colisionan con los IDs operacionales.
- El respaldo antiguo sigue conservado en regova_legacy y en backend/backups/historico_sqlite. La API usa el índice de lectura dentro de backend/storage/historico para presentar el panel sin necesitar permisos de escritura sobre el archivo histórico.

Esta comprobación contrasta estructura y captura las relaciones reales. No equivale a una validación académica de todos los requisitos ni a una prueba de restauración de respaldo.

Comparación adicional de claves foráneas: las 22 relaciones instaladas coinciden en tabla origen, campos y tabla/campos destino con el SQL de referencia.

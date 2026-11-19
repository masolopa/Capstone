# Modelo lógico inicial de REGOVA — versión vigente

La unidad de registro es el análisis de una fotografía. Cada ejecución tiene un ID automático, un local tomado de la sesión autenticada, un usuario autor, un pasillo obligatorio y una referencia de ubicación opcional. No se exige dar de alta góndolas ni pasillos.

## Entidades del negocio

| Entidad | Finalidad y atributos principales |
|---|---|
| Local | Identificador, código, nombre, dirección y estado activo/inactivo. Agrupa usuarios y fotografías. |
| Usuario | Identificador, código de acceso, nombre, correo, hash de contraseña, rol y estado. |
| Imagen | Identificador, archivo original, formato, dimensiones, tamaño, hash, fecha de captura y carga. Pertenece a un local y a su usuario de carga. |
| Análisis | Identificador, pasillo, referencia, observaciones, estado, fechas, duración, parámetros y error cuando corresponda. |
| Configuración de análisis | Identificador, versión, umbrales, límites de carga y dimensiones mínimas. |
| Versión de modelo | Identificador, nombre, versión, método, referencia de pesos, hash y métricas. |
| Resultado | Identificador, disponibilidad, clasificación, área evaluable, necesidad de revisión y detalle de visión. |
| Revisión | Identificador, decisión, corrección, comentario, fecha y usuario revisor. |
| Alerta | Identificador, motivo, estado, fechas y usuarios de atención/cierre. |
| Archivo de análisis | Identificador, tipo, referencia, hash, tamaño y fecha. |
| Evento de auditoría | Identificador, actor cuando exista, acción, registro afectado, fecha y detalle. |

## Relaciones y cardinalidades

- Un local tiene cero o muchos usuarios y fotografías. Cada usuario/fotografía pertenece a un local.
- Un usuario carga cero o muchas imágenes y ejecuta cero o muchos análisis. El autor se obtiene del backend, no de un campo editable del formulario.
- Una imagen puede tener cero o muchos análisis. Cada análisis pertenece a una imagen.
- Una versión de modelo o configuración puede utilizarse en múltiples análisis; cada ejecución conserva exactamente las versiones utilizadas.
- Un análisis puede no tener resultado mientras está pendiente o si falla; al finalizar exitosamente tiene uno.
- Un resultado admite cero o muchas revisiones y alertas. No se sobrescribe la predicción al revisarla.
- Un análisis genera cero o muchos archivos.
- Cada alerta puede tener cero o un responsable y cero o un usuario de cierre; un usuario puede participar en múltiples alertas.
- El local selecciona como máximo una configuración vigente entre sus versiones. Se requiere una antes de analizar.

## Flujo

1. Administrador o supervisor ingresa y carga una foto.
2. Declara el pasillo y, opcionalmente, una referencia como «snacks, lado derecho». El local se obtiene de su sesión.
3. El backend guarda original, parámetros y usuario autor, y ejecuta el detector con una versión identificada.
4. Guarda resultado, imagen procesada y, si corresponde, una alerta.
5. El reponedor consulta pasillo, referencia, evidencia y reporte; puede tomar y cerrar la reposición asignada.
6. Una revisión humana queda separada de la predicción original.

## Justificación y límites

El pasillo es un atributo de la captura, no una entidad que necesite registro previo. El ID de análisis identifica una evaluación y no representa una góndola física permanente. Por ello, el sistema no afirma que dos fotos del mismo pasillo correspondan al mismo mueble. Si se requiere seguimiento de una góndola estable, se diseñará esa identificación como ampliación.

Las zonas dibujadas y filas detectadas son datos del procesamiento, no un catálogo de regiones o estantes. El prototipo usa PostgreSQL y almacenamiento de archivos en el mismo PC. No hay nube obligatoria ni aprendizaje continuo implementado.

## Traducción al esquema existente

El MER presenta estas 11 entidades de negocio. El ML incluye además selección de configuración vigente y sesiones. La tabla `gondolas` del diseño anterior permanece como compatibilidad histórica, sin uso obligatorio en el nuevo flujo. Sus dos relaciones son opcionales, y una FK adicional imagen/local mantiene el aislamiento territorial. No se borran tablas ni datos para esta corrección. El esquema físico conserva 14 tablas y pasa a 115 campos.

Los diagramas vigentes están en 01_ML y 02_MER; el significado de cada campo se encuentra en 04_Diccionario. En Local.estado se indica activo/inactivo; no una división territorial de Chile.

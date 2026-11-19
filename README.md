# R.E.G.O.V.A.

**Regiones de Góndola para Valoración de Ausencias**

Proyecto académico Capstone desarrollado a partir de una necesidad planteada por Walmart Chile. Su objetivo es analizar fotografías de góndolas para detectar productos y espacios vacíos visibles, y entregar indicadores que apoyen la reposición.

> Este repositorio reúne documentación y evidencias del proyecto. Los resultados de visión artificial son estimaciones sobre lo que se observa en una fotografía; no confirman el inventario oculto ni el stock físico de una tienda.

## Contenido del repositorio

- [Fase 1](./Fase%201/): evidencias grupales e individuales de la definición del proyecto.
- [Fase final 2](./Final%20fase%202/): entregables grupales e individuales y evidencias del proyecto.
  - [Evidencias del proyecto](./Final%20fase%202/Evidencias%20Proyecto/)
  - [Entregables grupales](./Final%20fase%202/Grupal/)
  - [Entregables individuales](./Final%20fase%202/Individual/)

## ¿Qué propone REGOVA?

El MVP analiza capturas de góndolas mediante visión computacional y presenta resultados como detecciones, ocupación estimada y alertas de reposición. La solución contempla revisión humana y seguimiento de las alertas. Las estimaciones dependen de la imagen y de las reglas de análisis, por lo que requieren validación antes de usarse como conclusiones operativas.

## Tecnologías del MVP

- **Interfaz:** React, TypeScript y Vite.
- **API:** Python, FastAPI y Uvicorn.
- **Visión computacional:** YOLO, OpenCV, PyTorch y Ultralytics.
- **Persistencia:** PostgreSQL.

## Alcance y validación

REGOVA es un MVP académico de operación local, no un sistema productivo certificado. La perspectiva, iluminación, oclusiones y calidad de las fotografías pueden afectar los resultados. Las estimaciones de ocupación no acreditan stock completo, profundidad disponible ni condiciones físicas de reposición.

Consulta las carpetas de cada fase para revisar los documentos y evidencias disponibles en el repositorio.

---

*Proyecto académico Capstone — REGOVA.*

# 🛒 R.E.G.O.V.A. — Reposición Eficiente de Góndolas mediante Operación con Visión Artificial

\*\*Sistema de visión computacional desacoplado para la detección automatizada, localización y estimación cuantitativa de espacios vacíos en góndolas de supermercados.\*\* 
---

## 📌 1\. Descripción de la Solución 

### 🎯 Problemática Abordada En la industria del retail y supermercados (como Walmart Chile), los quiebres de stock en góndola representan pérdidas de ventas y degradan la experiencia del cliente. La inspección manual visual realizada por el personal es ineficiente y propensa a errores. Además, las imágenes capturadas por cámaras de seguridad en salas de venta presentan \*\*condiciones ópticas hostiles\*\*: ángulos oblicuos, distorsión por lentes \*fisheye\*, variaciones de iluminación artificial, reflejos metálicos y oclusiones temporales por clientes o carros de compra.

# 🚀 Objetivos del Proyecto 

*Objetivo General:* Diseñar e implementar un sistema de visión computacional que determine de manera automatizada cuánto espacio libre existe en las góndolas de supermercado, expresándose mediante una estimación porcentual segmentada por nivel físico de estantería. 

*Aporte de Valor:* Superar la clasificación binaria de "vacío / no vacío", entregando una estimación cuantitativa del espacio disponible y activando alertas de reposición cuando la disponibilidad caiga al umbral crítico

### ⚙️ Funcionalidades Principales 

1 \*\*Mapa Digital Configurable (CU01 / RF01):\*\* Registro de la estructura física mediante la jerarquía \*\*Góndola --> Estante --> Región de exhibición\*\*. 2\. \*\*Pre-procesamiento Geométrica:\*\* Corrección de perspectiva (homografía) y filtro \*fisheye\* antes del análisis. 
3\. \*\*Análisis e Inferencia de IA (CU03 / RF03-RF04):\*\* Detección de espacios vacíos y cálculo de disponibilidad porcentual observable. 
4\. \*\*Post-procesamiento y Alertas (CU05-CU06 / RF05-RF08):\*\* Clasificación en estados (\*Normal\*, \*Atención\*, \*Crítico\*, \*Revisión requerida\*) y gestión del ciclo de vida de alertas (\*Pendiente\* \\\\(\\rightarrow\\\\) \*Atendida\*).
5\. \*\*Supervisión de Oclusiones (CU08 / RF10):\*\* Módulo para que el supervisor valide o descarte capturas bloqueadas por objetos externos.
---

## 🛠️ 2\. Estrategia y Justificación Técnica ### 

🧰 Stack Tecnológico Utilizado 
Lenguaje Principal: Python 3.10+ (Scripts \.py\ modularizados). 
Visión Computacional Pre-procesamiento: OpenCV, NumPy, Pillow.
Framework de Deep Learning:PyTorch, Ultralytics YOLOn8v. 
Backend REST API:Python + Flask, Flask-SQLAlchemy, Psycopg2 
Base de Datos Relacional: PostgreSQL 15+ / pgAdmin 4\. 
Frontend Web: React.js.
Entorno de Entrenamiento:\*\* Google Colab (GPU T4) / Kaggle GPUs.


## 🏗️ 3\. Arquitectura de la Solución La arquitectura de R.E.G.O.V.A. 

está dividida en tres componentes principales de procesamiento, un módulo de persistencia y una interfaz de usuario: 


[ Frontend Web (React) ] 
           │ 
           ▼

[ Backend API REST (Python + Flask) ] ◄────────► [ Base de Datos (PostgreSQL) ] 
                      │                                │

                    (Estructura y Alertas) 
          ▼                                          ▼ 
[ Pre-procesamiento ]           [ Visión Computacional ] 
 (OpenCV Homografía)          (YOLOv8n / PyTorch) │ │ 

            └──────────┬──────────┘ 
                       ▼ 
[ Post-procesamiento y Alertas ] (Umbral Macro <= 30% / Oclusiones)

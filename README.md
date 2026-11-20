# REGOVA — Regiones de Góndola para Valoración de Ausencias

![Python 3.13](https://img.shields.io/badge/Python-3.13-3776AB?logo=python)
![FastAPI 0.162.0](https://img.shields.io/badge/FastAPI-0.162.0-009688?logo=fastapi)
![React 19.3.1](https://img.shields.io/badge/React-19.3.1-61DAFB?logo=react)
![TypeScript 6.0.3](https://img.shields.io/badge/TypeScript-6.0.3-3178C6?logo=typescript)
![PostgreSQL 17 en Docker](https://img.shields.io/badge/PostgreSQL-17-336791?logo=postgresql)
![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

## Descripción

**REGOVA** analiza fotografías de góndolas para detectar espacios vacíos en tiendas minoristas. El personal puede consultar los resultados, revisar alertas y exportar reportes para priorizar la reposición.

El sistema combina un modelo YOLOv8n, procesamiento de imágenes con OpenCV, una API FastAPI y una interfaz en React y TypeScript. Los resultados se registran en PostgreSQL y el acceso a las funciones se controla mediante roles.

## Diagramas

### Modelo de datos

![Diagrama entidad-relación de REGOVA](docs/modelado/02_MER/MER_REGOVA_Completo.png)

### Flujo de análisis de imágenes

![Diagrama del flujo de aprendizaje automático](docs/modelado/01_ML/ML_REGOVA.png)

## Tecnologías y versiones

| Componente | Versión o configuración |
|---|---|
| Python | 3.13 |
| Node.js | 24 en la imagen de compilación |
| FastAPI | 0.162.0 en el entorno de la aplicación |
| React | 19.3.1 |
| TypeScript | 6.0.3 |
| PostgreSQL | 17 en Docker. El backend también documenta pruebas en PostgreSQL 18 |
| Modelo de detección | YOLOv8n con Ultralytics 8.3.159 en el entorno de inferencia |
| OpenCV | 4.12.0.88 en inferencia y `opencv-python-headless` 5.0.0.93 en la aplicación |
| Autenticación y permisos | Argon2id y control de acceso basado en roles |
| Reportes PDF | ReportLab 5.1.0 |
| Pruebas | Vitest para el frontend y pytest para el backend |
| Contenedores | Docker con Compose v2 según la guía del proyecto. Docker Engine sin versión fijada |

Las versiones se pueden consultar en [`package-lock.json`](package-lock.json), [`backend/requirements-app.lock.txt`](backend/requirements-app.lock.txt), [`backend/requirements-inference.lock.txt`](backend/requirements-inference.lock.txt), [`Dockerfile`](Dockerfile) y [`compose.yaml`](compose.yaml).

## Instalación con Docker

Se requiere Docker con Compose y un host Linux x86-64 o Docker Desktop en modo Linux. Si recibiste el proyecto como ZIP, extráelo y abre PowerShell en la carpeta que contiene `compose.yaml`.

1. Crea la configuración local.

   ```powershell
   Copy-Item .env.docker.example .env.docker
   ```

2. Edita `.env.docker` y define `POSTGRES_PASSWORD`, `REGOVA_DB_PASSWORD` y `REGOVA_ADMIN_PASSWORD`. La contraseña de administración debe tener al menos 10 caracteres. Configura `REGOVA_CHECKPOINT` con la ruta al archivo `best.pt` entrenado. Si descargaste el ZIP para GitHub, consigue los pesos por separado.

3. Construye la aplicación e inicia los servicios.

   ```powershell
   docker compose --env-file .env.docker build app
   docker compose --env-file .env.docker up -d
   docker compose --env-file .env.docker ps -a
   ```

4. Comprueba que la aplicación responde.

   ```powershell
   Invoke-RestMethod http://localhost:8011/api/ready
   ```

Consulta [`DOCKER.md`](DOCKER.md) para la configuración de correo, los volúmenes y los comandos de diagnóstico. Para la instalación local en Windows, sigue el [manual de instalación](Manual_de_instalacion_REGOVA.md).

## Uso

Abre [REGOVA](http://localhost:8011) e inicia sesión con el usuario `ADM-001` y la contraseña definida en `REGOVA_ADMIN_PASSWORD`. Desde la interfaz puedes cargar una fotografía de góndola, ejecutar un análisis y consultar los resultados.

La documentación interactiva de la API está en [Swagger UI](http://localhost:8011/api/docs).

## Desarrollo y pruebas

Desde la raíz del proyecto, instala las dependencias y ejecuta las pruebas del frontend.

```powershell
npm ci
npm test
```

Usa `npm run dev` para iniciar Vite en modo desarrollo o `npm run build` para compilar el frontend.

Para las pruebas del backend, activa el entorno de Python con las dependencias de prueba e inicia pytest desde `backend`.

```powershell
Push-Location backend
python -m pytest
Pop-Location
```

Las pruebas de integración con PostgreSQL requieren una base desechable cuyo nombre termine en `_TEST`, configurada mediante `REGOVA_TEST_DSN`. Consulta la [documentación del backend](backend/API_REGOVA.md) para preparar ese entorno.

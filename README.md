# REGOVA — Regiones de Góndola para Valoración de Ausencias

![Python](https://img.shields.io/badge/python-3.13-blue?logo=python)  ![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi)  ![React](https://img.shields.io/badge/React-19.0.0-61DAFB?logo=react)  ![TypeScript](https://img.shields.io/badge/TypeScript-5.5.2-blue?logo=typescript)  ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql)  ![YOLOv8](https://img.shields.io/badge/YOLOv8-n-FF6F61) ![OpenCV](https://img.shields.io/badge/OpenCV-4.10.0-5C3EE8?logo=opencv)  ![Docker](https://img.shields.io/badge/Docker-24.0.6-2496ED?logo=docker)  ![License](https://img.shields.io/badge/License-MIT-green)

## 📖 Descripción del proyecto

**REGOVA** es un sistema de IA de stack completo que detecta góndolas vacías en tiendas minoristas y brinda información accionable para reducir situaciones de stock‑out. Combina modelos de visión por computadora, un backend FastAPI y una interfaz React/TypeScript para ofrecer alertas y reportes en tiempo real.

## 🎯 Problema

Los retailers pierden ingresos cuando los estantes están vacíos (out‑of‑stock). Las revisiones manuales son costosas y propensas a errores. REGOVA automatiza la detección, cuantifica el impacto y ayuda al personal a priorizar la reposición.

## 🚀 Solución

- **Pipeline de visión** – YOLOv8n + OpenCV procesa imágenes de los estantes capturadas por cámaras de bajo costo.  
- **API Backend** – FastAPI (Python 3.13) orquesta la inferencia, guarda los resultados en PostgreSQL y sirve datos a la UI.  
- **Frontend** – React 19 + TypeScript muestra tableros, alertas y exportación de reportes.  
- **Seguridad** – Hashing Argon2id, control de acceso basado en roles (RBAC).  
- **Reportes** – Generación de PDFs con ReportLab, pruebas automatizadas y pipelines CI.

### Diagrama de arquitectura

*(Añade aquí tu diagrama de arquitectura)*  

`![Diagrama MER](docs/modelado/02_MER/MER_REGOVA_Completo.png)`  

`![Diagrama de flujo ML](docs/modelado/01_ML/ML_REGOVA.png)`

## 🛠️ Tecnologías usadas

| Capa | Tecnologías | Versión | Badge |
|------|-------------|---------|-------|
| **Lenguaje** | Python | 3.13 | ![Python](https://img.shields.io/badge/python-3.13-blue?logo=python) |
| | TypeScript / JavaScript | 5.5 / 19 | ![TypeScript](https://img.shields.io/badge/TypeScript-5.5.2-blue?logo=typescript) |
| | SQL (PostgreSQL) | 18 | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql) |
| | Bash / PowerShell (scripts) | – | |
| **Frameworks** | FastAPI | 0.115.0 | ![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi) |
| | React | 19.0.0 | ![React](https://img.shields.io/badge/React-19.0.0-61DAFB?logo=react) |
| **IA / CV** | YOLOv8n (PyTorch) | n | ![YOLOv8](https://img.shields.io/badge/YOLOv8-n-FF6F61) |
| | OpenCV | 4.10.0 | ![OpenCV](https://img.shields.io/badge/OpenCV-4.10.0-5C3EE8?logo=opencv) |
| **Base de datos** | PostgreSQL | 18 | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql) |
| **Contenedores** | Docker | 24.0.6 | ![Docker](https://img.shields.io/badge/Docker-24.0.6-2496ED?logo=docker) |
| **Seguridad** | Argon2id | – | |
| **Reportes** | ReportLab | – | |
| **Testing** | pytest (Python) | – | |
| | JUnit (Java) | – | |
| **CI / Automatización** | GitHub Actions | – | |

## 📦 Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/REGOVA.git
cd REGOVA

# Backend (Python)
python -m venv venv
.\venv\Scripts\activate   # PowerShell en Windows
pip install -r requirements.txt

# Configurar PostgreSQL
# (Crear una base de datos llamada regova y ejecutar los scripts de migración en docs/db/)

# Frontend (Node.js)
npm install               # npm >= 10, o pnpm (instalar fuera del sandbox si es necesario)
npm run build             # genera los assets en /dist

# Opcional: entorno con Docker
docker compose up -d
```

### Variables de entorno

Crea un archivo `.env` en la raíz del proyecto (ejemplo):

```
POSTGRES_USER=regova_user
POSTGRES_PASSWORD=contraseña_fuerte
POSTGRES_DB=regova
FASTAPI_HOST=0.0.0.0
FASTAPI_PORT=8000
SECRET_KEY=tu_clave_secreta
```

## ▶️ Uso

```bash
# Iniciar el backend FastAPI
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Servir el frontend (desarrollo)
npm start
```

- Accede a `http://localhost:3000` para ver el tablero.  
- La documentación de la API está disponible en `http://localhost:8000/docs`.  
- Usa la UI para cargar imágenes de góndolas, ver resultados de detección y exportar reportes PDF.

## ✅ Pruebas

```bash
# Pruebas del backend
pytest tests/backend

# Pruebas del frontend
npm run test
```

Las acciones de CI ejecutan estas pruebas en cada push.


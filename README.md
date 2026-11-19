# REGOVA — Regiones de Góndola para Valoración de Ausencias

![Python](https://img.shields.io/badge/python-3.13-blue?logo=python)  
![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi)  
![React](https://img.shields.io/badge/React-19.0.0-61DAFB?logo=react)  
![TypeScript](https://img.shields.io/badge/TypeScript-5.5.2-blue?logo=typescript)  
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql)  
![YOLOv8](https://img.shields.io/badge/YOLOv8-n-FF6F61)  
![OpenCV](https://img.shields.io/badge/OpenCV-4.10.0-5C3EE8?logo=opencv)  
![Docker](https://img.shields.io/badge/Docker-24.0.6-2496ED?logo=docker)  
![License](https://img.shields.io/badge/License-MIT-green)

## 📖 Project Overview

**REGOVA** is a full‑stack AI‑powered system that detects empty gondola shelves in retail stores and provides actionable insights to reduce out‑of‑stock situations. It combines computer‑vision models, a FastAPI backend, and a React/TypeScript frontend to deliver real‑time alerts and reporting.

## 🎯 Problem Statement

Retailers lose revenue when product shelves are empty (out‑of‑stock). Manual shelf checks are costly and error‑prone. REGOVA automates detection, quantifies the impact, and helps staff prioritize restocking.

## 🚀 Solution Overview

- **Computer‑vision pipeline** – YOLOv8n + OpenCV processes shelf images captured by low‑cost cameras.
- **Backend API** – FastAPI (Python 3.13) orchestrates model inference, stores results in PostgreSQL, and serves data to the UI.
- **Frontend** – React 19 + TypeScript provides dashboards, alerts, and exportable reports.
- **Security** – Argon2id password hashing, RBAC for role‑based access.
- **Reporting** – PDF generation via ReportLab, automated test suites, and CI pipelines.

### Architecture Diagram

*(Add your architecture diagram here)*  

`![MER Diagram](docs/modelado/02_MER/MER_REGOVA_Completo.png)`  

`![ML Pipeline Diagram](docs/modelado/01_ML/ML_REGOVA.png)`

## 🛠️ Technology Stack

| Layer | Technology | Version | Badge |
|-------|------------|---------|-------|
| **Language** | Python | 3.13 | ![Python](https://img.shields.io/badge/python-3.13-blue?logo=python) |
| | TypeScript / JavaScript | 5.5 / 19 | ![TypeScript](https://img.shields.io/badge/TypeScript-5.5.2-blue?logo=typescript) |
| | SQL (PostgreSQL) | 18 | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql) |
| | Bash / PowerShell (scripts) | – | |
| **Frameworks** | FastAPI | 0.115.0 | ![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi) |
| | React | 19.0.0 | ![React](https://img.shields.io/badge/React-19.0.0-61DAFB?logo=react) |
| **AI / CV** | YOLOv8n (PyTorch) | n | ![YOLOv8](https://img.shields.io/badge/YOLOv8-n-FF6F61) |
| | OpenCV | 4.10.0 | ![OpenCV](https://img.shields.io/badge/OpenCV-4.10.0-5C3EE8?logo=opencv) |
| **Databases** | PostgreSQL | 18 | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0-336791?logo=postgresql) |
| **Containerisation** | Docker | 24.0.6 | ![Docker](https://img.shields.io/badge/Docker-24.0.6-2496ED?logo=docker) |
| **Security** | Argon2id | – | |
| **Reporting** | ReportLab | – | |
| **Testing** | pytest (Python) | – | |
| | JUnit (Java) | – | |
| **CI / Automation** | GitHub Actions | – | |

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/your‑username/REGOVA.git
cd REGOVA

# Backend (Python)
python -m venv venv
.\venv\Scripts\activate   # Windows PowerShell
pip install -r requirements.txt

# Set up PostgreSQL
# (Create a database named regova and run the migration scripts in docs/db/)

# Frontend (Node.js)
npm install               # npm >= 10, or use pnpm (install outside sandbox if needed)
npm run build             # creates production assets in /dist

# Optional Docker setup
docker compose up -d
```

### Environment variables

Create a `.env` file in the project root (example):

```
POSTGRES_USER=regova_user
POSTGRES_PASSWORD=strong_password
POSTGRES_DB=regova
FASTAPI_HOST=0.0.0.0
FASTAPI_PORT=8000
SECRET_KEY=your_secret_key
```

## ▶️ Usage

```bash
# Start the FastAPI backend
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Serve the frontend (development)
npm start
```

- Open `http://localhost:3000` to view the dashboard.
- API docs are available at `http://localhost:8000/docs`.
- Use the UI to upload shelf images, view detection results, and export PDF reports.

## ✅ Testing

```bash
# Backend tests
pytest tests/backend

# Frontend tests
npm run test
```

Continuous integration runs the above on every push.

## 🤝 Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/awesome‑feature`.
3. Follow the code style guidelines (`black`, `prettier`, `flake8`).
4. Write tests for new functionality.
5. Open a Pull Request with a clear description.

Please see `CONTRIBUTING.md` for detailed guidelines.

## 📄 License

This project is licensed under the **MIT License** – see the `LICENSE` file for details.

## 📧 Contact

- **Project Lead:** [Your Name] – `your.email@example.com`
- **Affiliation:** Duoc UC – Retail Innovation Lab
- **Client:** Walmart Chile

---

*Feel free to open issues or submit pull requests for any improvements or bug fixes!*

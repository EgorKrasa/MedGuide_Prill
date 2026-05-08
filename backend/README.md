# PRILL Backend (FastAPI + PostgreSQL)

API для дипломного приложения **«Справочник лекарственных препаратов»** с поиском по симптомам.

## Эндпоинты

- `GET /health` — проверка работоспособности
- `GET /symptoms?query=каш&limit=10` — подсказки симптомов
- `GET /drugs?symptoms=кашель&symptoms=температура` — поиск препаратов по симптомам (логика AND)
- `GET /drugs/{id}` — детали препарата
- `POST /admin/seed?mobile_assets_path=../mobile/assets/drugs.json` — заполнить БД демо-данными

## Запуск без Docker (Windows)

1) Поставь PostgreSQL и создай БД/пользователя (например `prill/prill`).
2) В `backend/.env` укажи строку подключения:

```env
DATABASE_URL=postgresql+psycopg://prill:prill@localhost:5432/prill
CORS_ORIGINS=*
```

3) Установи зависимости и запусти:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

4) Один раз заполни демо-данными:

```powershell
Invoke-RestMethod -Method Post "http://127.0.0.1:8000/admin/seed"
```

## Запуск через Docker (если установишь Docker Desktop)

В корне проекта:

```bash
docker compose up --build
```

Потом сидирование:

```bash
curl -X POST "http://127.0.0.1:8000/admin/seed"
```

# DEPLOY_RENDER.md

Крч рабочий чеклист, как вынести PRILL в интернет и не ломать запуск на других устройствах.

## 1) Что используем (free/почти free)

- Backend: **Render Web Service**
- База: **Render Postgres** или **Neon Postgres**
- Фото: **Cloudflare R2** (или Supabase Storage)

## 2) Backend деплой на Render

1. Пушим репозиторий на GitHub.
2. В Render: **New + > Blueprint** (возьмёт `render.yaml`)  
   или **New Web Service** с root `backend`.
3. Старт-команда:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

4. ENV в Render:
- `DATABASE_URL` = строка подключения к Postgres
- `CORS_ORIGINS` = `*` (или домены фронта через запятую)
- `SEED_ADMIN_TOKEN` = случайная длинная строка
- `IMAGE_BASE_URL` = публичная папка с фото, например `https://cdn.example.com/prill/drugs`

5. Проверка:
- `GET https://<service>.onrender.com/health` -> `{"status":"ok"}`

## 3) Сидирование production (один раз)

Вызов только с токеном:

```bash
POST /admin/seed?token=<SEED_ADMIN_TOKEN>
```

Пример PowerShell:

```powershell
Invoke-RestMethod -Method Post "https://<service>.onrender.com/admin/seed?token=<SEED_ADMIN_TOKEN>"
```

## 4) Фото в облаке

Текущая схема приложения: фото по номеру `1..40`.

Загружаем в cloud storage файлы:
- `1.jpg`
- `2.jpg`
- ...
- `40.jpg`

`IMAGE_BASE_URL` должен указывать на директорию, где лежат эти файлы.
Тогда API отдаст `image_url`, а Flutter попробует сначала удалённое фото, затем локальный fallback.

## 5) Запуск с другого ПК/телефона

### Web (prod URL)

```powershell
set PRILL_API_URL=https://<service>.onrender.com
.\scripts\run_mobile_prod.bat
```

### APK (prod URL)

```powershell
set PRILL_API_URL=https://<service>.onrender.com
.\scripts\build_apk_prod.bat
```

APK: `mobile\build\app\outputs\flutter-apk\app-release.apk`

## 6) Как ведёт себя офлайн

- Есть интернет -> тянет API/фото с сервера
- Нет интернета -> читает кэш последних ответов API
- Если и кэша нет -> fallback на `mobile/assets/drugs.json`
- Избранное/профиль остаются локально в `SharedPreferences`

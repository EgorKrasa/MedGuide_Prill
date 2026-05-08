# PRILL — как я это запускаю (Windows)

Крч это мой дипломный справочник лекарств, стек такой: **Flutter (web/Android) + FastAPI + PostgreSQL**. Записал сюда шаги, чтобы самому не забыть, ну типа шпаргалка.

Само приложение по умолчанию берёт каталог из **`mobile/assets/drugs.json`** внутри сборки — **сервер не обязателен** (удобно для web и **APK**).  
Если хочу remote API (prod), ставлю `PRILL_API_URL` и всё работает с интернета.

Коротко по режимам:

- **dev (локальный API):**
  - `cd .\mobile`
  - `flutter run -d chrome --dart-define=PRILL_API_URL=http://127.0.0.1:8000`
- **prod (удаленный API):**
  - `cd .\mobile`
  - `flutter run -d chrome --dart-define=PRILL_API_URL=https://<твой-render-url>`
- **prod APK:**
  - `cd .\mobile`
  - `flutter build apk --release --dart-define=PRILL_API_URL=https://<твой-render-url>`

Полный деплой в интернет: см. `DEPLOY_RENDER.md`.

Если вдруг снова хочу жить от локального FastAPI — запускаю backend и собираю/запускаю так:

`flutter run -d chrome --dart-define=PRILL_API_URL=http://127.0.0.1:8000`

Потом хочу интерфейс поинтереснее / разнообразить — это отдельно, не в этом файле.

---

## 1) Что у меня вообще должно стоять

- PostgreSQL локально
- Python 3.11+ (или 3.10+, ну как пойдёт)
- Flutter SDK
- Google Chrome (для web)

---

## 2) `.env` у backend — проверить не забыть

Файл: `backend/.env`

```env
DATABASE_URL=postgresql+psycopg://postgres:ТВОЙ_ПАРОЛЬ@localhost:5432/postgres
CORS_ORIGINS=*
SEED_ADMIN_TOKEN=
IMAGE_BASE_URL=
```

---

## 3) Нормальный запуск (то, что обычно работает)

### Шаг A. Backend

Первое окно PowerShell:

```powershell
cd .\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

В браузере глянуть:

`http://127.0.0.1:8000/health`

Должно быть типа:

```json
{"status":"ok"}
```

### Шаг B. Залить данные в БД (seed)

**Только если** крутишь Postgres + backend. Сначала шаг A должен работать (в браузере открывается `/health`). Иначе `Invoke-RestMethod` даст *«Невозможно соединиться с удаленным сервером»* — это не баг, сервер просто не запущен.

Второе окно PowerShell (из корня `prill`):

```powershell
Invoke-RestMethod -Method Post "http://127.0.0.1:8000/admin/seed"
```

В ответе что-то вроде `inserted_drugs ... inserted_symptoms ...` и `catalog_replaced: true` — норм.

Для Flutter **без** `PRILL_API_URL` seed **не обязателен** — каталог и так из `assets/drugs.json`.

Каждый `/admin/seed` у меня **полностью чистит** препараты и симптомы в Postgres и заливает заново из `mobile/assets/drugs.json`, крч если в БД был мусор — после seed его не должно быть.

Если JSON руками крутил или `generate_catalog.py` менял — опять seed. Пересобрать JSON:

```powershell
python scripts/generate_catalog.py
```

### Шаг C. Flutter в Chrome

Третье окно:

```powershell
cd .\mobile
flutter config --enable-web
flutter pub get
flutter run -d chrome
```

Если в браузере после сидирования всё ещё тянутся старые названия — зайди в `mobile`, ну вот так:

`flutter clean`, потом снова `flutter pub get` и `flutter run -d chrome`.

---

## 3.1) APK под Android (release)

Перед сборкой APK на новом ПК:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Если ругается на `No Android SDK found` — ставь Android Studio + Android SDK (platform-tools, build-tools, command-line tools), потом снова `flutter doctor`.

Из папки `mobile`:

```powershell
cd .\mobile
flutter pub get
flutter build apk --release --dart-define=PRILL_API_URL=https://prill-api.onrender.com
```

Файл обычно тут: `mobile\build\app\outputs\flutter-apk\app-release.apk`.
В `android` сейчас release может быть на debug-ключах — для магазина потом нормальная подпись, крч это отдельная история.

---

## 4) Таблицы в Postgres снёс — не страшно

1. Backend остановить (`Ctrl+C`).
2. Снова поднять:

```powershell
cd .\backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

При старте само создаст `drugs`, `symptoms`, `drug_symptoms`.

3. Опять seed:

```powershell
cd C:\Users\Егор\Desktop\prill
Invoke-RestMethod -Method Post "http://127.0.0.1:8000/admin/seed"
```

Если `Internal Server Error` — смотри traceback в окне backend, там причина.

---

## 5) Частые косяки

### `Невозможно соединиться с удаленным сервером` (seed)

Не запущен `uvicorn` в другом окне или упал с ошибкой. Сначала шаг 3A, потом seed. Либо вообще не делаю seed, если приложение только с локальным JSON.

### В путь скопировались угловые скобки `<ТВОЙ_...>`

Так **нельзя**: PowerShell ругается на путь. Либо свой реальный путь (`C:\Users\Егор\...`), либо из корня проекта: `cd .\mobile`, `cd .\backend` — см. INSTALL_WINDOWS.md.

### `No pubspec.yaml file found`

Я не в той папке сижу. Надо:

```powershell
cd .\mobile
flutter run -d chrome
```

или из корня `prill`: `cd .\mobile`

### В cmd батник орёт: `"flutter" не является внутренней или внешней командой`

cmd не видит Flutter в PATH. Я просто через PowerShell делаю как в разделе 3 — в общем работает.

### `Internal Server Error` на `/admin/seed`

Обычно backend не перезапускал после схемы / дрочки с таблицами. Раздел 4 по кругу.

---

## 6) На защите — коротко что показать

1. PowerShell #1 — backend.
2. PowerShell #2 — `POST /admin/seed`.
3. PowerShell #3 — `flutter run -d chrome`.
4. Поиск по симптомам, список, карточка с ценой — и всё вроде.

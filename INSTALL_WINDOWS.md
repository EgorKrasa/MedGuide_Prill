# INSTALL_WINDOWS.md

Записал для себя: как поднять **PRILL** на новом винде с нуля. Команды оставил как есть, текст — по-человечески.

**Важно:** в консоль **нельзя** копировать путь с угловыми скобками вроде `C:\Users\<ТВОЙ_ПОЛЬЗОВАТЕЛЬ>\...` — PowerShell воспринимает `<` `>` как недопустимые символы. Либо подставляешь своё имя папки (`Егор` и т.д.), либо открываешь PowerShell **уже из корня проекта** (папка `prill`, где лежат `backend` и `mobile`) и используешь команды ниже с `.\` — там скобок нет.

## 1. Что поставить

По очереди, крч так удобнее:

1. **PostgreSQL** (+ pgAdmin 4 в установщике)
2. **Python 3.11+**
3. **Flutter SDK**
4. **Google Chrome**

---

## 2. PostgreSQL + pgAdmin

1. [https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)
2. Инсталлер EDB, дальше по умолчанию: сервер, pgAdmin, порт **5432**
3. Пароль для `postgres` — записать куда-нибудь, он потом в `.env` пойдёт
4. Stack Builder можно просто закрыть, не обязателен

---

## 3. Где лежит проект

Пример полного пути у себя на диске: `C:\Users\Егор\Desktop\prill` (у тебя имя пользователя может быть другое).

Дальше везде считаю, что в PowerShell ты уже сделал `cd` в **корень** этой папки `prill` (рядом должны быть каталоги `backend`, `mobile`, `scripts`).

---

## 4. `.env` для backend

Создать файл `backend\.env` (внутри папки backend в проекте).

Внутри:

```env
DATABASE_URL=postgresql+psycopg://postgres:ТВОЙ_ПАРОЛЬ_POSTGRES@localhost:5432/postgres
CORS_ORIGINS=*
SEED_ADMIN_TOKEN=
IMAGE_BASE_URL=
```

`ТВОЙ_ПАРОЛЬ_POSTGRES` — пароль postgres при установке (это не путь, в консоль кавычки не нужны).

---

## 5. Первый запуск backend

PowerShell **окно #1**, текущая папка = **корень `prill`**:

```powershell
cd .\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Пока это окно работает и в логе нет ошибки — порт 8000 занят backend.

Проверка: в браузере `http://127.0.0.1:8000/health` → должно быть:

```json
{"status":"ok"}
```

---

## 6. Seed — залить данные

**Окно #2** (лучше новое окно PowerShell). Перейти в **корень `prill`** (где лежат `backend` и `mobile`), не оставаться внутри `backend`:

```powershell
Invoke-RestMethod -Method Post "http://127.0.0.1:8000/admin/seed"
```

Если пишешь **«Невозможно соединиться с удаленным сервером»** — в первом окне **нет** запущенного `uvicorn` (или упал с ошибкой). Сначала шаг 5, потом снова seed.

В ответе `inserted_drugs`, `inserted_symptoms` и т.д. — ок.

---

## 7. Flutter в браузере

**Окно #3**, **корень `prill`**:

```powershell
cd .\mobile
flutter config --enable-web
flutter pub get
flutter run -d chrome
```

Если было `No pubspec.yaml` — ты не в папке `mobile`, сделай `cd .\mobile` из корня проекта.

Chrome откроется сам.

---

## 8. pgAdmin — глянуть таблицы

1. pgAdmin 4
2. Servers → PostgreSQL → Databases → postgres → Schemas → public → Tables
3. Должны жить: `drugs`, `symptoms`, `drug_symptoms`

---

## 9. Таблицы удалили — повтор

1. Backend стоп (`Ctrl+C`) в #1
2. Корень `prill`, потом:

```powershell
cd .\backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

3. Другое окно, корень `prill`:

```powershell
Invoke-RestMethod -Method Post "http://127.0.0.1:8000/admin/seed"
```

---

## 10. Ошибки, которые я уже ловил

### `No pubspec.yaml file found`

Не та папка:

```powershell
cd .\mobile
```

### `"flutter" не является внутренней или внешней командой`

PATH не видит Flutter — проверить установку, перезапустить PowerShell, ну или снова в PATH добавить.

### `Internal Server Error` на `/admin/seed`

Смотреть лог в окне backend. Часто помогает: перезапуск uvicorn + ещё раз seed.

### `Невозможно соединиться с удаленным сервером` на seed

Backend не запущен или не слушает 8000 — см. раздел 5.

---

## 11. APK

Каталог вшит в **assets**, для обычного APK сервер не нужен. Корень `prill`, потом:

```powershell
cd .\mobile
flutter pub get
flutter build apk --release
```

Файл: `mobile\build\app\outputs\flutter-apk\app-release.apk`. Про `PRILL_API_URL` если снова хочу API — в основном README.

---

## 12. Режим prod с удаленным сервером

Если backend уже в интернете (например Render):

```powershell
cd .\mobile
flutter run -d chrome --dart-define=PRILL_API_URL=https://<твой-render-url>
```

APK с удаленным API:

```powershell
cd .\mobile
flutter build apk --release --dart-define=PRILL_API_URL=https://<твой-render-url>
```

Подробный деплой backend/db/storage: см. `DEPLOY_RENDER.md`.

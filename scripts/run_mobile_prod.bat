@echo off
setlocal
if "%PRILL_API_URL%"=="" (
  set "PRILL_API_URL=https://YOUR-RENDER-SERVICE.onrender.com"
)
cd /d "%~dp0..\mobile"
flutter pub get
flutter run -d chrome --dart-define=PRILL_API_URL=%PRILL_API_URL%

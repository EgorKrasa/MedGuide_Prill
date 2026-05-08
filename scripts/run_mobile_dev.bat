@echo off
setlocal
cd /d "%~dp0..\mobile"
flutter pub get
flutter run -d chrome --dart-define=PRILL_API_URL=http://127.0.0.1:8000

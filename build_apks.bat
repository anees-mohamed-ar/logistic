@echo off
cd /d "%~dp0"
echo Building APKs for both companies...

echo.
echo Building Sri Krishna Cargo Corporation APK (ID: 7)...
flutter build apk --flavor cargo --release
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build Cargo APK
    exit /b %ERRORLEVEL%
)
echo Cargo APK built successfully!

echo.
echo Building Sri Krishna Carrying Corporation APK (ID: 6)...
flutter build apk --flavor carrying --release
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build Carrying APK
    exit /b %ERRORLEVEL%
)
echo Carrying APK built successfully!

echo.
echo Both APKs built successfully!
echo.
echo APK locations:
echo - Cargo APK: build\app\outputs\flutter-apk\app-cargo-release.apk
echo - Carrying APK: build\app\outputs\flutter-apk\app-carrying-release.apk
echo.

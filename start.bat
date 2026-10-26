@echo off
setlocal DisableDelayedExpansion

if not defined CFX_SERVER_KEY (
    echo CFX_SERVER_KEY is required. Set it in the server environment before starting.
    exit /b 1
)

set "FXSERVER_EXE=%~dp0..\..\artifacts\FXServer.exe"
if not exist "%FXSERVER_EXE%" (
    echo FXServer.exe was not found in the artifacts directory.
    exit /b 1
)

start "" /D "%~dp0" "%FXSERVER_EXE%" +set sv_licenseKey "%CFX_SERVER_KEY%" +set steam_webApiKey "%STEAM_WEB_API_KEY%" +set interior_city_webhook_logs "%INTERIOR_CITY_WEBHOOK_LOGS%" +set interior_city_webhook_bugs "%INTERIOR_CITY_WEBHOOK_BUGS%" +exec config/config.cfg +set onesync_enableInfinity 0 +set onesync on +set sv_enforceGameBuild 2612

@echo off
setlocal DisableDelayedExpansion

if exist "%~dp0.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0.env") do (
        if /I "%%A"=="CFX_SERVER_KEY" if not defined CFX_SERVER_KEY set "CFX_SERVER_KEY=%%B"
        if /I "%%A"=="MYSQL_CONNECTION_STRING" if not defined MYSQL_CONNECTION_STRING set "MYSQL_CONNECTION_STRING=%%B"
        if /I "%%A"=="STEAM_WEB_API_KEY" if not defined STEAM_WEB_API_KEY set "STEAM_WEB_API_KEY=%%B"
        if /I "%%A"=="INTERIOR_CITY_WEBHOOK_LOGS" if not defined INTERIOR_CITY_WEBHOOK_LOGS set "INTERIOR_CITY_WEBHOOK_LOGS=%%B"
        if /I "%%A"=="INTERIOR_CITY_WEBHOOK_BUGS" if not defined INTERIOR_CITY_WEBHOOK_BUGS set "INTERIOR_CITY_WEBHOOK_BUGS=%%B"
    )
)

if not defined CFX_SERVER_KEY (
    echo CFX_SERVER_KEY is required. Set it in .env or the server environment before starting.
    exit /b 1
)

if not defined MYSQL_CONNECTION_STRING (
    echo MYSQL_CONNECTION_STRING is required. Set it in .env or the server environment before starting.
    exit /b 1
)

set "FXSERVER_EXE=%~dp0..\..\artifacts\FXServer.exe"
if not exist "%FXSERVER_EXE%" (
    echo FXServer.exe was not found in the artifacts directory.
    exit /b 1
)

start "" /D "%~dp0" "%FXSERVER_EXE%" +set sv_licenseKey "%CFX_SERVER_KEY%" +set mysql_connection_string "%MYSQL_CONNECTION_STRING%" +set steam_webApiKey "%STEAM_WEB_API_KEY%" +set interior_city_webhook_logs "%INTERIOR_CITY_WEBHOOK_LOGS%" +set interior_city_webhook_bugs "%INTERIOR_CITY_WEBHOOK_BUGS%" +exec config/config.cfg

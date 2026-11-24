@echo off
cd /d "%~dp0"
echo ===-------------------------------===
echo --
echo -    Interior City 
echo -   --   
echo ===-------------------------------===

REM Preserva o cache para evitar reprocessar todos os mapas e veiculos.

cls
color 0c  
start "" ".\build\FXServer.exe" +set onesync on +set onesync_population true +set sv_enforceGameBuild 3407 +exec config/config.cfg
exit
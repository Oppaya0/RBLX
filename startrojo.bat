@echo off
cd /d "%~dp0"
echo Starting Rojo server for project: %CD%
rojo serve
pause
@echo off
title MediClinic - Backend Python
cd /d "%~dp0backend_python"
if not exist .env copy .env.example .env
echo Instalando dependencias de Python...
python -m pip install -r requirements.txt
echo.
echo Iniciando MediClinic en http://127.0.0.1:4000
echo Si abre correctamente, prueba tambien http://127.0.0.1:4000/api/health
echo.
python -m uvicorn main:app --reload --host 127.0.0.1 --port 4000
pause

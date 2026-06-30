@echo off
title TramDoc Backend Services
echo ============================================
echo   TramDoc Backend - Auto Start
echo ============================================
echo.

:: 1. Start Spring Boot Backend
echo [1/2] Starting Spring Boot Backend...
cd /d D:\Reading_Station\Backend
start "" mvn spring-boot:run
echo       Spring Boot starting on port 8080...
echo.

:: 2. Start Cloudflare Tunnel
echo [2/2] Starting Cloudflare Tunnel...
start "" d:\Reading_Station\cloudflared.exe tunnel run tramdoc
echo       Tunnel starting...
echo.

echo ============================================
echo   All services started!
echo   API: https://tramdoc-api.dichvu.cloud
echo ============================================
echo.
echo Press any key to stop all services...
pause >nul

:: Cleanup
echo Stopping services...
taskkill /F /IM java.exe >nul 2>&1
taskkill /F /IM cloudflared.exe >nul 2>&1
echo Done.

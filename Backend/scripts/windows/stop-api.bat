@echo off
TITLE Stop Tram Doc API

echo ============================================
echo Stopping Tram Doc API Server...
echo ============================================
echo.

:: Find and kill Java process running the JAR
SET FOUND=0
FOR /F "tokens=2" %%p IN ('wmic process where "commandline like '%%tram-doc-backend%%'" get processid 2^>nul ^| findstr /r "[0-9]"') DO (
    echo Found process ID: %%p
    taskkill /F /PID %%p
    SET FOUND=1
)

IF %FOUND%==0 (
    echo No running Tram Doc API process found.
) ELSE (
    echo.
    echo API Server stopped successfully!
)

echo.
pause

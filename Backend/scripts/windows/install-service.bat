@echo off
:: ============================================
:: Install Tram Doc API as Windows Service
:: Requires NSSM (Non-Sucking Service Manager)
:: Download from: https://nssm.cc/download
:: ============================================

TITLE Install Tram Doc API Service

:: Check if running as Administrator
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] This script requires Administrator privileges!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Configuration
SET SERVICE_NAME=TramdocAPI
SET APP_HOME=C:\Apps\TramdocAPI
SET JAVA_EXE=C:\Program Files\Eclipse Adoptium\jdk-17.0.13+11\bin\java.exe
SET JAR_FILE=%APP_HOME%\app\tram-doc-backend-1.0.0.jar
SET CONFIG_FILE=%APP_HOME%\config\application-prod.properties
SET NSSM_PATH=C:\Tools\nssm\win64\nssm.exe

echo ============================================
echo Tram Doc API - Windows Service Installer
echo ============================================
echo.

:: Check NSSM exists
IF NOT EXIST "%NSSM_PATH%" (
    echo [ERROR] NSSM not found at: %NSSM_PATH%
    echo.
    echo Please download NSSM from: https://nssm.cc/download
    echo Extract to: C:\Tools\nssm\
    echo.
    pause
    exit /b 1
)

:: Check Java exists
IF NOT EXIST "%JAVA_EXE%" (
    echo [WARNING] Java not found at default path: %JAVA_EXE%
    echo Please update JAVA_EXE variable in this script.
    echo.
    SET /P JAVA_EXE="Enter full path to java.exe: "
)

:: Check if service already exists
sc query %SERVICE_NAME% >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo [WARNING] Service %SERVICE_NAME% already exists!
    SET /P CONFIRM="Do you want to remove and reinstall? (Y/N): "
    IF /I "%CONFIRM%"=="Y" (
        echo Removing existing service...
        "%NSSM_PATH%" stop %SERVICE_NAME%
        "%NSSM_PATH%" remove %SERVICE_NAME% confirm
    ) ELSE (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)

:: Install service
echo.
echo Installing service: %SERVICE_NAME%
echo ============================================

"%NSSM_PATH%" install %SERVICE_NAME% "%JAVA_EXE%"
"%NSSM_PATH%" set %SERVICE_NAME% AppDirectory "%APP_HOME%"
"%NSSM_PATH%" set %SERVICE_NAME% AppParameters "-Xms256m -Xmx512m -Dspring.config.location=file:%CONFIG_FILE% -Dfile.encoding=UTF-8 -jar %JAR_FILE%"
"%NSSM_PATH%" set %SERVICE_NAME% DisplayName "Tram Doc API Server"
"%NSSM_PATH%" set %SERVICE_NAME% Description "Backend API for Tram Doc Reading Station Application"
"%NSSM_PATH%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM_PATH%" set %SERVICE_NAME% AppStdout "%APP_HOME%\logs\service-stdout.log"
"%NSSM_PATH%" set %SERVICE_NAME% AppStderr "%APP_HOME%\logs\service-stderr.log"
"%NSSM_PATH%" set %SERVICE_NAME% AppStdoutCreationDisposition 4
"%NSSM_PATH%" set %SERVICE_NAME% AppStderrCreationDisposition 4
"%NSSM_PATH%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM_PATH%" set %SERVICE_NAME% AppRotateBytes 10485760

echo.
echo ============================================
echo Service installed successfully!
echo ============================================
echo.
echo Service Name: %SERVICE_NAME%
echo.
echo Commands:
echo   Start:   net start %SERVICE_NAME%
echo   Stop:    net stop %SERVICE_NAME%
echo   Status:  sc query %SERVICE_NAME%
echo.

SET /P START_NOW="Do you want to start the service now? (Y/N): "
IF /I "%START_NOW%"=="Y" (
    net start %SERVICE_NAME%
    echo.
    sc query %SERVICE_NAME%
)

echo.
pause

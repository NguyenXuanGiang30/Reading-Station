@echo off
TITLE Tram Doc API Server

:: ============================================
:: CONFIGURATION
:: ============================================
SET APP_NAME=Tram Doc API
SET APP_HOME=C:\Apps\TramdocAPI
SET JAR_FILE=%APP_HOME%\app\tram-doc-backend-1.0.0.jar
SET CONFIG_FILE=%APP_HOME%\config\application-prod.properties
SET LOG_FILE=%APP_HOME%\logs\console.log

:: JVM Options
SET JVM_OPTS=-Xms256m -Xmx512m -Dfile.encoding=UTF-8

:: ============================================
:: PRE-FLIGHT CHECKS
:: ============================================
echo ============================================
echo %APP_NAME% - Startup Script
echo ============================================
echo.

:: Check Java installation
java -version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Java is not installed or not in PATH
    echo Please install JDK 17 from: https://adoptium.net/temurin/releases/
    pause
    exit /b 1
)

:: Check JAR file exists
IF NOT EXIST "%JAR_FILE%" (
    echo [ERROR] JAR file not found: %JAR_FILE%
    echo Please copy the JAR file to the correct location.
    pause
    exit /b 1
)

:: Check config file exists
IF NOT EXIST "%CONFIG_FILE%" (
    echo [WARNING] Config file not found: %CONFIG_FILE%
    echo Using default configuration...
    SET CONFIG_PARAM=
) ELSE (
    SET CONFIG_PARAM=-Dspring.config.location=file:%CONFIG_FILE%
)

:: Create logs directory if not exists
IF NOT EXIST "%APP_HOME%\logs" (
    mkdir "%APP_HOME%\logs"
)

:: ============================================
:: START APPLICATION
:: ============================================
echo.
echo Starting %APP_NAME%...
echo ============================================
echo JAR File: %JAR_FILE%
echo Config: %CONFIG_FILE%
echo Log File: %LOG_FILE%
echo JVM Options: %JVM_OPTS%
echo ============================================
echo.
echo Press Ctrl+C to stop the server.
echo.

cd /d %APP_HOME%
java %JVM_OPTS% %CONFIG_PARAM% -jar "%JAR_FILE%"

:: This line is reached when the application stops
echo.
echo %APP_NAME% has stopped.
pause

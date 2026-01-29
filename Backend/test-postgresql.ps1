# ============================================
# TEST POSTGRESQL CONNECTION
# ============================================

Write-Host "`n=== POSTGRESQL CONNECTION TEST ===" -ForegroundColor Cyan

# Test 1: Check if PostgreSQL is installed
Write-Host "`n[1/4] Checking PostgreSQL installation..." -ForegroundColor Yellow
try {
    $psqlVersion = psql --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: $psqlVersion" -ForegroundColor Green
    } else {
        throw "PostgreSQL not found"
    }
} catch {
    Write-Host "ERROR: PostgreSQL not found. Please install from:" -ForegroundColor Red
    Write-Host "https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check if database exists
Write-Host "`n[2/4] Checking database 'tram_doc_db'..." -ForegroundColor Yellow
try {
    $dbList = psql -U postgres -lqt 2>&1
    if ($dbList -match "tram_doc_db") {
        Write-Host "OK: Database exists" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Database not found. Create it with:" -ForegroundColor Yellow
        Write-Host "psql -U postgres -c 'CREATE DATABASE tram_doc_db;'" -ForegroundColor Cyan
    }
} catch {
    Write-Host "WARNING: Could not check database list" -ForegroundColor Yellow
}

# Test 3: Test connection
Write-Host "`n[3/4] Testing connection..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = "giang2005"  # Thay bằng mật khẩu của bạn
    $testConn = psql -U postgres -d tram_doc_db -c "SELECT version();" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Connection successful" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Connection failed. Check password in application.properties" -ForegroundColor Red
        Write-Host "Error: $testConn" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: Could not test connection" -ForegroundColor Red
}

# Test 4: Check Spring Boot config
Write-Host "`n[4/4] Checking Spring Boot configuration..." -ForegroundColor Yellow
$props = Get-Content "src\main\resources\application.properties" | Select-String "postgresql"
if ($props) {
    Write-Host "OK: PostgreSQL configured in application.properties" -ForegroundColor Green
    $props | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "WARNING: PostgreSQL not configured. Update application.properties" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   TEST COMPLETED!                     " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

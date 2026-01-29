# ============================================
# SCRIPT DEPLOY TRAM DOC API LEN HEROKU
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TRAM DOC API - HEROKU DEPLOYMENT SCRIPT  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Kiem tra Heroku CLI
Write-Host "`n[1/7] Kiem tra Heroku CLI..." -ForegroundColor Yellow
try {
    $herokuVersion = heroku --version
    Write-Host "OK: $herokuVersion" -ForegroundColor Green
} catch {
    Write-Host "LOI: Heroku CLI chua duoc cai dat!" -ForegroundColor Red
    Write-Host "Tai ve tai: https://devcenter.heroku.com/articles/heroku-cli" -ForegroundColor Yellow
    exit 1
}

# Kiem tra dang nhap
Write-Host "`n[2/7] Kiem tra dang nhap Heroku..." -ForegroundColor Yellow
$authStatus = heroku auth:whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Chua dang nhap. Dang mo trinh duyet de dang nhap..." -ForegroundColor Yellow
    heroku login
}
Write-Host "OK: Da dang nhap" -ForegroundColor Green

# Kiem tra Git
Write-Host "`n[3/7] Kiem tra Git repository..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "Khoi tao Git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit - Tram Doc API"
}
Write-Host "OK: Git repository san sang" -ForegroundColor Green

# Kiem tra Heroku remote
Write-Host "`n[4/7] Kiem tra Heroku app..." -ForegroundColor Yellow
$remotes = git remote -v
if ($remotes -notmatch "heroku") {
    Write-Host "Chua co Heroku app. Tao moi..." -ForegroundColor Yellow
    $appName = Read-Host "Nhap ten app (de trong de tu dong tao)"
    if ($appName) {
        heroku create $appName
    } else {
        heroku create
    }
}
Write-Host "OK: Heroku app da san sang" -ForegroundColor Green

# Kiem tra ClearDB
Write-Host "`n[5/7] Kiem tra Database (ClearDB)..." -ForegroundColor Yellow
$addons = heroku addons 2>&1
if ($addons -notmatch "cleardb") {
    Write-Host "Them ClearDB MySQL..." -ForegroundColor Yellow
    heroku addons:create cleardb:ignite
    
    # Lay URL va cau hinh
    $dbUrl = heroku config:get CLEARDB_DATABASE_URL
    Write-Host "Database URL: $dbUrl" -ForegroundColor Cyan
    
    # Parse URL
    if ($dbUrl -match "mysql://([^:]+):([^@]+)@([^/]+)/([^?]+)") {
        $dbUser = $matches[1]
        $dbPass = $matches[2]
        $dbHost = $matches[3]
        $dbName = $matches[4]
        
        $jdbcUrl = "jdbc:mysql://${dbHost}/${dbName}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true&reconnect=true"
        
        heroku config:set JDBC_DATABASE_URL="$jdbcUrl"
        heroku config:set JDBC_DATABASE_USERNAME="$dbUser"
        heroku config:set JDBC_DATABASE_PASSWORD="$dbPass"
        
        Write-Host "OK: Da cau hinh database" -ForegroundColor Green
    }
}
Write-Host "OK: Database da san sang" -ForegroundColor Green

# Cau hinh JWT Secret
Write-Host "`n[6/7] Kiem tra JWT Secret..." -ForegroundColor Yellow
$jwtSecret = heroku config:get JWT_SECRET 2>&1
if (-not $jwtSecret -or $jwtSecret -match "not set") {
    $randomBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(64)
    $jwtSecretKey = [Convert]::ToBase64String($randomBytes)
    heroku config:set JWT_SECRET="$jwtSecretKey"
    Write-Host "OK: Da tao JWT Secret moi" -ForegroundColor Green
} else {
    Write-Host "OK: JWT Secret da co" -ForegroundColor Green
}

# Cau hinh them
heroku config:set DDL_AUTO="update"
heroku config:set SHOW_SQL="false"
heroku config:set LOG_LEVEL_ROOT="INFO"
heroku config:set LOG_LEVEL_APP="INFO"
heroku config:set LOG_LEVEL_SECURITY="WARN"
heroku config:set LOG_LEVEL_SQL="WARN"

# Deploy
Write-Host "`n[7/7] Deploy ung dung..." -ForegroundColor Yellow
git add .
git commit -m "Deploy to Heroku - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>$null

Write-Host "Dang deploy... (co the mat vai phut)" -ForegroundColor Cyan
git push heroku main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "   DEPLOY THANH CONG!                       " -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    
    $appInfo = heroku apps:info --json | ConvertFrom-Json
    $appUrl = $appInfo.app.web_url
    
    Write-Host "`nURL ung dung: $appUrl" -ForegroundColor Cyan
    Write-Host "Swagger UI: ${appUrl}swagger-ui/index.html" -ForegroundColor Cyan
    Write-Host "Health Check: ${appUrl}actuator/health" -ForegroundColor Cyan
    
    Write-Host "`nMo ung dung trong trinh duyet..." -ForegroundColor Yellow
    heroku open
} else {
    Write-Host "`nCo loi khi deploy. Kiem tra logs:" -ForegroundColor Red
    Write-Host "heroku logs --tail" -ForegroundColor Yellow
}

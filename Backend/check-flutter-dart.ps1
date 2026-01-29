# Check Flutter and Dart SDK Installation
# Run this script after installing Flutter to verify everything is ready

Write-Host "=== CHECKING FLUTTER AND DART SDK ===" -ForegroundColor Cyan
Write-Host ""

$flutterPath = "$env:LOCALAPPDATA\flutter"
$flutterBinPath = "$flutterPath\bin"

# Check if Flutter is installed
Write-Host "1. Checking Flutter SDK..." -ForegroundColor Yellow
if (Test-Path $flutterBinPath) {
    Write-Host "   [OK] Flutter SDK found at: $flutterPath" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Flutter SDK not found" -ForegroundColor Red
    Write-Host "   Please run: install-flutter-jdk.ps1" -ForegroundColor Yellow
    exit 1
}

# Add Flutter to PATH for current session
$env:Path = "$env:Path;$flutterBinPath"

# Check Flutter version
Write-Host ""
Write-Host "2. Checking Flutter version..." -ForegroundColor Yellow
try {
    $flutterVersion = & "$flutterBinPath\flutter.bat" --version 2>&1
    if ($flutterVersion) {
        Write-Host "   [OK] Flutter is working:" -ForegroundColor Green
        $flutterVersion | Select-Object -First 3 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
    } else {
        Write-Host "   [WARNING] Could not get Flutter version" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [ERROR] Error running Flutter: $_" -ForegroundColor Red
}

# Check Dart version
Write-Host ""
Write-Host "3. Checking Dart SDK version..." -ForegroundColor Yellow
try {
    $dartVersion = & "$flutterBinPath\dart.bat" --version 2>&1
    if ($dartVersion) {
        Write-Host "   [OK] Dart SDK is working:" -ForegroundColor Green
        $dartVersion | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
    } else {
        Write-Host "   [WARNING] Could not get Dart version" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [WARNING] Dart SDK may still be downloading..." -ForegroundColor Yellow
    Write-Host "   Flutter will automatically download Dart SDK on first run" -ForegroundColor White
    Write-Host "   Please wait a few minutes and run this script again" -ForegroundColor White
}

# Check PATH
Write-Host ""
Write-Host "4. Checking PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($currentPath -like "*$flutterBinPath*") {
    Write-Host "   [OK] Flutter is in PATH" -ForegroundColor Green
} else {
    Write-Host "   [WARNING] Flutter not in PATH" -ForegroundColor Yellow
    Write-Host "   Adding Flutter to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable('Path', "$currentPath;$flutterBinPath", 'User')
    Write-Host "   [OK] Flutter added to PATH" -ForegroundColor Green
    Write-Host "   [INFO] Please close and reopen terminal for PATH to take effect" -ForegroundColor Yellow
}

# Run flutter doctor
Write-Host ""
Write-Host "5. Running Flutter Doctor (checking dependencies)..." -ForegroundColor Yellow
Write-Host "   (This may take a few minutes if Dart SDK is still downloading)" -ForegroundColor Gray
Write-Host ""
try {
    & "$flutterBinPath\flutter.bat" doctor
} catch {
    Write-Host "   [WARNING] Could not run flutter doctor: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Notes:" -ForegroundColor Yellow
Write-Host "- If Dart SDK is not ready, Flutter will auto-download it on first Flutter command" -ForegroundColor White
Write-Host "- Close and reopen terminal if PATH was just updated" -ForegroundColor White
Write-Host "- Follow flutter doctor instructions to install missing dependencies" -ForegroundColor White
Write-Host ""

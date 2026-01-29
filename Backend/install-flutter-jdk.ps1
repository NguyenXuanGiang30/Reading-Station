# Script cài đặt Flutter và Dart SDK
# Chạy script này với quyền Administrator nếu cần

Write-Host "=== CÀI ĐẶT FLUTTER VÀ DART SDK ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Dart SDK
Write-Host "1. Kiểm tra Dart SDK..." -ForegroundColor Yellow
$dartInstalled = $false
try {
    $dartVersion = dart --version 2>&1 | Select-Object -First 1
    if ($dartVersion -like "*Dart SDK*") {
        Write-Host "   ✓ Dart SDK đã được cài đặt: $dartVersion" -ForegroundColor Green
        $dartInstalled = $true
    }
} catch {
    # Dart chưa được cài đặt hoặc chưa có trong PATH
}

if (-not $dartInstalled) {
    Write-Host "   ⚠ Dart SDK chưa được cài đặt (sẽ được cài cùng Flutter)" -ForegroundColor Yellow
}

Write-Host ""

# Kiểm tra Git
Write-Host "2. Kiểm tra Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "   ✓ Git đã được cài đặt: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Git chưa được cài đặt" -ForegroundColor Red
    Write-Host "   Vui lòng tải Git từ: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Cài đặt Flutter
Write-Host "3. Cài đặt Flutter..." -ForegroundColor Yellow
$flutterPath = "$env:LOCALAPPDATA\flutter"
$flutterBinPath = "$flutterPath\bin"

# Xóa thư mục cũ nếu trống hoặc không đầy đủ
if (Test-Path $flutterPath) {
    $hasBin = Test-Path $flutterBinPath
    if (-not $hasBin) {
        Write-Host "   Xóa thư mục Flutter cũ (không đầy đủ)..." -ForegroundColor Yellow
        Remove-Item -Path $flutterPath -Recurse -Force
    } else {
        Write-Host "   Flutter đã được cài đặt tại: $flutterPath" -ForegroundColor Green
        $flutterInstalled = $true
    }
}

if (-not $flutterInstalled) {
    Write-Host "   Đang clone Flutter SDK từ GitHub (có thể mất vài phút)..." -ForegroundColor Yellow
    try {
        cd $env:LOCALAPPDATA
        git clone https://github.com/flutter/flutter.git -b stable
        Write-Host "   ✓ Flutter đã được clone thành công!" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Lỗi khi clone Flutter: $_" -ForegroundColor Red
        Write-Host "   Bạn có thể tải thủ công từ: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Thêm Flutter vào PATH
Write-Host ""
Write-Host "4. Thêm Flutter vào PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($currentPath -notlike "*$flutterBinPath*") {
    [Environment]::SetEnvironmentVariable('Path', "$currentPath;$flutterBinPath", 'User')
    Write-Host "   ✓ Flutter đã được thêm vào PATH" -ForegroundColor Green
    Write-Host "   ⚠ Vui lòng đóng và mở lại terminal để PATH có hiệu lực" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ Flutter đã có trong PATH" -ForegroundColor Green
}

# Kiểm tra Flutter và Dart
Write-Host ""
Write-Host "5. Kiểm tra Flutter và Dart..." -ForegroundColor Yellow
$env:Path = "$env:Path;$flutterBinPath"
try {
    $flutterVersion = & "$flutterBinPath\flutter.bat" --version 2>&1 | Select-Object -First 1
    Write-Host "   ✓ Flutter hoạt động: $flutterVersion" -ForegroundColor Green
    
    # Kiểm tra Dart từ Flutter
    $dartVersion = & "$flutterBinPath\dart.bat" --version 2>&1 | Select-Object -First 1
    if ($dartVersion) {
        Write-Host "   ✓ Dart SDK hoạt động: $dartVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠ Flutter/Dart chưa sẵn sàng trong terminal hiện tại" -ForegroundColor Yellow
    Write-Host "   Vui lòng đóng và mở lại terminal, sau đó chạy: flutter doctor" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== HOÀN TẤT ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Các bước tiếp theo:" -ForegroundColor Yellow
Write-Host "1. Đóng và mở lại terminal/PowerShell" -ForegroundColor White
Write-Host "2. Chạy lệnh: flutter doctor" -ForegroundColor White
Write-Host "3. Làm theo hướng dẫn của flutter doctor để cài đặt các dependencies còn thiếu" -ForegroundColor White
Write-Host ""

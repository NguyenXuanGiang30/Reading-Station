# Script cài đặt Dart SDK riêng biệt
# Lưu ý: Flutter đã đi kèm Dart SDK, script này chỉ dùng nếu bạn muốn cài Dart riêng

Write-Host "=== CÀI ĐẶT DART SDK ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Dart đã cài chưa
Write-Host "1. Kiểm tra Dart SDK..." -ForegroundColor Yellow
try {
    $dartVersion = dart --version 2>&1
    if ($dartVersion -like "*Dart SDK*") {
        Write-Host "   ✓ Dart SDK đã được cài đặt" -ForegroundColor Green
        Write-Host "   $dartVersion" -ForegroundColor White
        exit 0
    }
} catch {
    # Dart chưa được cài đặt
}

# Kiểm tra Git
Write-Host ""
Write-Host "2. Kiểm tra Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "   ✓ Git đã được cài đặt: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Git chưa được cài đặt" -ForegroundColor Red
    Write-Host "   Vui lòng tải Git từ: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Cài đặt Dart SDK
Write-Host ""
Write-Host "3. Cài đặt Dart SDK..." -ForegroundColor Yellow
$dartPath = "$env:LOCALAPPDATA\dart-sdk"
$dartBinPath = "$dartPath\bin"

# Xóa thư mục cũ nếu trống hoặc không đầy đủ
if (Test-Path $dartPath) {
    $hasBin = Test-Path $dartBinPath
    if (-not $hasBin) {
        Write-Host "   Xóa thư mục Dart cũ (không đầy đủ)..." -ForegroundColor Yellow
        Remove-Item -Path $dartPath -Recurse -Force
    } else {
        Write-Host "   Dart SDK đã được cài đặt tại: $dartPath" -ForegroundColor Green
        $dartInstalled = $true
    }
}

if (-not $dartInstalled) {
    Write-Host "   Đang clone Dart SDK từ GitHub (có thể mất vài phút)..." -ForegroundColor Yellow
    try {
        cd $env:LOCALAPPDATA
        git clone https://github.com/dart-lang/sdk.git dart-sdk
        Write-Host "   ✓ Dart SDK đã được clone thành công!" -ForegroundColor Green
        Write-Host "   ⚠ Lưu ý: Cần build Dart SDK từ source (phức tạp)" -ForegroundColor Yellow
        Write-Host "   Khuyến nghị: Sử dụng Flutter (đã đi kèm Dart) hoặc tải Dart SDK từ:" -ForegroundColor Yellow
        Write-Host "   https://dart.dev/get-dart" -ForegroundColor Cyan
    } catch {
        Write-Host "   ✗ Lỗi khi clone Dart SDK: $_" -ForegroundColor Red
        Write-Host "   Vui lòng tải Dart SDK từ: https://dart.dev/get-dart" -ForegroundColor Yellow
        exit 1
    }
}

# Thêm Dart vào PATH
Write-Host ""
Write-Host "4. Thêm Dart vào PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($currentPath -notlike "*$dartBinPath*") {
    [Environment]::SetEnvironmentVariable('Path', "$currentPath;$dartBinPath", 'User')
    Write-Host "   ✓ Dart đã được thêm vào PATH" -ForegroundColor Green
    Write-Host "   ⚠ Vui lòng đóng và mở lại terminal để PATH có hiệu lực" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ Dart đã có trong PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== HOÀN TẤT ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lưu ý: Flutter đã đi kèm Dart SDK, bạn không cần cài Dart riêng nếu đã cài Flutter" -ForegroundColor Yellow
Write-Host ""

# ============================================
# PARSE RENDER DATABASE URL
# ============================================
# Script này giúp chuyển đổi Render Database URL thành JDBC URL

Write-Host "`n=== RENDER DATABASE URL PARSER ===" -ForegroundColor Cyan
Write-Host "`nNhập Render Database URL (từ tab Info):" -ForegroundColor Yellow
Write-Host "Format: postgresql://user:password@host:port/database" -ForegroundColor Gray
Write-Host ""

$renderUrl = Read-Host "Render URL"

if ($renderUrl -match "postgresql://([^:]+):([^@]+)@([^:]+):?(\d+)?/(.+)") {
    $username = $matches[1]
    $password = $matches[2]
    $host = $matches[3]
    $port = if ($matches[4]) { $matches[4] } else { "5432" }
    $database = $matches[5]
    
    $jdbcUrl = "jdbc:postgresql://${host}:${port}/${database}"
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "   PARSED CONFIGURATION                  " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    Write-Host "Copy các giá trị sau vào Render Environment Variables:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DATABASE_URL=$jdbcUrl" -ForegroundColor Yellow
    Write-Host "DATABASE_USERNAME=$username" -ForegroundColor Yellow
    Write-Host "DATABASE_PASSWORD=$password" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    
} else {
    Write-Host "ERROR: Invalid URL format!" -ForegroundColor Red
    Write-Host "Expected: postgresql://user:password@host:port/database" -ForegroundColor Yellow
}

# Quick Disk Space Cleanup Script for Flutter

Write-Host "🧹 Cleaning Flutter and Temp Files..." -ForegroundColor Yellow
Write-Host ""

# 1. Clean Flutter build
Write-Host "1. Cleaning Flutter build files..." -ForegroundColor Cyan
cd "D:\New folder\Main folder\bidmaster flutter"
flutter clean 2>&1 | Out-Null

# 2. Clean Flutter pub cache
Write-Host "2. Cleaning Flutter pub cache..." -ForegroundColor Cyan
flutter pub cache clean 2>&1 | Out-Null

# 3. Clean temp Flutter files
Write-Host "3. Cleaning temp Flutter files..." -ForegroundColor Cyan
Remove-Item "$env:LOCALAPPDATA\Temp\flutter_tools.*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\flutter_*" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Clean build folders
Write-Host "4. Cleaning build folders..." -ForegroundColor Cyan
Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue

# 5. Check free space
Write-Host ""
Write-Host "5. Checking free space..." -ForegroundColor Cyan
$freeSpace = [math]::Round((Get-PSDrive C).Free/1GB, 2)
Write-Host "   Free space on C: drive: $freeSpace GB" -ForegroundColor $(if($freeSpace -lt 1){"Red"}elseif($freeSpace -lt 5){"Yellow"}else{"Green"})

Write-Host ""
if ($freeSpace -lt 1) {
    Write-Host "⚠️  WARNING: Very low disk space! ($freeSpace GB)" -ForegroundColor Red
    Write-Host "   Please free up more space:" -ForegroundColor Yellow
    Write-Host "   - Empty Recycle Bin" -ForegroundColor White
    Write-Host "   - Run Windows Disk Cleanup" -ForegroundColor White
    Write-Host "   - Delete old/unused files" -ForegroundColor White
    Write-Host "   - Uninstall unused programs" -ForegroundColor White
} else {
    Write-Host "✅ Cleanup complete! You can now try 'flutter pub get' and 'flutter run'" -ForegroundColor Green
}


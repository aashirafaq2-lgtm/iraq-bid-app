# Clean Kotlin Incremental Compilation Cache
# Run this script if you encounter "Storage already registered" or "different roots" errors

Write-Host "Cleaning Kotlin Incremental Compilation Cache..." -ForegroundColor Cyan
Write-Host ""

# Stop Gradle daemon
Write-Host "1. Stopping Gradle daemon..." -ForegroundColor Yellow
cd android
& gradlew.bat --stop 2>$null
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
    Write-Host "   [OK] Gradle daemon stopped" -ForegroundColor Green
} else {
    Write-Host "   [WARN] Gradle daemon may not be running" -ForegroundColor Yellow
}
cd ..

# Stop Kotlin compiler daemon
Write-Host "2. Stopping Kotlin compiler daemon..." -ForegroundColor Yellow
$kotlinDaemonPath = "$env:USERPROFILE\.kotlin\daemon"
if (Test-Path $kotlinDaemonPath) {
    Get-Process | Where-Object { $_.ProcessName -like "*kotlin*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Kotlin daemon processes stopped" -ForegroundColor Green
} else {
    Write-Host "   [INFO] No Kotlin daemon found" -ForegroundColor Gray
}

# Clean Flutter build
Write-Host "3. Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean

# Clean Android build directories
Write-Host "4. Cleaning Android build directories..." -ForegroundColor Yellow
if (Test-Path "android\build") {
    Remove-Item -Recurse -Force "android\build" -ErrorAction SilentlyContinue
    Write-Host "   [OK] Removed android\build" -ForegroundColor Green
}

if (Test-Path "android\.gradle") {
    Remove-Item -Recurse -Force "android\.gradle" -ErrorAction SilentlyContinue
    Write-Host "   [OK] Removed android\.gradle" -ForegroundColor Green
}

if (Test-Path "android\app\build") {
    Remove-Item -Recurse -Force "android\app\build" -ErrorAction SilentlyContinue
    Write-Host "   [OK] Removed android\app\build" -ForegroundColor Green
}

# Clean Kotlin incremental cache in build directory
Write-Host "5. Cleaning Kotlin incremental caches..." -ForegroundColor Yellow
$buildPath = "android\build"
if (Test-Path $buildPath) {
    Get-ChildItem -Path $buildPath -Recurse -Filter "*kotlin*" -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -like "*cacheable*" -or $_.FullName -like "*caches-jvm*" } | 
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "   [OK] Kotlin cache files removed" -ForegroundColor Green
}

# Clean app build Kotlin cache
$appBuildPath = "android\app\build"
if (Test-Path $appBuildPath) {
    Get-ChildItem -Path $appBuildPath -Recurse -Filter "*kotlin*" -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -like "*cacheable*" -or $_.FullName -like "*caches-jvm*" } | 
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "   [OK] App Kotlin cache files removed" -ForegroundColor Green
}

# Clean Gradle cache (Kotlin related)
Write-Host "6. Cleaning Gradle Kotlin cache..." -ForegroundColor Yellow
$gradleKotlinCache = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.jetbrains.kotlin"
if (Test-Path $gradleKotlinCache) {
    Write-Host "   [WARN] Kotlin cache found at: $gradleKotlinCache" -ForegroundColor Yellow
    Write-Host "   [TIP] To clean manually, run: Remove-Item -Recurse -Force '$gradleKotlinCache'" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[OK] Cache cleaning complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Kotlin incremental compilation is now DISABLED in gradle.properties" -ForegroundColor Cyan
Write-Host "This prevents cache errors but builds may be slightly slower." -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: flutter pub get" -ForegroundColor White
Write-Host "  2. Run: flutter build apk --release" -ForegroundColor White
Write-Host ""

@echo off
setlocal enabledelayedexpansion
echo ====================================================
echo      IRAQ BID - AUTOMATIC GITHUB UPLOADER
echo ====================================================
echo.

:: Check for GitHub CLI
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] GitHub CLI (gh) is missing. Attempting to install...
    winget install --id GitHub.cli -e --source winget --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        echo.
        echo [X] Auto-install failed. Please install manually from: 
        echo     https://cli.github.com/
        pause
        exit /b
    )
    echo.
    echo [!] Installation successful! 
    echo [!] IMPORTANT: Please CLOSE this window and START it again.
    pause
    exit /b
)

echo [1/3] Initializing Git...
if not exist .git (
    git init
)
git add .
git commit -m "Final Apple Fixes"

echo.
echo [2/3] Logging into GitHub...
echo (A browser window will open. Please authorize GitHub CLI)
gh auth login --web -h github.com -s repo

echo.
echo [3/3] Creating and Pushing to GitHub...
:: Try to create, if exists it will just fail and we continue to push
gh repo create iraq-bid-app --private --source=. --push --confirm 2>nul
if %errorlevel% neq 0 (
    echo [!] Repository might already exist. Trying to push anyway...
    git push -u origin master
)

echo.
echo ====================================================
echo ✅ PROCESS COMPLETE!
echo.
echo If everything went well, your code is now on GitHub.
echo Check here: github.com/your-username/iraq-bid-app/actions
echo ====================================================
pause

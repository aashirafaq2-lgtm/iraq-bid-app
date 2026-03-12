@echo off
echo ====================================================
echo      IRAQ BID - AUTOMATIC GITHUB UPLOADER
echo ====================================================
echo.

where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] GitHub CLI (gh) looks missing. Installing it for you...
    echo.
    winget install --id GitHub.cli -e --source winget
    echo.
    echo [!] Installation finished. Please RE-START this file now.
    pause
    exit
)

echo Step 1: Initializing Git...
git init
git add .
git commit -m "Final Apple Fixes: Account Deletion and Login Bug fixed"

echo.
echo Step 2: Creating Privacy-Safe Repository on GitHub...
echo (If a browser window opens, please login and come back here)
gh auth login --web -h github.com -s repo
gh repo create iraq-bid-app --private --source=. --push --confirm

echo.
echo ====================================================
echo ✅ DONE! Your code is now on GitHub.
echo.
echo NOW GO TO: github.com/your-username/iraq-bid-app/actions
echo and click on "Build and Release IPA" to start the build.
echo ====================================================
pause

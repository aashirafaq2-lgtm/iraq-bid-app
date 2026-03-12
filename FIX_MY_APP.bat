@echo off
echo ====================================================
echo      IRAQ BID - AUTOMATIC GITHUB UPLOADER
echo ====================================================
echo.
echo Step 1: Initializing Git...
git init
git add .
git commit -m "Final Apple Fixes: Account Deletion and Login Bug fixed"

echo.
echo Step 2: Creating Privacy-Safe Repository on GitHub...
echo (If a browser window opens, please login and come back here)
gh repo create iraq-bid-app --private --source=. --push --confirm

echo.
echo ====================================================
echo ✅ DONE! Your code is now on GitHub.
echo.
echo NOW GO TO: github.com/your-username/iraq-bid-app/actions
echo and click on "Build and Release IPA" to start the build.
echo ====================================================
pause

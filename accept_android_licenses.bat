@echo off
echo ========================================
echo Accepting Android SDK Licenses
echo ========================================
echo.

set ANDROID_HOME=C:\Android\sdk

echo Checking Android SDK at: %ANDROID_HOME%
if not exist "%ANDROID_HOME%" (
    echo ERROR: Android SDK not found at %ANDROID_HOME%
    echo Please update ANDROID_HOME path in this script
    pause
    exit /b 1
)

echo.
echo Method 1: Using cmdline-tools (if installed)
if exist "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" (
    echo Found cmdline-tools, accepting licenses...
    echo y | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
    goto :done
)

echo.
echo Method 2: Using tools (if installed)
if exist "%ANDROID_HOME%\tools\bin\sdkmanager.bat" (
    echo Found tools, accepting licenses...
    echo y | "%ANDROID_HOME%\tools\bin\sdkmanager.bat" --licenses
    goto :done
)

echo.
echo ========================================
echo SDK Manager not found!
echo ========================================
echo.
echo Please do ONE of the following:
echo.
echo OPTION 1: Install cmdline-tools
echo   1. Open Android Studio
echo   2. Go to: Tools ^> SDK Manager
echo   3. Click "SDK Tools" tab
echo   4. Check "Android SDK Command-line Tools (latest)"
echo   5. Click "Apply" and wait for installation
echo   6. Run this script again
echo.
echo OPTION 2: Accept licenses manually
echo   1. Open Android Studio
echo   2. Go to: Tools ^> SDK Manager
echo   3. Click "SDK Tools" tab
echo   4. Check "NDK (Side by side)" and install
echo   5. When prompted, accept all licenses
echo.
echo OPTION 3: Use Flutter Doctor
echo   Run: flutter doctor --android-licenses
echo   (After installing cmdline-tools)
echo.
pause
exit /b 1

:done
echo.
echo ========================================
echo Licenses accepted successfully!
echo ========================================
echo.
echo Now you can build the APK:
echo   flutter build apk --release
echo.
pause



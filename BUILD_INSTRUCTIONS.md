# Build Instructions for Production Release

## Prerequisites
1.  **Flutter SDK** installed and in `PATH`.
2.  **Android SDK** configured.
3.  **Java/JDK** 11 or 17 configured.

## Steps to Build Release APK

1.  Open terminal in project root:
    ```bash
    cd "c:\Users\computer lab\Downloads\Bidmaster-Flutter-App-main\Bidmaster-Flutter-App-main"
    ```

2.  Clean previous builds:
    ```bash
    flutter clean
    ```

3.  Get dependencies:
    ```bash
    flutter pub get
    ```

4.  Build release APK:
    ```bash
    flutter build apk --release
    ```

5.  Locate APK:
    The APK will be generated at:
    `build/app/outputs/flutter-apk/app-release.apk`

## Signing with Custom Key (Optional)

If you have a keystore file (`key.jks` or similar), place `key.properties` in `android/` directory with:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../key.jks
```

Then create/copy your `key.jks` to the project root or adjust `storeFile` path.

## Verify Build
After building, install on device:
```bash
flutter install
```
Or drag and drop the APK file onto an emulator/device.

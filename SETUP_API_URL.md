# API URL Configuration Guide

## Problem
When running Flutter apps on **web browsers** or **mobile devices**, `localhost` does NOT work because:
- **Web**: `localhost` refers to the browser's localhost, not your development machine
- **Mobile**: `localhost` refers to the device itself, not your development machine

## Solution

### Option 1: Run with API_BASE_URL (Recommended)

Use your local IP address instead of localhost:

```bash
# For Web
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.2.15:5000/api

# For Mobile (Android/iOS)
flutter run --dart-define=API_BASE_URL=http://192.168.2.15:5000/api

# For Desktop
flutter run --dart-define=API_BASE_URL=http://192.168.2.15:5000/api
```

### Option 2: Find Your IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your active network adapter (usually Wi-Fi or Ethernet).

**Mac/Linux:**
```bash
ifconfig
# or
ip addr
```

### Option 3: Use Production URL

If you have a production server:
```bash
flutter run --dart-define=API_BASE_URL=https://your-production-server.com/api
```

## Important Notes

1. **Make sure your backend server is running** on port 5000 (or your configured port)
2. **Make sure your device/computer is on the same network** as your development machine
3. **Check firewall settings** - Windows Firewall might block incoming connections
4. **For production builds**, you MUST set API_BASE_URL:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://your-server.com/api
   ```

## Quick Fix for Current Session

Run this command to start your app with the correct API URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.2.15:5000/api
```

Replace `192.168.2.15` with your actual IP address if different.


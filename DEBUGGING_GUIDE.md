# 🔍 Flutter Network & Twilio Debugging Guide

This guide helps you debug network connectivity and Twilio OTP issues in your Flutter app.

## 📋 Table of Contents

1. [Network Connectivity Issues](#network-connectivity-issues)
2. [Twilio Configuration](#twilio-configuration)
3. [Flutter Debugging](#flutter-debugging)
4. [Backend Testing](#backend-testing)

---

## 🌐 Network Connectivity Issues

### Problem: `ERR_CONNECTION_REFUSED`

This error means the Flutter app cannot reach your backend server.

### Solution Steps:

#### Step 1: Find Your Local IP Address

**Windows:**
```powershell
ipconfig
# Look for "IPv4 Address" under your active network adapter
```

**Mac/Linux:**
```bash
ifconfig
# or
ip addr
```

#### Step 2: Verify Backend Server is Running

```bash
cd "Bid app Backend"
npm start
```

Check that you see:
```
✅ Server running on port 5000
```

#### Step 3: Test Backend Connectivity

Run the network test script:
```bash
cd "Bid app Backend"
node src/scripts/testNetworkConnectivity.js http://YOUR_IP:5000
```

Replace `YOUR_IP` with your actual IP (e.g., `192.168.2.15`)

#### Step 4: Run Flutter with Correct API URL

**For Web:**
```bash
cd "bidmaster flutter"
flutter run -d chrome --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
```

**For Mobile (Android/iOS):**
```bash
cd "bidmaster flutter"
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
```

**Important:** Replace `YOUR_IP` with your actual local IP address (e.g., `192.168.2.15`)

#### Step 5: Using ngrok (Alternative for Testing)

If you need to test from a different network:

1. **Install ngrok:**
   ```bash
   # Download from https://ngrok.com/download
   ```

2. **Start ngrok tunnel:**
   ```bash
   ngrok http 5000
   ```

3. **Use ngrok URL in Flutter:**
   ```bash
   flutter run --dart-define=API_BASE_URL=https://YOUR_NGROK_URL.ngrok.io/api
   ```

---

## 📱 Twilio Configuration

### Problem: OTP Not Sending

### Solution Steps:

#### Step 1: Verify Twilio Configuration

Run the Twilio verification script:
```bash
cd "Bid app Backend"
node src/scripts/verifyTwilioConfig.js
```

This will check:
- ✅ Environment variables are set
- ✅ Twilio credentials are valid
- ✅ Verify Service exists
- ✅ Can connect to Twilio API

#### Step 2: Check Environment Variables

Make sure your `.env` file in `Bid app Backend` has:

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_VERIFY_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### Step 3: Verify Twilio Console

1. Go to https://console.twilio.com/
2. Check **Verify** → **Services**
3. Make sure your Verify Service SID matches `TWILIO_VERIFY_SID`
4. For **trial accounts**, verify phone numbers at:
   https://console.twilio.com/us1/develop/phone-numbers/manage/verified

#### Step 4: Test OTP Sending Directly

Test the backend endpoint directly:
```bash
curl -X POST http://YOUR_IP:5000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+9647700914000"}'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

---

## 🐛 Flutter Debugging

### Enable Verbose Logging

Run Flutter with verbose output:
```bash
flutter run --verbose --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
```

### Check Flutter Logs

Look for these log messages in the console:

**Good Signs:**
```
✅ API Service initialized
   Base URL: http://192.168.2.15:5000/api
📤 Sending OTP via Twilio Verify
✅ OTP sent successfully
```

**Error Signs:**
```
❌ API Error: The connection errored
❌ Send OTP error: DioException [connection error]
```

### Enable Network Logging in Code

The app already has debug logging. Check the console output when:
- App starts (API Service initialization)
- Sending OTP (network request details)
- Receiving response (success/error messages)

### Common Flutter Network Issues

1. **CORS Issues (Web only):**
   - Make sure backend has CORS enabled
   - Check browser console for CORS errors

2. **SSL Certificate Issues:**
   - For local development, use `http://` not `https://`
   - For production, ensure valid SSL certificate

3. **Firewall Blocking:**
   - Windows Firewall might block connections
   - Check Windows Defender Firewall settings
   - Allow Node.js/backend through firewall

---

## 🧪 Backend Testing

### Test Backend Server Health

```bash
# Test if server is running
curl http://localhost:5000/health

# Or test from another machine
curl http://YOUR_IP:5000/health
```

### Test OTP Endpoint

```bash
# Send OTP
curl -X POST http://YOUR_IP:5000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+9647700914000"}'

# Verify OTP (use code from SMS)
curl -X POST http://YOUR_IP:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+9647700914000", "otp": "123456"}'
```

### Check Backend Logs

Watch backend console for:
- ✅ Twilio client initialization
- ✅ OTP sending attempts
- ❌ Error messages

---

## 🔧 Quick Troubleshooting Checklist

### Network Issues:
- [ ] Backend server is running (`npm start`)
- [ ] Using correct IP address (not `localhost`)
- [ ] Device/computer on same network
- [ ] Firewall not blocking connections
- [ ] Port 5000 is not in use by another app

### Twilio Issues:
- [ ] Twilio credentials are correct in `.env`
- [ ] Verify Service SID exists in Twilio Console
- [ ] Phone number is verified (for trial accounts)
- [ ] Twilio account is active (not suspended)
- [ ] Sufficient Twilio credits/balance

### Flutter Issues:
- [ ] Using `--dart-define=API_BASE_URL=...` flag
- [ ] API URL format is correct (`http://IP:PORT/api`)
- [ ] No typos in IP address
- [ ] Running latest code changes

---

## 📞 Still Having Issues?

1. **Check Backend Logs:**
   - Look for detailed error messages
   - Check Twilio service logs

2. **Check Flutter Logs:**
   - Run with `--verbose` flag
   - Check browser console (for web)

3. **Test Each Component Separately:**
   - Test backend with curl/Postman
   - Test Twilio with verification script
   - Test Flutter network separately

4. **Common Solutions:**
   - Restart backend server
   - Restart Flutter app
   - Clear Flutter build cache: `flutter clean`
   - Rebuild: `flutter pub get && flutter run`

---

## 📚 Additional Resources

- [Twilio Verify API Docs](https://www.twilio.com/docs/verify/api)
- [Flutter Network Debugging](https://docs.flutter.dev/testing/debugging)
- [Dio HTTP Client Docs](https://pub.dev/packages/dio)


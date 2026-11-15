// ==================== DEVELOPMENT AUTO-LOGIN CONFIG ====================
// 🔥 Toggle ON/OFF for dev mode
const bool AUTO_LOGIN_ENABLED = true;

// 🎯 VERIFIED TWILIO NUMBER (Trial Account)
// This is the ONLY number that can receive OTP from Twilio Verify
const String VERIFIED_TWILIO_PHONE = '+9647700914000';

// Default test phone number (for auto-login feature only)
// Uses verified Twilio number for OTP testing
const String DEFAULT_DEV_PHONE = VERIFIED_TWILIO_PHONE;

// ONE NUMBER LOGIN SYSTEM
// Both buyer and seller use the SAME verified phone number
const String ONE_NUMBER_LOGIN_PHONE = VERIFIED_TWILIO_PHONE;


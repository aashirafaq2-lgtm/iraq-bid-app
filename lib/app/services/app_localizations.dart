import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'language_service.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    // Always use LanguageService locale to ensure Kurdish works
    // MaterialApp might use English for Kurdish, but we use actual selected language
    // Listen to language changes to force rebuild
    final actualLocale = LanguageService.languageNotifier.value;
    return AppLocalizations(actualLocale);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Common translations
  String get appName => _localizedValues[locale.languageCode]?['appName'] ?? 'IRAQ BID';
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get transactions => _localizedValues[locale.languageCode]?['transactions'] ?? 'Transactions';
  String get contactUs => _localizedValues[locale.languageCode]?['contactUs'] ?? 'Contact Us';
  String get aboutUs => _localizedValues[locale.languageCode]?['aboutUs'] ?? 'About Us';
  String get shareApp => _localizedValues[locale.languageCode]?['shareApp'] ?? 'Share this App';
  String get loginSignUp => _localizedValues[locale.languageCode]?['loginSignUp'] ?? 'Login/Sign Up';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get notLoggedIn => _localizedValues[locale.languageCode]?['notLoggedIn'] ?? 'Not Logged In';
  String get loginRequired => _localizedValues[locale.languageCode]?['loginRequired'] ?? 'You need to be logged in to access the full features of this app';
  
  // Auth screen
  String get welcome => _localizedValues[locale.languageCode]?['welcome'] ?? 'Welcome to IRAQ BID';
  String get enterPhone => _localizedValues[locale.languageCode]?['enterPhone'] ?? 'Enter your phone number to get started';
  String get phoneNumber => _localizedValues[locale.languageCode]?['phoneNumber'] ?? 'Phone Number';
  String get referralCode => _localizedValues[locale.languageCode]?['referralCode'] ?? 'Referral Code (Optional)';
  String get sendOtp => _localizedValues[locale.languageCode]?['sendOtp'] ?? 'Send OTP';
  String get otpSent => _localizedValues[locale.languageCode]?['otpSent'] ?? 'OTP will be sent to your phone via SMS';
  String get dontHaveAccount => _localizedValues[locale.languageCode]?['dontHaveAccount'] ?? "Don't have an account?";
  String get signUp => _localizedValues[locale.languageCode]?['signUp'] ?? 'Sign Up';
  
  // Categories
  String get categories => _localizedValues[locale.languageCode]?['categories'] ?? 'Categories';
  String get electronics => _localizedValues[locale.languageCode]?['electronics'] ?? 'Electronics';
  String get fashion => _localizedValues[locale.languageCode]?['fashion'] ?? 'Fashion';
  String get furniture => _localizedValues[locale.languageCode]?['furniture'] ?? 'Furniture';
  String get homeAppliances => _localizedValues[locale.languageCode]?['homeAppliances'] ?? 'Home Appliances';
  String get laptops => _localizedValues[locale.languageCode]?['laptops'] ?? 'Laptops';
  String get mobile => _localizedValues[locale.languageCode]?['mobile'] ?? 'Mobile';
  String get mobiles => _localizedValues[locale.languageCode]?['mobiles'] ?? 'Mobiles';
  String get property => _localizedValues[locale.languageCode]?['property'] ?? 'Property';
  String get collectibles => _localizedValues[locale.languageCode]?['collectibles'] ?? 'Collectibles';
  String get iraqiBid => _localizedValues[locale.languageCode]?['iraqiBid'] ?? 'IRAQ BID';
  
  // Helper method to translate category names
  String translateCategory(String categoryName) {
    // Normalize category name (case-insensitive, trim whitespace)
    final normalized = categoryName.trim();
    
    // Map common category names to translation keys
    final categoryMap = {
      'all': allProducts,
      'property': property,
      'mobiles': mobiles,
      'mobile': mobile,
      'laptops': laptops,
      'home appliances': homeAppliances,
      'furniture': furniture,
      'fashion': fashion,
      'electronics': electronics,
      'collectibles': collectibles,
    };
    
    // Try exact match (case-insensitive)
    final lowerKey = normalized.toLowerCase();
    if (categoryMap.containsKey(lowerKey)) {
      return categoryMap[lowerKey]!;
    }
    
    // If no translation found, return original
    return normalized;
  }
  
  // Common
  String get search => _localizedValues[locale.languageCode]?['search'] ?? 'Search';
  String get myBids => _localizedValues[locale.languageCode]?['myBids'] ?? 'My Bids';
  String get profile => _localizedValues[locale.languageCode]?['profile'] ?? 'Profile';
  String get notifications => _localizedValues[locale.languageCode]?['notifications'] ?? 'Notifications';
  String get logout => _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get loginSuccessful => _localizedValues[locale.languageCode]?['loginSuccessful'] ?? 'Login successful! Welcome';
  String get toBidMaster => _localizedValues[locale.languageCode]?['toBidMaster'] ?? 'to BidMaster';
  String get otpResent => _localizedValues[locale.languageCode]?['otpResent'] ?? 'OTP resent to your phone. Please check your SMS.';
  String get changePhoneNumber => _localizedValues[locale.languageCode]?['changePhoneNumber'] ?? 'Change phone number';
  
  // Auth screen additional
  String get verifyPhone => _localizedValues[locale.languageCode]?['verifyPhone'] ?? 'Verify Your Phone';
  String get otpSentMessage => _localizedValues[locale.languageCode]?['otpSentMessage'] ?? 'We sent a code to';
  String get enterOtp => _localizedValues[locale.languageCode]?['enterOtp'] ?? 'Enter OTP';
  String get verify => _localizedValues[locale.languageCode]?['verify'] ?? 'Verify';
  String get resendOtp => _localizedValues[locale.languageCode]?['resendOtp'] ?? 'Resend OTP';
  String get invalidOtp => _localizedValues[locale.languageCode]?['invalidOtp'] ?? 'Invalid OTP';
  String get invalidPhone => _localizedValues[locale.languageCode]?['invalidPhone'] ?? 'Invalid Phone Number';
  String get onlyIraqNumbers => _localizedValues[locale.languageCode]?['onlyIraqNumbers'] ?? 'Only Iraq (+964) numbers are allowed.';
  String get enterValidPhone => _localizedValues[locale.languageCode]?['enterValidPhone'] ?? 'Please enter a valid phone number';
  String get phoneMustBe10Digits => _localizedValues[locale.languageCode]?['phoneMustBe10Digits'] ?? 'Phone number must be exactly 10 digits';
  String get otpSentToPhone => _localizedValues[locale.languageCode]?['otpSentToPhone'] ?? 'OTP sent to your phone. Please check your SMS.';
  String get failedToSendOtp => _localizedValues[locale.languageCode]?['failedToSendOtp'] ?? 'Failed to send OTP. Please try again.';
  String get phoneNotRegistered => _localizedValues[locale.languageCode]?['phoneNotRegistered'] ?? 'Phone number not registered. Please contact administrator.';
  String get invalidPhoneFormat => _localizedValues[locale.languageCode]?['invalidPhoneFormat'] ?? 'Invalid phone number format. Please check and try again.';
  String get enter6DigitOtp => _localizedValues[locale.languageCode]?['enter6DigitOtp'] ?? 'Please enter the 6-digit OTP';
  
  // Home screen
  String get all => _localizedValues[locale.languageCode]?['all'] ?? 'All';
  String get allProducts => _localizedValues[locale.languageCode]?['allProducts'] ?? 'All Products';
  String get selectCategory => _localizedValues[locale.languageCode]?['selectCategory'] ?? 'Select Category';
  String get failedToLoadProducts => _localizedValues[locale.languageCode]?['failedToLoadProducts'] ?? 'Failed to load products';
  String get retry => _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';
  String get noProductsFound => _localizedValues[locale.languageCode]?['noProductsFound'] ?? 'No products found';
  String get tryAdjustingSearch => _localizedValues[locale.languageCode]?['tryAdjustingSearch'] ?? 'Try adjusting your search or filters';
  String get close => _localizedValues[locale.languageCode]?['close'] ?? 'Close';
  
  // Additional missing translations
  String get exitApp => _localizedValues[locale.languageCode]?['exitApp'] ?? 'Exit App';
  String get exitAppMessage => _localizedValues[locale.languageCode]?['exitAppMessage'] ?? 'Do you want to exit the app?';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get exit => _localizedValues[locale.languageCode]?['exit'] ?? 'Exit';
  String get noProductsYet => _localizedValues[locale.languageCode]?['noProductsYet'] ?? 'No products yet';
  String get createFirstProduct => _localizedValues[locale.languageCode]?['createFirstProduct'] ?? 'Create your first product to start selling';
  String get createProduct => _localizedValues[locale.languageCode]?['createProduct'] ?? 'Create Product';
  String get company => _localizedValues[locale.languageCode]?['company'] ?? 'Company';
  String get wishlist => _localizedValues[locale.languageCode]?['wishlist'] ?? 'Wishlist';
  String get wins => _localizedValues[locale.languageCode]?['wins'] ?? 'Wins';
  String get notification => _localizedValues[locale.languageCode]?['notification'] ?? 'Notification';
  String get pleaseLoginFirst => _localizedValues[locale.languageCode]?['pleaseLoginFirst'] ?? 'Please login first';
  String get roleSwitched => _localizedValues[locale.languageCode]?['roleSwitched'] ?? 'Role switched to';
  String get sellerProducts => _localizedValues[locale.languageCode]?['sellerProducts'] ?? 'Seller Products';
  String get companyProducts => _localizedValues[locale.languageCode]?['companyProducts'] ?? 'Company Products';
  String get failedToSwitchRole => _localizedValues[locale.languageCode]?['failedToSwitchRole'] ?? 'Failed to switch role';
  String get viewAll => _localizedValues[locale.languageCode]?['viewAll'] ?? 'View All';
  String get noCompanyProducts => _localizedValues[locale.languageCode]?['noCompanyProducts'] ?? 'No company products available';
  String get noSellerProducts => _localizedValues[locale.languageCode]?['noSellerProducts'] ?? 'No seller products yet';
  String get addProduct => _localizedValues[locale.languageCode]?['addProduct'] ?? 'Add Product';
  String get searchHereProduct => _localizedValues[locale.languageCode]?['searchHereProduct'] ?? 'Search here product';
  String get searchOutCategory => _localizedValues[locale.languageCode]?['searchOutCategory'] ?? 'Search out category';
  String get contactUsContent => _localizedValues[locale.languageCode]?['contactUsContent'] ?? 'Email: info@iqbidmaster.com\nPhone: +964 750 352 3322';
  String get aboutUsTitle => _localizedValues[locale.languageCode]?['aboutUsTitle'] ?? 'About IQ BidMaster';
  String get aboutUsContent => _localizedValues[locale.languageCode]?['aboutUsContent'] ?? 'IQ BidMaster is the first online auction platform in Iraq and Kurdistan. It is a very developed online store where customers can buy high quality items with real guarantee at the best prices.';
  String get darkMode => _localizedValues[locale.languageCode]?['darkMode'] ?? 'Dark Mode';
  String get darkThemeEnabled => _localizedValues[locale.languageCode]?['darkThemeEnabled'] ?? 'Dark theme is enabled';
  String get lightThemeEnabled => _localizedValues[locale.languageCode]?['lightThemeEnabled'] ?? 'Light theme is enabled';
  String get currentRole => _localizedValues[locale.languageCode]?['currentRole'] ?? 'Current Role';
  String get roleNotSet => _localizedValues[locale.languageCode]?['roleNotSet'] ?? 'Not Set';
  String get switchRoleDescription => _localizedValues[locale.languageCode]?['switchRoleDescription'] ?? 'Switch between Company Products and Seller Products roles';
  String get ended => _localizedValues[locale.languageCode]?['ended'] ?? 'Ended';
  String get user => _localizedValues[locale.languageCode]?['user'] ?? 'User';
  String get rewardBalance => _localizedValues[locale.languageCode]?['rewardBalance'] ?? 'Reward Balance';
  String get day => _localizedValues[locale.languageCode]?['day'] ?? 'Day';
  String get days => _localizedValues[locale.languageCode]?['days'] ?? 'Days';
  String get hour => _localizedValues[locale.languageCode]?['hour'] ?? 'Hr';
  String get hours => _localizedValues[locale.languageCode]?['hours'] ?? 'Hrs';
  String get minute => _localizedValues[locale.languageCode]?['minute'] ?? 'Min';
  String get minutes => _localizedValues[locale.languageCode]?['minutes'] ?? 'Mins';
  String get second => _localizedValues[locale.languageCode]?['second'] ?? 'Sec';
  String get seconds => _localizedValues[locale.languageCode]?['seconds'] ?? 'Secs';
  String get noCategoriesAvailable => _localizedValues[locale.languageCode]?['noCategoriesAvailable'] ?? 'No categories available';
  String get productDetails => _localizedValues[locale.languageCode]?['productDetails'] ?? 'Product Details';
  String get productNotFound => _localizedValues[locale.languageCode]?['productNotFound'] ?? 'Product not found';
  String get loginOrRegister => _localizedValues[locale.languageCode]?['loginOrRegister'] ?? 'Login or register';
  String get noBidsYet => _localizedValues[locale.languageCode]?['noBidsYet'] ?? 'No bids yet';
  String get bids => _localizedValues[locale.languageCode]?['bids'] ?? 'Bids';
  String get bidders => _localizedValues[locale.languageCode]?['bidders'] ?? 'Bidders';
  String get views => _localizedValues[locale.languageCode]?['views'] ?? 'Views';
  String get productId => _localizedValues[locale.languageCode]?['productId'] ?? 'Product ID';
  String get realPrice => _localizedValues[locale.languageCode]?['realPrice'] ?? 'Real Price';
  String get condition => _localizedValues[locale.languageCode]?['condition'] ?? 'Condition';
  String get sellerInformation => _localizedValues[locale.languageCode]?['sellerInformation'] ?? 'Seller Information';
  String get seller => _localizedValues[locale.languageCode]?['seller'] ?? 'Seller';
  String get description => _localizedValues[locale.languageCode]?['description'] ?? 'Description';
  String get modelName => _localizedValues[locale.languageCode]?['modelName'] ?? 'Model Name';
  String get brand => _localizedValues[locale.languageCode]?['brand'] ?? 'Brand';
  String get others => _localizedValues[locale.languageCode]?['others'] ?? 'Others';
  String get aboutThisItem => _localizedValues[locale.languageCode]?['aboutThisItem'] ?? 'About this Item';
  String get noDescriptionProvided => _localizedValues[locale.languageCode]?['noDescriptionProvided'] ?? 'No description provided';
  String get bidHistory => _localizedValues[locale.languageCode]?['bidHistory'] ?? 'Bid History';
  String get anonymous => _localizedValues[locale.languageCode]?['anonymous'] ?? 'Anonymous';
  String get placeBid => _localizedValues[locale.languageCode]?['placeBid'] ?? 'Place Bid';
  String get justNow => _localizedValues[locale.languageCode]?['justNow'] ?? 'Just now';
  String get deleteProduct => _localizedValues[locale.languageCode]?['deleteProduct'] ?? 'Delete Product';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get productDeletedSuccessfully => _localizedValues[locale.languageCode]?['productDeletedSuccessfully'] ?? 'Product deleted successfully';
  String get failedToDeleteProduct => _localizedValues[locale.languageCode]?['failedToDeleteProduct'] ?? 'Failed to delete product';
  String get notSpecified => _localizedValues[locale.languageCode]?['notSpecified'] ?? 'Not Specified';
  String get newCondition => _localizedValues[locale.languageCode]?['newCondition'] ?? 'New';
  String get usedCondition => _localizedValues[locale.languageCode]?['usedCondition'] ?? 'Used';
  String get workingCondition => _localizedValues[locale.languageCode]?['workingCondition'] ?? 'Working';
  String get productPendingApproval => _localizedValues[locale.languageCode]?['productPendingApproval'] ?? 'This product is pending admin approval. Bidding will be available once approved.';
  String get cannotBidOwnProduct => _localizedValues[locale.languageCode]?['cannotBidOwnProduct'] ?? 'You cannot bid on your own product.';
  String get product => _localizedValues[locale.languageCode]?['product'] ?? 'Product';
  String get timeRemaining => _localizedValues[locale.languageCode]?['timeRemaining'] ?? 'Time Remaining';
  String get areYouSureDelete => _localizedValues[locale.languageCode]?['areYouSureDelete'] ?? 'Are you sure you want to delete';
  String get cannotBeUndone => _localizedValues[locale.languageCode]?['cannotBeUndone'] ?? 'This action cannot be undone.';
  String get ago => _localizedValues[locale.languageCode]?['ago'] ?? 'ago';
  String get noBidsYetFirst => _localizedValues[locale.languageCode]?['noBidsYetFirst'] ?? 'No bids yet. Be the first to bid!';
  String get quickActions => _localizedValues[locale.languageCode]?['quickActions'] ?? 'Quick Actions';
  String get wallet => _localizedValues[locale.languageCode]?['wallet'] ?? 'Wallet';
  String get logoutConfirm => _localizedValues[locale.languageCode]?['logoutConfirm'] ?? 'Are you sure you want to logout?';
  String get inviteAndEarn => _localizedValues[locale.languageCode]?['inviteAndEarn'] ?? 'Invite & Earn';
  String get yourReferralCode => _localizedValues[locale.languageCode]?['yourReferralCode'] ?? 'Your Referral Code';
  String get copy => _localizedValues[locale.languageCode]?['copy'] ?? 'Copy';
  String get share => _localizedValues[locale.languageCode]?['share'] ?? 'Share';
  String get referralHistory => _localizedValues[locale.languageCode]?['referralHistory'] ?? 'Referral History';
  String get noReferralsYet => _localizedValues[locale.languageCode]?['noReferralsYet'] ?? 'No referrals yet';
  String get loadMore => _localizedValues[locale.languageCode]?['loadMore'] ?? 'Load More';
  String get unknown => _localizedValues[locale.languageCode]?['unknown'] ?? 'Unknown';
  String get awarded => _localizedValues[locale.languageCode]?['awarded'] ?? 'Awarded';
  String get pending => _localizedValues[locale.languageCode]?['pending'] ?? 'Pending';
  String get revoked => _localizedValues[locale.languageCode]?['revoked'] ?? 'Revoked';
  String get referralCodeCopied => _localizedValues[locale.languageCode]?['referralCodeCopied'] ?? 'Referral code copied to clipboard!';
  String get failedToShareReferral => _localizedValues[locale.languageCode]?['failedToShareReferral'] ?? 'Failed to share referral link';
  String get failedToLoadReferralData => _localizedValues[locale.languageCode]?['failedToLoadReferralData'] ?? 'Failed to load referral data';
  String get failedToLoadReferralInfo => _localizedValues[locale.languageCode]?['failedToLoadReferralInfo'] ?? 'Failed to load referral information';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'IRAQ BID',
      'home': 'Home',
      'transactions': 'Transactions',
      'contactUs': 'Contact Us',
      'aboutUs': 'About Us',
      'shareApp': 'Share this App',
      'loginSignUp': 'Login/Sign Up',
      'language': 'Language',
      'notLoggedIn': 'Not Logged In',
      'loginRequired': 'You need to be logged in to access the full features of this app',
      'welcome': 'Welcome to IRAQ BID',
      'enterPhone': 'Enter your phone number to get started',
      'phoneNumber': 'Phone Number',
      'referralCode': 'Referral Code (Optional)',
      'sendOtp': 'Send OTP',
      'otpSent': 'OTP will be sent to your phone via SMS',
      'dontHaveAccount': "Don't have an account?",
      'signUp': 'Sign Up',
      'contactUsContent': 'Email: info@iqbidmaster.com\nPhone: +964 750 352 3322',
      'aboutUsTitle': 'About IQ BidMaster',
      'aboutUsContent': 'IQ BidMaster is the first online auction platform in Iraq and Kurdistan. It is a very developed online store where customers can buy high quality items with real guarantee at the best prices.',
      'categories': 'Categories',
      'electronics': 'Electronics',
      'fashion': 'Fashion',
      'furniture': 'Furniture',
      'homeAppliances': 'Home Appliances',
      'laptops': 'Laptops',
      'mobile': 'Mobile',
      'mobiles': 'Mobiles',
      'property': 'Property',
      'collectibles': 'Collectibles',
      'iraqiBid': 'IRAQ BID',
      'english': 'English',
      'property': 'Property',
      'search': 'Search',
      'myBids': 'My Bids',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'logout': 'Logout',
      'settings': 'Settings',
      'verifyPhone': 'Verify Your Phone',
      'otpSentMessage': 'We sent a code to',
      'enterOtp': 'Enter OTP',
      'verify': 'Verify',
      'resendOtp': 'Resend OTP',
      'invalidOtp': 'Invalid OTP',
      'invalidPhone': 'Invalid Phone Number',
      'onlyIraqNumbers': 'Only Iraq (+964) numbers are allowed.',
      'enterValidPhone': 'Please enter a valid phone number',
      'phoneMustBe10Digits': 'Phone number must be exactly 10 digits',
      'otpSentToPhone': 'OTP sent to your phone. Please check your SMS.',
      'failedToSendOtp': 'Failed to send OTP. Please try again.',
      'phoneNotRegistered': 'Phone number not registered. Please contact administrator.',
      'invalidPhoneFormat': 'Invalid phone number format. Please check and try again.',
      'enter6DigitOtp': 'Please enter the 6-digit OTP',
      'all': 'All',
      'allProducts': 'All Products',
      'selectCategory': 'Select Category',
      'failedToLoadProducts': 'Failed to load products',
      'retry': 'Retry',
      'noProductsFound': 'No products found',
      'tryAdjustingSearch': 'Try adjusting your search or filters',
      'close': 'Close',
      'english': 'English',
      'exitApp': 'Exit App',
      'exitAppMessage': 'Do you want to exit the app?',
      'cancel': 'Cancel',
      'exit': 'Exit',
      'noProductsYet': 'No products yet',
      'createFirstProduct': 'Create your first product to start selling',
      'createProduct': 'Create Product',
      'company': 'Company',
      'companyProducts': 'Company Products',
      'wishlist': 'Wishlist',
      'wins': 'Wins',
      'notification': 'Notification',
      'day': 'Day',
      'days': 'Days',
      'hour': 'Hr',
      'hours': 'Hrs',
      'minute': 'Min',
      'minutes': 'Mins',
      'second': 'Sec',
      'seconds': 'Secs',
      'pending': 'Pending',
    },
    'ar': {
      'appName': 'IQ BidMaster',
      'home': 'الرئيسية',
      'transactions': 'المعاملات',
      'contactUs': 'اتصل بنا',
      'aboutUs': 'من نحن',
      'shareApp': 'شارك التطبيق',
      'loginSignUp': 'تسجيل الدخول / التسجيل',
      'language': 'اللغة',
      'notLoggedIn': 'غير مسجل الدخول',
      'loginRequired': 'تحتاج إلى تسجيل الدخول للوصول إلى جميع ميزات هذا التطبيق',
      'welcome': 'مرحباً بك في IQ BidMaster',
      'enterPhone': 'أدخل رقم هاتفك للبدء',
      'phoneNumber': 'رقم الهاتف',
      'referralCode': 'رمز الإحالة (اختياري)',
      'sendOtp': 'إرسال رمز التحقق',
      'otpSent': 'سيتم إرسال رمز التحقق إلى هاتفك عبر الرسائل النصية',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'signUp': 'سجل الآن',
      'categories': 'الفئات',
      'electronics': 'إلكترونيات',
      'fashion': 'أزياء',
      'furniture': 'أثاث',
      'homeAppliances': 'أجهزة منزلية',
      'laptops': 'أجهزة كمبيوتر محمولة',
      'mobile': 'جوال',
      'mobiles': 'جوالات',
      'property': 'عقارات',
      'collectibles': 'المقتنيات',
      'iraqiBid': 'Iraq Bid',
      'english': 'الإنجليزية',
      'search': 'بحث',
      'myBids': 'مزايداتي',
      'profile': 'الملف الشخصي',
      'notifications': 'الإشعارات',
      'logout': 'تسجيل الخروج',
      'settings': 'الإعدادات',
      'verifyPhone': 'تحقق من هاتفك',
      'otpSentMessage': 'أرسلنا رمزاً إلى',
      'enterOtp': 'أدخل رمز التحقق',
      'verify': 'تحقق',
      'resendOtp': 'إعادة إرسال رمز التحقق',
      'invalidOtp': 'رمز التحقق غير صحيح',
      'invalidPhone': 'رقم الهاتف غير صحيح',
      'onlyIraqNumbers': 'يُسمح بأرقام العراق (+964) فقط.',
      'enterValidPhone': 'يرجى إدخال رقم هاتف صحيح',
      'phoneMustBe10Digits': 'يجب أن يكون رقم الهاتف 10 أرقام بالضبط',
      'otpSentToPhone': 'تم إرسال رمز التحقق إلى هاتفك. يرجى التحقق من رسائلك النصية.',
      'failedToSendOtp': 'فشل إرسال رمز التحقق. يرجى المحاولة مرة أخرى.',
      'phoneNotRegistered': 'رقم الهاتف غير مسجل. يرجى الاتصال بالمسؤول.',
      'invalidPhoneFormat': 'تنسيق رقم الهاتف غير صحيح. يرجى التحقق والمحاولة مرة أخرى.',
      'enter6DigitOtp': 'يرجى إدخال رمز التحقق المكون من 6 أرقام',
      'all': 'الكل',
      'allProducts': 'جميع المنتجات',
      'selectCategory': 'اختر الفئة',
      'failedToLoadProducts': 'فشل تحميل المنتجات',
      'retry': 'إعادة المحاولة',
      'noProductsFound': 'لم يتم العثور على منتجات',
      'tryAdjustingSearch': 'حاول تعديل البحث أو المرشحات',
      'close': 'إغلاق',
      'exitApp': 'إغلاق التطبيق',
      'exitAppMessage': 'هل تريد إغلاق التطبيق؟',
      'cancel': 'إلغاء',
      'exit': 'خروج',
      'failedToLoadProducts': 'فشل تحميل المنتجات',
      'noProductsYet': 'لا توجد منتجات بعد',
      'createFirstProduct': 'أنشئ منتجك الأول للبدء في البيع',
      'createProduct': 'إنشاء منتج',
      'company': 'الشركة',
      'wishlist': 'قائمة الرغبات',
      'wins': 'الفوز',
      'notification': 'الإشعارات',
      'pleaseLoginFirst': 'يرجى تسجيل الدخول أولاً',
      'roleSwitched': 'تم تغيير الدور إلى',
      'sellerProducts': 'منتجات البائع',
      'companyProducts': 'منتجات الشركة',
      'failedToSwitchRole': 'فشل تغيير الدور',
      'viewAll': 'عرض الكل',
      'noCompanyProducts': 'لا توجد منتجات للشركة متاحة',
      'noSellerProducts': 'لا توجد منتجات بائع بعد',
      'iraqiBid': 'Iraq Bid',
      'addProduct': 'إضافة منتج',
      'searchHereProduct': 'ابحث عن المنتج هنا',
      'searchOutCategory': 'ابحث عن الفئة',
      'emailPhone': 'البريد الإلكتروني: info@iqbidmaster.com\nالهاتف: +964 750 352 3322',
      'aboutDescription': 'IQ BidMaster هو أول منصة مزادات عبر الإنترنت في العراق وكردستان. إنه متجر إلكتروني متطور جداً حيث يمكن للعملاء شراء منتجات عالية الجودة بضمان حقيقي بأفضل الأسعار.',
      'darkMode': 'الوضع الداكن',
      'darkThemeEnabled': 'الوضع الداكن مفعّل',
      'lightThemeEnabled': 'الوضع الفاتح مفعّل',
      'currentRole': 'الدور الحالي',
      'roleNotSet': 'غير محدد',
      'switchRoleDescription': 'التبديل بين أدوار منتجات الشركة ومنتجات البائع',
      'ended': 'انتهى',
      'user': 'المستخدم',
      'rewardBalance': 'رصيد المكافآت',
      'day': 'يوم',
      'days': 'أيام',
      'hour': 'ساعة',
      'hours': 'ساعات',
      'minute': 'دقيقة',
      'minutes': 'دقائق',
      'contactUsContent': 'البريد الإلكتروني: info@iqbidmaster.com\nالهاتف: +964 750 352 3322',
      'aboutUsTitle': 'عن IQ BidMaster',
      'aboutUsContent': 'IQ BidMaster هو أول منصة مزادات عبر الإنترنت في العراق وكردستان. إنه متجر إلكتروني متطور جداً حيث يمكن للعملاء شراء منتجات عالية الجودة بضمان حقيقي بأفضل الأسعار.',
      'second': 'ثانية',
      'seconds': 'ثواني',
      'noCategoriesAvailable': 'لا توجد فئات متاحة',
      'productDetails': 'تفاصيل المنتج',
      'productNotFound': 'المنتج غير موجود',
      'loginOrRegister': 'تسجيل الدخول أو التسجيل',
      'noBidsYet': 'لا توجد مزايدات بعد',
      'bids': 'المزايدات',
      'bidders': 'المزايدون',
      'views': 'المشاهدات',
      'productId': 'معرف المنتج',
      'realPrice': 'السعر الحقيقي',
      'condition': 'الحالة',
      'sellerInformation': 'معلومات البائع',
      'seller': 'البائع',
      'description': 'الوصف',
      'modelName': 'اسم الموديل',
      'brand': 'العلامة التجارية',
      'others': 'أخرى',
      'aboutThisItem': 'حول هذا العنصر',
      'noDescriptionProvided': 'لا يوجد وصف متاح',
      'bidHistory': 'تاريخ المزايدة',
      'anonymous': 'مجهول',
      'loginRequired': 'تسجيل الدخول مطلوب',
      'placeBid': 'تقديم مزايدة',
      'justNow': 'الآن',
      'deleteProduct': 'حذف المنتج',
      'delete': 'حذف',
      'productDeletedSuccessfully': 'تم حذف المنتج بنجاح',
      'failedToDeleteProduct': 'فشل حذف المنتج',
      'notSpecified': 'غير محدد',
      'newCondition': 'جديد',
      'usedCondition': 'مستعمل',
      'workingCondition': 'يعمل',
      'productPendingApproval': 'هذا المنتج في انتظار موافقة المسؤول. ستكون المزايدة متاحة بعد الموافقة.',
      'cannotBidOwnProduct': 'لا يمكنك المزايدة على منتجك الخاص.',
      'product': 'المنتج',
      'timeRemaining': 'الوقت المتبقي',
      'areYouSureDelete': 'هل أنت متأكد أنك تريد حذف',
      'cannotBeUndone': 'لا يمكن التراجع عن هذا الإجراء.',
      'ago': 'منذ',
      'noBidsYetFirst': 'لا توجد مزايدات بعد. كن أول من يزايد!',
      'quickActions': 'إجراءات سريعة',
      'wallet': 'المحفظة',
      'logoutConfirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'inviteAndEarn': 'ادعُ واكسب',
      'yourReferralCode': 'رمز الإحالة الخاص بك',
      'copy': 'نسخ',
      'share': 'مشاركة',
      'referralHistory': 'تاريخ الإحالات',
      'noReferralsYet': 'لا توجد إحالات بعد',
      'loadMore': 'تحميل المزيد',
      'unknown': 'غير معروف',
      'awarded': 'ممنوح',
      'pending': 'قيد الانتظار',
      'revoked': 'ملغي',
      'referralCodeCopied': 'تم نسخ رمز الإحالة إلى الحافظة!',
      'failedToShareReferral': 'فشل مشاركة رابط الإحالة',
      'failedToLoadReferralData': 'فشل تحميل بيانات الإحالة',
      'failedToLoadReferralInfo': 'فشل تحميل معلومات الإحالة',
      'viewEditProfile': 'عرض وتعديل ملفك الشخصي',
      'switchRole': 'تبديل الدور',
      'viewWalletEarnings': 'عرض محفظتك وأرباحك',
      'manageNotifications': 'إدارة إشعاراتك',
      'viewSavedProducts': 'عرض منتجاتك المحفوظة',
      'viewWonAuctions': 'عرض المزادات التي فزت بها',
      'discover': 'اكتشف',
      'activeAuctions': 'المزادات النشطة',
      'switchRoleDescription': 'التبديل بين المشتري والبائع',
      'notifications': 'الإشعارات',
      'settings': 'الإعدادات',
      'loginSuccessful': 'تم تسجيل الدخول بنجاح! مرحباً',
      'toBidMaster': 'في BidMaster',
      'otpResent': 'تم إعادة إرسال رمز التحقق إلى هاتفك. يرجى التحقق من رسائلك النصية.',
      'changePhoneNumber': 'تغيير رقم الهاتف',
      'english': 'الإنجليزية',
    },
    'ku': {
      'appName': 'IQ BidMaster',
      'home': 'سەرەکی',
      'transactions': 'مامەڵەکان',
      'contactUs': 'پەیوەندی',
      'aboutUs': 'دەربارەمان',
      'shareApp': 'ئەپەکە هاوبەش بکە',
      'loginSignUp': 'چوونەژوورەوە / خۆتۆمارکردن',
      'language': 'زمان',
      'notLoggedIn': 'چوونەژوورەوە نەکراوە',
      'loginRequired': 'پێویستە چوونەژوورەوە بکەیت بۆ دەستگەیشتن بە هەموو تایبەتمەندیەکانی ئەم ئەپە',
      'welcome': 'بەخێربێیت بۆ IQ BidMaster',
      'enterPhone': 'ژمارەی تەلەفۆنەکەت بنووسە بۆ دەستپێکردن',
      'phoneNumber': 'ژمارەی تەلەفۆن',
      'referralCode': 'کۆدی داواتکردن (دڵخواز)',
      'sendOtp': 'کۆدی پشتڕاستکردنەوە بنێرە',
      'welcome': 'بەخێربێیت بۆ IQ BidMaster',
      'enterPhone': 'ژمارەی تەلەفۆنەکەت بنووسە بۆ دەستپێکردن',
      'phoneNumber': 'ژمارەی تەلەفۆن',
      'referralCode': 'کۆدی داواتکردن (دڵخواز)',
      'sendOtp': 'کۆدی پشتڕاستکردنەوە بنێرە',
      'otpSent': 'کۆدی پشتڕاستکردنەوە بە پەیامی دەستنووس بۆ تەلەفۆنەکەت دەنێردرێت',
      'dontHaveAccount': 'هیژمارت نییە؟',
      'signUp': 'خۆتۆمار بکە',
      'searchHereProduct': 'لێرە بۆ بەرهەم بگەڕێ',
      'searchOutCategory': 'بەدوای بەشدا بگەڕێ',
      'sellerProducts': 'بەرهەمەکانی فرۆشیار',
      'companyProducts': 'بەرهەمەکانی کۆمپانیا',
      'roleSwitched': 'ڕۆڵ گۆڕدرا بۆ',
      'viewAll': 'هەموو ببینە',
      'noCompanyProducts': 'هیچ بەرهەمێکی کۆمپانیا بەردەست نییە',
      'noSellerProducts': 'هیچ بەرهەمێکی فرۆشیار نییە تا ئێستا',
      'failedToSwitchRole': 'گۆڕینی ڕۆڵ سەرکەوتوو نەبوو',
      'addProduct': 'زیادکردنی بەرهەم',
      'darkMode': 'دۆخی تاریک',
      'darkThemeEnabled': 'دۆخی تاریک چالاک کرا',
      'lightThemeEnabled': 'دۆخی ڕووناک چالاک کرا',
      'currentRole': 'ڕۆڵی ئێستا',
      'roleNotSet': 'دیاری نەکراوە',
      'switchRoleDescription': 'گۆڕین لەنێوان ڕۆڵی بەرهەمەکانی کۆمپانیا و فرۆشیار',
      'ended': 'تەواو بوو',
      'user': 'بەکارهێنەر',
      'rewardBalance': 'باڵانسی پاداشت',
      'categories': 'بەشەکان',
      'electronics': 'ئەلیکترۆنی',
      'fashion': 'فەیشن',
      'furniture': 'فرنیچەر',
      'homeAppliances': 'ئامێرەکانی ماڵ',
      'laptops': 'لێپتۆپ',
      'mobile': 'مۆبایل',
      'mobiles': 'مۆبایل',
      'property': 'موڵک',
      'collectibles': 'کەلوپەلە کۆنەکان',
      'iraqiBid': 'Iraq Bid',
      'english': 'ئینگلیزی',
      'search': 'گەڕان',
      'myBids': 'مزایندەکانم',
      'profile': 'پرۆفایل',
      'notifications': 'ئاگاداریەکان',
      'logout': 'دەرچوون',
      'settings': 'ڕێکخستنەکان',
      'verifyPhone': 'تەلەفۆنەکەت پشتڕاست بکەوە',
      'otpSentMessage': 'کۆدێکمان نارد بۆ',
      'enterOtp': 'کۆدی پشتڕاستکردنەوە بنووسە',
      'verify': 'پشتڕاست بکەوە',
      'resendOtp': 'دووبارە کۆد بنێرە',
      'invalidOtp': 'کۆدی پشتڕاستکردنەوە نادروستە',
      'invalidPhone': 'ژمارەی تەلەفۆن نادروستە',
      'onlyIraqNumbers': 'تەنها ژمارەکانی عێراق (+964) ڕێگەپێدراون.',
      'enterValidPhone': 'تکایە ژمارەیەکی تەلەفۆنی دروست بنووسە',
      'phoneMustBe10Digits': 'ژمارەی تەلەفۆن دەبێت بەتەواوی 10 ژمارە بێت',
      'otpSentToPhone': 'کۆدی پشتڕاستکردنەوە نێردرا بۆ تەلەفۆنەکەت. تکایە پەیامەکەت بپشکنە.',
      'failedToSendOtp': 'ناردنی کۆدی پشتڕاستکردنەوە سەرکەوتوو نەبوو. تکایە دووبارە هەوڵ بدە.',
      'phoneNotRegistered': 'ژمارەی تەلەفۆن تۆمار نەکراوە. تکایە پەیوەندی بە بەڕێوەبەرەوە بکە.',
      'invalidPhoneFormat': 'شێوەی ژمارەی تەلەفۆن نادروستە. تکایە پشکنین بکە و دووبارە هەوڵ بدە.',
      'enter6DigitOtp': 'تکایە کۆدی پشتڕاستکردنەوەی 6 ژمارەیی بنووسە',
      'all': 'هەموو',
      'allProducts': 'هەموو بەرهەمەکان',
      'selectCategory': 'بەش هەڵبژێرە',
      'failedToLoadProducts': 'بارکردنی بەرهەمەکان سەرکەوتوو نەبوو',
      'retry': 'دووبارە هەوڵ بدە',
      'noProductsFound': 'هیچ بەرهەمێک نەدۆزرایەوە',
      'tryAdjustingSearch': 'هەوڵ بدە گەڕان یان فیلتەرەکان دەستکاری بکەیت',
      'close': 'داخستن',
      'exitApp': 'داخستنی ئەپ',
      'exitAppMessage': 'دەتەوێت ئەپەکە دابخەیت؟',
      'cancel': 'هەڵوەشاندنەوە',
      'exit': 'دەرچوون',
      'noProductsYet': 'هیچ بەرهەمێک نییە',
      'createFirstProduct': 'یەکەم بەرهەمەکەت دروست بکە بۆ دەستپێکردنی فرۆشتن',
      'createProduct': 'دروستکردنی بەرهەم',
      'company': 'کۆمپانیا',
      'wishlist': 'لیستی خوازراوەکان',
      'wins': 'بردنەوەکان',
      'notification': 'ئاگاداری',
      'day': 'ڕۆژ',
      'days': 'ڕۆژ',
      'hour': 'کاتژمێر',
      'hours': 'کاتژمێر',
      'minute': 'خولەک',
      'minutes': 'خولەک',
      'contactUsContent': 'ئیمەیڵ: info@iqbidmaster.com\nتەلەفۆن: +964 750 352 3322',
      'aboutUsTitle': 'دەربارەی IQ BidMaster',
      'aboutUsContent': 'IQ BidMaster یەکەم پلاتفۆرمی مەزادی ئۆنلاینە لە عێراق و کوردستان. فرۆشگایەکی ئۆنلاینی زۆر پێشکەوتووە کە تێیدا کڕیاران دەتوانن کاڵای کوالێتی بەرز بکڕن بە گرێنتی ڕاستەقینە و بە باشترین نرخ.',
      'second': 'چرکە',
      'seconds': 'چرکە',
      'pending': 'چاوەڕوان',
      'noCategoriesAvailable': 'هیچ بەشێک بەردەست نییە',
      'productDetails': 'وردەکاری بەرهەم',
      'productNotFound': 'بەرهەم نەدۆزرایەوە',
      'loginOrRegister': 'چوونەژوورەوە یان خۆتۆمارکردن',
      'noBidsYet': 'هیچ مزاینەیەک نەکراوە',
      'bids': 'مزاینەکان',
      'bidders': 'مزاینەکاران',
      'views': 'بینینەکان',
      'productId': 'ئایدی بەرهەم',
      'realPrice': 'نرخی ڕاستەقینە',
      'condition': 'دۆخ',
      'sellerInformation': 'زانیاری فرۆشیار',
      'seller': 'فرۆشیار',
      'description': 'وەسف',
      'modelName': 'ناوی مۆدێل',
      'brand': 'مارکە',
      'others': 'هیتر',
      'aboutThisItem': 'دەربارەی ئەم بەرهەمە',
      'noDescriptionProvided': 'هیچ وەسفێک دابین نەکراوە',
      'bidHistory': 'مێژووی مزاینە',
      'anonymous': 'نەناسراو',
      'placeBid': 'مزاینە بکە',
      'justNow': 'هەر ئێستا',
      'deleteProduct': 'سڕینەوەی بەرهەم',
      'delete': 'سڕینەوە',
      'productDeletedSuccessfully': 'بەرهەم بە سەرکەوتوویی سڕایەوە',
      'failedToDeleteProduct': 'سڕینەوەی بەرهەم سەرکەوتوو نەبوو',
      'notSpecified': 'دیاری نەکراوە',
      'newCondition': 'نوێ',
      'usedCondition': 'بەکارهاتوو',
      'workingCondition': 'کار دەکات',
      'productPendingApproval': 'ئەم بەرهەمە چاوەڕوانی ڕەزامەندی بەڕێوەبەرە. مزاینەکردن لە دوای ڕەزامەندی بەردەست دەبێت.',
      'cannotBidOwnProduct': 'ناتوانیت مزاینە لەسەر بەرهەمی خۆت بکەیت.',
      'product': 'بەرهەم',
      'timeRemaining': 'کاتی ماوە',
      'areYouSureDelete': 'دڵنیایت دەتەوێت بیسڕیتەوە',
      'cannotBeUndone': 'ئەم کردە و پاشگەزبوونەوەی نییە.',
      'ago': 'لەبەرواری',
      'noBidsYetFirst': 'هیچ مزاینەیەک نەکراوە. یەکەم کەس بە بۆ مزاینە!',
      'quickActions': 'کردارە خێراکان',
      'wallet': 'جزدان',
      'logoutConfirm': 'دڵنیایت دەتەوێت دەربچیت؟',
      'inviteAndEarn': 'بانگهێشت بکە و قازانج بکە',
      'yourReferralCode': 'کۆدی داواتکردنی تۆ',
      'copy': 'کۆپی',
      'share': 'هاوبەشکردن',
      'referralHistory': 'مێژووی بانگهێشت',
      'noReferralsYet': 'هیچ بانگهێشتێک نەکراوە',
      'loadMore': 'زیاتر نیشان بدە',
      'unknown': 'نەناسراو',
      'awarded': 'پاداشت دراوە',
      'revoked': 'هەڵوەشاوەتەوە',
      'referralCodeCopied': 'کۆدی بانگهێشت کۆپی کرا!',
      'failedToShareReferral': 'هاوبەشکردنی بەستەری بانگهێشت سەرکەوتوو نەبوو',
      'failedToLoadReferralData': 'بارکردنی داتای بانگهێشت سەرکەوتوو نەبوو',
      'failedToLoadReferralInfo': 'بارکردنی زانیاری بانگهێشت سەرکەوتوو نەبوو',
      'loginSuccessful': 'چوونەژوورەوە سەرکەوتوو بوو! بەخێربێیت',
      'toBidMaster': 'بۆ BidMaster',
      'otpResent': 'کۆدی پشتڕاستکردنەوە دووبارە نێردرا. تکایە نامەکانت بپشکنە.',
      'changePhoneNumber': 'گۆڕینی ژمارەی تەلەفۆن',
      'exitApp': 'داخستنی ئەپ',
      'exitAppMessage': 'دەتەوێت ئەپەکە دابخەیت؟',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'ku'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Always use the locale from LanguageService to ensure Kurdish works
    // Use languageNotifier.value to get current language (reactive)
    final actualLocale = LanguageService.languageNotifier.value;
    return AppLocalizations(actualLocale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


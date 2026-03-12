import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_links/app_links.dart';
import 'app/router/app_router.dart';
import 'app/theme/theme.dart';
import 'app/services/storage_service.dart';
import 'app/services/referral_service.dart';
import 'app/services/theme_service.dart';
import 'app/services/language_service.dart';
import 'app/services/app_localizations.dart';
import 'app/services/socket_service.dart';
import 'app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Error handling to prevent white screen
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    // In release mode, silently handle errors to prevent crashes
    // Errors are logged internally by Flutter
  };
  
  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('❌ Platform Error: $error');
      print('Stack: $stack');
    }
    return true; // Prevent app from crashing
  };
  
  try {
    // Initialize SharedPreferences before any navigation
    // This prevents white screen in release mode
    await SharedPreferences.getInstance();
    
    // Initialize GetStorage for theme persistence
    await GetStorage.init();
    
    // Check for existing session and auto-login
    // Auto-login works in both debug and release mode (as per requirements)
    await _checkAutoLogin();
    
    // Initialize deep link handling for referral codes
    _initDeepLinks();

    // Initialize New Services
    socketService.init();
    notificationService.init();
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Catch any initialization errors
    if (kDebugMode) {
      print('❌ Initialization Error: $e');
      print('Stack: $stackTrace');
    }
    // Still run app even if initialization fails
    runApp(const MyApp());
  }
}

Future<void> _checkAutoLogin() async {
  final isLoggedIn = await StorageService.isLoggedIn();
  if (isLoggedIn) {
    // Verify token is still valid by checking role
    final role = await StorageService.getUserRole();
    if (role == null) {
      // Invalid session - clear storage
      await StorageService.clearAll();
    } else if (role == 'admin') {
      // Admin should not access mobile app - clear storage
      await StorageService.clearAll();
    }
    // Token is valid - user will be redirected by router
  }
}

/// Initialize deep link handling for referral codes
void _initDeepLinks() {
  final appLinks = AppLinks();
  
  // Handle initial link (if app was opened via deep link)
  appLinks.getInitialLink().then((Uri? uri) {
    if (uri != null) {
      ReferralService.handleDeepLink(uri.toString());
    }
  }).catchError((err) {
    if (kDebugMode) {
      print('❌ Error getting initial link: $err');
    }
  });

  // Handle links while app is running
  appLinks.uriLinkStream.listen((Uri uri) {
    ReferralService.handleDeepLink(uri.toString());
  }, onError: (err) {
    if (kDebugMode) {
      print('❌ Error listening to links: $err');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.themeNotifier.addListener(_onThemeChanged);
    // Listen to language changes
    LanguageService.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    ThemeService.themeNotifier.removeListener(_onThemeChanged);
    LanguageService.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageService.languageNotifier,
          builder: (context, locale, child) {
            // Determine text direction based on locale
            // Both Arabic and Kurdish are RTL languages
            final textDirection = (locale.languageCode == 'ar' || locale.languageCode == 'ku')
                ? TextDirection.rtl 
                : TextDirection.ltr;
            
            // For Kurdish, use English locale for Material widgets (since Flutter doesn't support Kurdish)
            // Our AppLocalizations will still use Kurdish via LanguageService
            final materialLocale = locale.languageCode == 'ku' 
                ? const Locale('en', 'US') 
                : locale;
            
            return Directionality(
              textDirection: textDirection,
              child: GestureDetector(
                onTertiaryLongPress: () {
                  // Secret 3-finger long press to toggle screenshot mode (hide status bar)
                  // Note: On Windows emulator, try to find a way to simulate this or use the method below
                },
                onLongPressStart: (details) {
                  // If user holds with multiple fingers (simulated)
                  if (details.localPosition.dx < 50 && details.localPosition.dy < 50) {
                     // Debug corner trigger
                  }
                },
                child: MaterialApp.router(
                  title: 'IRAQ BID',
                  debugShowCheckedModeBanner: false, // ✅ Remove debug banner for App Store
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  // smooth transition is handled by MaterialApp's internal AnimatedTheme
                  themeAnimationDuration: const Duration(milliseconds: 300),
                  themeAnimationCurve: Curves.easeInOut,
                  // Screenshot helper listener
                  builder: (context, child) {
                    return Scaffold(
                      body: RawKeyboardListener(
                        focusNode: FocusNode(),
                        autofocus: true,
                        onKey: (event) {
                          if (event.logicalKey == LogicalKeyboardKey.keyS && event is RawKeyDownEvent) {
                            // Toggle UI visibility for screenshots
                            SystemChrome.setEnabledSystemUIMode(
                              (View.of(context).platformDispatcher.views.first.devicePixelRatio > 0) 
                              ? SystemUiMode.manual 
                              : SystemUiMode.edgeToEdge, 
                              overlays: []
                            );
                          }
                        },
                        child: child ?? const SizedBox(),
                      ),
                    );
                  },
                locale: materialLocale, // Use English for Kurdish to avoid MaterialLocalizations errors
                supportedLocales: const [
                  Locale('en', 'US'), // English
                  Locale('ar', 'IQ'), // Arabic (RTL)
                  // Note: Kurdish (ku_IQ) not in supportedLocales for Material widgets
                  // but our AppLocalizations still supports it
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: AppRouter.router,
              ),
            );
          },
        );
      },
    );
  }
}

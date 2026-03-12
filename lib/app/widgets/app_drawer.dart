import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../services/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'theme_toggle_tile.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;
  String? _userName;
  String _selectedLanguage = 'English';

  // Orange colors for warning/notification (theme-independent)
  static const Color _orangeBg = Color(0xFFFFE5CC);
  static const Color _orangeText = Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadLanguage();
    // Listen to language changes
    LanguageService.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageService.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _selectedLanguage = LanguageService.getLanguageName();
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    final userName = await StorageService.getUserName();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _userName = userName;
    });
  }

  void _loadLanguage() {
    setState(() {
      _selectedLanguage = LanguageService.getLanguageName();
    });
  }


  void _selectLanguage(String language) {
    if (_selectedLanguage != language) {
      LanguageService.setLanguage(language);
      // Update selected language immediately
      setState(() {
        _selectedLanguage = language;
      });
      // Language will update automatically via listener
      // Close drawer after language change
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _shareApp() {
    Share.share(
      'Check out IRAQ BID - The best auction platform!',
      subject: 'IRAQ BID App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Not Logged In Section
            if (!_isLoggedIn) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                color: _orangeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.notLoggedIn ?? 'Not Logged In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _orangeText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.loginRequired ?? 'You need to be logged in to access the full features of this app',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Home
                  _DrawerMenuItem(
                    icon: Icons.home,
                    label: AppLocalizations.of(context)?.home ?? 'Home',
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      // Use go to navigate to home (replaces current route)
                      context.go('/home');
                    },
                  ),

                  // Contact Us
                  _DrawerMenuItem(
                    icon: Icons.phone,
                    label: AppLocalizations.of(context)?.contactUs ?? 'Contact Us',
                    onTap: () {
                      Navigator.pop(context);
                      final l10n = AppLocalizations.of(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n?.contactUs ?? 'Contact Us'),
                          content: Text(l10n?.contactUsContent ?? 'Email: info@iqbidmaster.com\nPhone: +964 750 352 3322'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n?.close ?? 'Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // About Us
                  _DrawerMenuItem(
                    icon: Icons.info,
                    label: AppLocalizations.of(context)?.aboutUs ?? 'About Us',
                    onTap: () {
                      Navigator.pop(context);
                      final l10n = AppLocalizations.of(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n?.aboutUsTitle ?? 'About IQ BidMaster'),
                          content: Text(
                            l10n?.aboutUsContent ?? 'IQ BidMaster is the first online auction platform in Iraq and Kurdistan. It is a very developed online store where customers can buy high quality items with real guarantee at the best prices.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n?.close ?? 'Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Share this App
                  _DrawerMenuItem(
                    icon: Icons.share,
                    label: AppLocalizations.of(context)?.shareApp ?? 'Share this App',
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp();
                    },
                  ),

                  Divider(height: 1, color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB)),

                  // Theme Toggle (Light/Dark Mode)
                  const ThemeToggleTile(),

                  Divider(height: 1, color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB)),

                  // Language Selection
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.language ?? 'Language',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LanguageButton(
                                label: 'عربي',
                                isSelected: _selectedLanguage == 'Arabic',
                                onTap: () => _selectLanguage('Arabic'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LanguageButton(
                                label: 'کوردی',
                                isSelected: _selectedLanguage == 'Kurdish',
                                onTap: () => _selectLanguage('Kurdish'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LanguageButton(
                                label: 'English',
                                isSelected: _selectedLanguage == 'English',
                                onTap: () => _selectLanguage('English'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
              ),
            ),

            // Login/Sign Up Button
            if (!_isLoggedIn) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.loginSignUp ?? 'Login/Sign Up',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Drawer Menu Item Widget
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      enabled: isEnabled,
      onTap: onTap,
    );
  }
}

// Language Button Widget
class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

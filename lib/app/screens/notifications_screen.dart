import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _filter; // 'all', 'read', 'unread'

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadNotifications();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();

    if (!isLoggedIn || accessToken == null) {
      if (mounted) {
        setState(() {
          _errorMessage = LanguageService.isArabic ? 'يرجى تسجيل الدخول أولاً' : 'Please login first';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool? readFilter;
      if (_filter == 'read') {
        readFilter = true;
      } else if (_filter == 'unread') {
        readFilter = false;
      }

      final notifications = await apiService.getNotifications(read: readFilter);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await apiService.markNotificationAsRead(id);
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await apiService.markAllNotificationsAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.isArabic
                  ? 'تم تحديد جميع الإشعارات كمقروءة'
                  : 'All notifications marked as read',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'مركز الإشعارات' : 'Notifications',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isAr ? 'تحديد الكل كمقروء' : 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF0284C7)),
            onPressed: _markAllAsRead,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  _buildFilterChip(label: isAr ? 'الكل' : 'All', value: null),
                  const SizedBox(width: 8),
                  _buildFilterChip(label: isAr ? 'غير مقروء' : 'Unread', value: 'unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip(label: isAr ? 'مقروء' : 'Read', value: 'read'),
                ],
              ),
            ),

            // Notification Content List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadNotifications,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState(isAr)
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: RefreshIndicator(
                                onRefresh: _loadNotifications,
                                color: const Color(0xFF0284C7),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  itemCount: _notifications.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final n = _notifications[index];
                                    return _buildNotificationCard(n, isAr);
                                  },
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String? value}) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadNotifications();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n, bool isAr) {
    IconData icon = Icons.notifications_rounded;
    Color iconColor = const Color(0xFF0284C7);
    Color iconBg = const Color(0xFF0284C7).withValues(alpha: 0.1);

    final titleLower = (n.title).toLowerCase();
    if (titleLower.contains('bid') || titleLower.contains('outbid')) {
      icon = Icons.gavel_rounded;
      iconColor = const Color(0xFFF59E0B);
      iconBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
    } else if (titleLower.contains('won') || titleLower.contains('win')) {
      icon = Icons.emoji_events_rounded;
      iconColor = const Color(0xFF10B981);
      iconBg = const Color(0xFF10B981).withValues(alpha: 0.1);
    } else if (titleLower.contains('wallet') || titleLower.contains('deposit')) {
      icon = Icons.account_balance_wallet_rounded;
      iconColor = const Color(0xFF6366F1);
      iconBg = const Color(0xFF6366F1).withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () {
        if (!n.read) {
          _markAsRead(n.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.read ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.read ? const Color(0xFFE2E8F0) : const Color(0xFFBAE6FD),
            width: n.read ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(n.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAr ? 'لا توجد إشعارات حتى الآن' : 'No notifications yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'ستظهر هنا تحديثات المزادات المباشرة، وتنبيهات المزايدة والفوز'
                  : 'Live auction alerts, outbid notices and winning tickets will appear here',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

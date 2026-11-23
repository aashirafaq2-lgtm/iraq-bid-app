import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class VipContainersScreen extends StatefulWidget {
  const VipContainersScreen({super.key});

  @override
  State<VipContainersScreen> createState() => _VipContainersScreenState();
}

class _VipContainersScreenState extends State<VipContainersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isVipBidder = false;
  List<dynamic> _containers = [];
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadVipStatusAndContainers();
    _startCountdownTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTicker() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadVipStatusAndContainers() async {
    try {
      final statusRes = await _apiService.getVipStatus();
      if (statusRes != null && statusRes['canBid'] == true) {
        _isVipBidder = true;
      }
    } catch (_) {}

    try {
      final containers = await _apiService.getVipContainers();
      if (mounted) {
        setState(() {
          _containers = containers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0728), // Deep Royal Purple/Navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF160938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 24),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'مزادات VIP الحصرية' : 'VIP Bidders Exclusive',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  // COMING SOON BADGE
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF1E0A3C), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'قريباً في التحديث القادم' : 'COMING SOON IN NEXT UPDATE',
                          style: const TextStyle(
                            color: Color(0xFF1E0A3C),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. VIP Header Banner matching Screenshot 6
                  _buildHeaderBanner(isArabic),

                  const SizedBox(height: 18),

                  // 2. 3 Tier Badges Row (Normal, Silver, Gold)
                  _buildTiersSummaryRow(isArabic),

                  const SizedBox(height: 20),

                  // 3. Container Cards
                  if (_containers.isEmpty)
                    _buildFallbackContainers(isArabic)
                  else
                    ..._containers.map((c) => _buildContainerCard(c, isArabic)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF3B1376),
            Color(0xFF190638),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 48),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFDF00), Color(0xFFF59E0B), Color(0xFFFFFBEB)],
            ).createShader(bounds),
            child: const Text(
              'VIP BIDDERS',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isArabic ? 'مزادات الحاويات الحصرية' : 'CONTAINER AUCTIONS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
              Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
              Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
              Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
              Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiersSummaryRow(bool isArabic) {
    return Row(
      children: [
        _buildTierSummaryCard('Normal Container', 'Great Products', const Color(0xFF0284C7), Icons.inventory_2_outlined, isArabic),
        const SizedBox(width: 8),
        _buildTierSummaryCard('Silver Container', 'Higher Value', const Color(0xFF94A3B8), Icons.military_tech_outlined, isArabic),
        const SizedBox(width: 8),
        _buildTierSummaryCard('Gold Container', 'Premium & Exclusive', const Color(0xFFEAB308), Icons.workspace_premium_rounded, isArabic),
      ],
    );
  }

  Widget _buildTierSummaryCard(String title, String sub, Color accent, IconData iconData, bool isArabic) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Icon(iconData, color: accent, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerCard(dynamic c, bool isArabic) {
    final code = c['code'] ?? '#G-102';
    final tier = (c['tier'] ?? 'gold').toString().toLowerCase();
    final categoryLabel = c['category_label'] ?? 'High Value Items';
    final bidders = c['registered_bidders_count'] ?? 20;

    Color badgeColor;
    Color borderColor;
    String tierTitle;
    IconData tierIcon;

    if (tier == 'gold') {
      badgeColor = const Color(0xFFEAB308);
      borderColor = const Color(0xFFFFD700);
      tierTitle = 'Gold Container';
      tierIcon = Icons.workspace_premium_rounded;
    } else if (tier == 'silver') {
      badgeColor = const Color(0xFF94A3B8);
      borderColor = const Color(0xFFCBD5E1);
      tierTitle = 'Silver Container';
      tierIcon = Icons.military_tech_outlined;
    } else {
      badgeColor = const Color(0xFF38BDF8);
      borderColor = const Color(0xFF0284C7);
      tierTitle = 'Normal Container';
      tierIcon = Icons.inventory_2_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0D42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Tier Badge + Container Code + Info Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tierIcon, color: badgeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      tierTitle,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 18),
            ],
          ),

          const SizedBox(height: 10),

          // Middle row: Container 3D Box Illustration + Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Cargo Container Mock Graphic
              Container(
                width: 100,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tier == 'gold'
                        ? [const Color(0xFFF59E0B), const Color(0xFFB45309)]
                        : (tier == 'silver'
                            ? [const Color(0xFF94A3B8), const Color(0xFF475569)]
                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor.withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Title, Category & Countdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Container $code',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFFF59E0B), size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            categoryLabel,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Starts In
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'يبدأ خلال' : 'Starts In',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                            const Text(
                              '00:14:36',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // VIP Bidders count
                        Row(
                          children: [
                            const Icon(Icons.group_rounded, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$bidders VIP\nBidders',
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Action Buttons: [ Watch ] & [ Join / Lock ]
          Row(
            children: [
              // Watch Button (Everyone can watch live)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/vip/arena?code=$code&watchOnly=true');
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                    label: Text(
                      isArabic ? 'مشاهدة' : 'Watch',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B21A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Join Button (VIP Bidders can Join to Bid, Regular sees Lock & can only Watch)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_isVipBidder) {
                        context.push('/vip/arena?code=$code&watchOnly=false');
                      } else {
                        _showVipPermissionAlert(context, isArabic);
                      }
                    },
                    icon: Icon(
                      _isVipBidder ? Icons.rocket_launch_rounded : Icons.lock_rounded,
                      size: 16,
                      color: _isVipBidder ? const Color(0xFF1E1045) : const Color(0xFF94A3B8),
                    ),
                    label: Text(
                      isArabic ? 'انضمام' : 'Join',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isVipBidder ? const Color(0xFF1E1045) : const Color(0xFF94A3B8),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVipBidder ? const Color(0xFFF59E0B) : const Color(0xFF33205E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackContainers(bool isArabic) {
    final fallbacks = [
      {'code': '#G-102', 'tier': 'gold', 'category_label': 'Premium Electronics & More', 'registered_bidders_count': 20},
      {'code': '#S-205', 'tier': 'silver', 'category_label': 'High Value Items', 'registered_bidders_count': 20},
      {'code': '#N-308', 'tier': 'normal', 'category_label': 'Various Products', 'registered_bidders_count': 20},
    ];
    return Column(
      children: fallbacks.map((c) => _buildContainerCard(c, isArabic)).toList(),
    );
  }

  void _showVipPermissionAlert(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1045),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 26),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'خاص بمزايدي VIP' : 'VIP Bidders Only',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'يحق فقط للمزايدين المعتمدين من الإدارة المشاركة في مزايدات VIP الحصرية.\n\nيمكنك كمستخدم عادي مشاهدة البث الحي للمزاد مباشرة!'
              : 'Only VIP Bidders explicitly authorized by Admin can place bids in VIP container auctions.\n\nAs a regular customer, you can Watch all live auctions, avatars, and prices in real-time!',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Close', style: const TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/vip/arena?code=#G-102&watchOnly=true');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isArabic ? 'مشاهدة البث الحي' : 'Watch Live Auction',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

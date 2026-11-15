import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
          isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () {
                final newLang = isAr ? 'English' : 'Arabic';
                LanguageService.setLanguage(newLang);
                setState(() {});
              },
              icon: const Icon(Icons.language, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                isAr ? 'English' : 'العربية',
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Privacy Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'حماية بياناتك أولويتنا' : 'Your Data Security & Privacy',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isAr ? 'تشفير كامل للبيانات والمعاملات المالية' : 'End-to-End Encryption & Zero Data Reselling',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildPolicySection(
                title: isAr ? '1. البيانات التي نجمعها' : '1. Information We Collect',
                content: isAr
                    ? 'نقوم بجمع رقم الهاتف للتحقق الآمن (OTP)، وبيانات التوصيل (الاسم، المحافظة، والمنطقة) لتسليم المنتجات الفائزة، بالإضافة إلى سجل المزايدات والرصيد المالي.'
                    : 'We collect phone numbers for secure OTP verification, delivery addresses for shipping won items, and transactional bidding history.',
              ),

              _buildPolicySection(
                title: isAr ? '2. كيفية استخدام المعلومات' : '2. How We Use Information',
                content: isAr
                    ? 'تُستخدم بياناتك فقط لإدارة حسابك، تنفيذ المزايدات الحية، إرسال إشعارات الفوز والتحديثات، وتوصيل البضائع بأمان تام.'
                    : 'Your information is used strictly to authenticate bids, manage digital wallet transactions, and dispatch winning orders via verified couriers.',
              ),

              _buildPolicySection(
                title: isAr ? '3. عدم مشاركة البيانات' : '3. Zero Data Sharing',
                content: isAr
                    ? 'نحن لا نقوم ببيع أو تأجير أو مشاركة بيانات مستخدمينا مع أي طرف ثالث لأغراض إعلانية. بياناتك محفوظة في خوادم مشفرة بنكياً.'
                    : 'We strictly never sell or lease your personal identity or financial records to third-party advertising companies.',
              ),

              _buildPolicySection(
                title: isAr ? '4. حقوق المستخدم والتحكم' : '4. Your User Rights',
                content: isAr
                    ? 'يحق لك في أي وقت تعديل بياناتك الشخصية، تغيير لغة التطبيق، أو طلب حذف الحساب نهائياً عبر التواصل المباشر مع الدعم الفني.'
                    : 'You retain complete ownership over your account, with the ability to modify profile settings or request full data deletion at any time.',
              ),

              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

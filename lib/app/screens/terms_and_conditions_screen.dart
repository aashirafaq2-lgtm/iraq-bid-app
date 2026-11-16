import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
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
          isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
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
              // Header Badge
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
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.verified_outlined, color: Color(0xFF0284C7), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'منصة مزاد العراق الرسمية' : 'Official Iraq Bid Platform',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isAr ? 'آخر تحديث: 2026 • حماية المشتري والبائع' : 'Last Updated: 2026 • Buyer & Seller Protection',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildClause(
                number: '01',
                title: isAr ? 'الموافقة على الشروط' : 'Acceptance of Terms',
                content: isAr
                    ? 'باستخدامك لتطبيق مزاد العراق، فإنك تقر وتوافق صراحة على الالتزام بكافة الشروط والأحكام واللوائح المعتمدة لتنظيم المزادات الإلكترونية داخل جمهورية العراق.'
                    : 'By downloading, accessing, or using the Iraq Bid application, you agree to comply with and be bound by all auction rules and commercial transaction terms in the Republic of Iraq.',
              ),

              _buildClause(
                number: '02',
                title: isAr ? 'المزايدة والالتزام المالي' : 'Bidding & Financial Binding',
                content: isAr
                    ? 'كل مزايدة يقدمها المستخدم ملزمة ونهائية. في حال فوزك بالمزاد، يتعين عليك سداد قيمة الصفقة خلال 24 ساعة لاستلام المنتج عبر شركة التوصيل المعتمدة.'
                    : 'Every bid submitted constitutes a legally binding commitment. Winners must settle the invoice within 24 hours to initiate rapid delivery with our verified courier.',
              ),

              _buildClause(
                number: '03',
                title: isAr ? 'أصالة المنتجات والضمان' : 'Product Authenticity & Warranty',
                content: isAr
                    ? 'تضمن شركة مزاد العراق أصالة منتجات الشركة الرسمية 100% مع فحص فني دقيق لكل جهاز وسلعة قبل عرضها في المزاد المباشر.'
                    : 'Iraq Bid guarantees 100% authenticity for all Company Products with thorough technical verification before each live auction event.',
              ),

              _buildClause(
                number: '04',
                title: isAr ? 'أمان المحفظة والمدفوعات' : 'Wallet & Payment Security',
                content: isAr
                    ? 'تتم معالجة جميع الإيداعات والتحويلات عبر بوابات دفع آمنة ومشفرة، مع ربط مباشر برصيد المستخدم لحماية جميع أطراف المزايدة.'
                    : 'All deposits, bids, and withdrawals are handled via high-security encrypted gateways with instant balance reconciliations.',
              ),

              _buildClause(
                number: '05',
                title: isAr ? 'سياسة الاسترجاع والشكاوى' : 'Returns & Dispute Resolution',
                content: isAr
                    ? 'يحق للمشتري فحص المنتج فور الاستلام. في حال وجود أي مطابقة غير صحيحة، يرجى التواصل مع فريق الدعم الفني خلال 48 ساعة للمراجعة الفورية.'
                    : 'Buyers are protected upon inspection. In the rare case of discrepancy, reach out to 24/7 VIP customer support within 48 hours.',
              ),

              const SizedBox(height: 20),

              // Bottom Confirmation Button
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
                    isAr ? 'فهمت وموافق' : 'I Understand & Agree',
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

  Widget _buildClause({required String number, required String title, required String content}) {
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
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
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

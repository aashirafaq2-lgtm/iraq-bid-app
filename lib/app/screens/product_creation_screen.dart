import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product_model.dart';
import '../utils/image_url_helper.dart';
import '../services/image_service.dart';
import '../services/language_service.dart';

class ProductCreationScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductCreationScreen({super.key, this.productToEdit});

  @override
  State<ProductCreationScreen> createState() => _ProductCreationScreenState();
}

class _ProductCreationScreenState extends State<ProductCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _realPriceController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  int _duration = 1; // 1, 2, or 3 days
  String? _selectedCondition;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _titleController.text = product.title;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.startingPrice.toString();
      _realPriceController.text = product.currentPrice?.toString() ?? '';
      _selectedCondition = product.condition;
      _selectedCategoryId = product.categoryId;
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        _existingImageUrl = product.imageUrl;
      }
    }

    _loadCategories();
    _animController.forward();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await apiService.getAllCategories();
      setState(() => _categories = categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('Error loading categories', 'خطأ في تحميل الفئات')}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _realPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _selectedImageBytes = bytes);
        } else {
          setState(() => _selectedImage = File(image.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('Error picking image', 'خطأ في اختيار الصورة')}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _selectedImageBytes = bytes);
        } else {
          setState(() => _selectedImage = File(image.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('Error taking photo', 'خطأ في التقاط الصورة')}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Please select a category', 'يرجى اختيار الفئة')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Please select product condition', 'يرجى اختيار حالة المنتج')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final userRole = await StorageService.getUserRole();
    if (!mounted) return;
    final allowedRoles = ['seller_products', 'admin', 'superadmin', 'company_products'];
    if (!allowedRoles.contains(userRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Only authorized sellers or admins can create/edit products.',
            'يمكن للبائعين أو المسؤولين المعتمدين فقط إنشاء المنتجات أو تعديلها.',
          )),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        throw Exception(_t('Invalid starting price', 'سعر البداية غير صالح'));
      }

      final realPrice = double.tryParse(_realPriceController.text);
      if (realPrice == null || realPrice <= 0) {
        throw Exception(_t('Invalid real price', 'السعر الفعلي غير صالح'));
      }

      String? imageUrl;
      if (_selectedImage != null || _selectedImageBytes != null) {
        if (kIsWeb && _selectedImageBytes != null) {
          final compressedBytes = await ImageService.compressUint8List(_selectedImageBytes!);
          imageUrl = await apiService.uploadImage(compressedBytes ?? _selectedImageBytes!, filename: 'product.png');
        } else if (_selectedImage != null) {
          final compressedFile = await ImageService.compressImage(_selectedImage!);
          imageUrl = await apiService.uploadImage(compressedFile ?? _selectedImage!);
        }
      } else if (widget.productToEdit != null) {
        imageUrl = _existingImageUrl;
      }

      if (widget.productToEdit != null) {
        await apiService.updateProduct(
          id: widget.productToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          imageUrl: imageUrl,
          startingPrice: price,
          realPrice: realPrice,
          condition: _selectedCondition,
          categoryId: _selectedCategoryId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('Product updated successfully!', 'تم تحديث المنتج بنجاح!')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          context.pop(true);
        }
      } else {
        await apiService.createProduct(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          imageUrl: imageUrl,
          startingPrice: price,
          realPrice: realPrice,
          condition: _selectedCondition,
          duration: _duration,
          categoryId: _selectedCategoryId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t(
                'Product created successfully! Pending admin approval.',
                'تم إنشاء المنتج بنجاح! في انتظار موافقة المسؤول.',
              )),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('Error', 'خطأ')}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDurationButton(int days, String label) {
    final isSelected = _duration == days;
    return GestureDetector(
      onTap: () => setState(() => _duration = days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.productToEdit != null;

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(
                isEditMode
                    ? _t('Edit Auction Listing', 'تعديل قائمة المزاد')
                    : _t('Create Luxury Listing', 'إنشاء مزاد جديد'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  _isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                  color: const Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Banner Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _t('Iraq Bid Official Seller', 'بائع معتمد في مزاد العراق'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF0369A1),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _t(
                                          'Listing will be live after rapid system approval.',
                                          'ستظهر القائمة مباشرة بعد الموافقة السريعة.',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Product Title
                          _buildFieldLabel(_t('Auction Title', 'عنوان المزاد')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: _inputDecoration(
                              hint: _t('e.g. Rolex Submariner 2024', 'مثال: ساعة رولكس غواصة 2024'),
                              icon: Icons.title_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? _t('Title is required', 'العنوان مطلوب')
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // Description
                          _buildFieldLabel(_t('Description & Condition Details', 'الوصف وتفاصيل الحالة')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: _inputDecoration(
                              hint: _t('Describe product features, box, papers, warranty...', 'صف مواصفات المنتج، الصندوق، الضمان...'),
                              icon: Icons.description_rounded,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Price Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(_t('Starting Bid (\$)', 'سعر البداية (\$)')),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                      decoration: _inputDecoration(
                                        hint: '100',
                                        icon: Icons.attach_money_rounded,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return _t('Required', 'مطلوب');
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(_t('Market Value (\$)', 'القيمة السوقية (\$)')),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _realPriceController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                      decoration: _inputDecoration(
                                        hint: '250',
                                        icon: Icons.price_check_rounded,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return _t('Required', 'مطلوب');
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Category & Condition
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(_t('Category', 'الفئة')),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: _isLoadingCategories
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            )
                                          : DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: _selectedCategoryId,
                                                hint: Text(
                                                  _t('Select Category', 'اختر الفئة'),
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                                ),
                                                isExpanded: true,
                                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                                items: _categories.map((c) {
                                                  return DropdownMenuItem<int>(
                                                    value: c['id'] as int,
                                                    child: Text(
                                                      c['name'] as String,
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) => setState(() => _selectedCategoryId = val),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(_t('Condition', 'الحالة')),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCondition,
                                          hint: Text(
                                            _t('Select Condition', 'اختر الحالة'),
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                          ),
                                          isExpanded: true,
                                          icon: const Icon(Icons.arrow_drop_down_rounded),
                                          items: [
                                            ('New', _t('Brand New', 'جديد بالكامل')),
                                            ('Used', _t('Like New', 'مستعمل بحالة ممتازة')),
                                            ('Working', _t('Good Working', 'يعمل بصورة جيدة')),
                                          ].map((pair) {
                                            return DropdownMenuItem<String>(
                                              value: pair.$1,
                                              child: Text(
                                                pair.$2,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _selectedCondition = val),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Product Image Box
                          _buildFieldLabel(_t('Product Media Gallery', 'معرض صور المنتج')),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (_selectedImage != null || _selectedImageBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 180,
                                      width: double.infinity,
                                      child: kIsWeb && _selectedImageBytes != null
                                          ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                          : _selectedImage != null
                                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                              : const SizedBox.shrink(),
                                    ),
                                  )
                                else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 180,
                                      width: double.infinity,
                                      child: Image.network(
                                        ImageUrlHelper.fixImageUrl(_existingImageUrl!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 40,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _t('Upload high quality photo', 'قم برفع صورة واضحة وعالية الجودة'),
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                                        label: Text(_t('Gallery', 'المعرض')),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          foregroundColor: const Color(0xFF0284C7),
                                          side: const BorderSide(color: Color(0xFF0284C7)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _takePhoto,
                                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                        label: Text(_t('Camera', 'الكاميرا')),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          foregroundColor: const Color(0xFF475569),
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Duration Buttons (only for new listings)
                          if (!isEditMode) ...[
                            _buildFieldLabel(_t('Auction Duration', 'مدة المزاد')),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildDurationButton(1, _t('24 Hours', '24 ساعة'))),
                                const SizedBox(width: 10),
                                Expanded(child: _buildDurationButton(2, _t('48 Hours', '48 ساعة'))),
                                const SizedBox(width: 10),
                                Expanded(child: _buildDurationButton(3, _t('72 Hours', '72 ساعة'))),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Submit Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isEditMode ? Icons.save_rounded : Icons.rocket_launch_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isEditMode
                                              ? _t('Save Listing Changes', 'حفظ تغييرات القائمة')
                                              : _t('Launch Auction', 'إطلاق المزاد الآن'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }
}

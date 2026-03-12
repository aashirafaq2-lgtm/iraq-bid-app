import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product_model.dart';
import '../utils/image_url_helper.dart';
import '../services/image_service.dart';

class ProductCreationScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  
  const ProductCreationScreen({super.key, this.productToEdit});

  @override
  State<ProductCreationScreen> createState() => _ProductCreationScreenState();
}

class _ProductCreationScreenState extends State<ProductCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _realPriceController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  int _duration = 1; // Default to 1 day, must be 1, 2, or 3
  String? _selectedCondition; // 'New', 'Used', 'Working'
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl; // Store existing image URL for edit mode
  
  // Category state
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _titleController.text = product.title;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.startingPrice.toString();
      _realPriceController.text = product.currentPrice?.toString() ?? '';
      _selectedCondition = product.condition;
      _selectedCategoryId = product.categoryId;
      
      // Load existing image URL
      if (product.imageUrls.isNotEmpty) {
        _existingImageUrl = product.imageUrls.first;
      }
    }
    // Load categories on init
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await apiService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
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
        setState(() {
          if (kIsWeb) {
            // For web, read bytes directly
            image.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _selectedImageBytes = bytes;
                });
              }
            });
          } else {
            // For mobile, use File
            _selectedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
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
        setState(() {
          if (kIsWeb) {
            // For web, read bytes directly
            image.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _selectedImageBytes = bytes;
                });
              }
            });
          } else {
            // For mobile, use File
            _selectedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate category is selected
    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a category'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Validate condition is selected
    if (_selectedCondition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select product condition'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Check user role before attempting to create/update product
    final userRole = await StorageService.getUserRole();
    final allowedRoles = ['seller_products', 'admin', 'superadmin', 'company_products'];
    if (!allowedRoles.contains(userRole)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only authorized sellers or admins can ${widget.productToEdit != null ? 'edit' : 'create'} products. Your current role: ${userRole ?? 'unknown'}.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        throw Exception('Invalid starting price');
      }

      final realPrice = double.tryParse(_realPriceController.text);
      if (realPrice == null || realPrice <= 0) {
        throw Exception('Invalid real price');
      }

      // Upload image first if a new image was selected
      String? imageUrl;
      bool imageRemoved = false;
      
      if (_selectedImage != null || _selectedImageBytes != null) {
        // New image selected - compress and upload it
        if (kIsWeb && _selectedImageBytes != null) {
          // For web, compress bytes
          final compressedBytes = await ImageService.compressUint8List(_selectedImageBytes!);
          imageUrl = await apiService.uploadImage(compressedBytes ?? _selectedImageBytes!, filename: 'product-image.png');
          print('✅ Image compressed and uploaded (Web)');
        } else if (_selectedImage != null) {
          // For mobile, compress File
          final compressedFile = await ImageService.compressImage(_selectedImage!);
          imageUrl = await apiService.uploadImage(compressedFile ?? _selectedImage!);
          print('✅ Image compressed and uploaded (Mobile)');
        }
      } else if (widget.productToEdit != null) {
        // Editing existing product
        if (_existingImageUrl == null || _existingImageUrl!.isEmpty) {
          // Image was removed by user
          imageUrl = null;
          imageRemoved = true;
        } else {
          // Keep existing image if no new image was selected and existing image exists
          imageUrl = _existingImageUrl;
        }
      }

      if (widget.productToEdit != null) {
        // Update existing product
        // Always send title and startingPrice (required fields)
        // Send imageUrl only if it changed (new upload, removed, or kept existing)
        await apiService.updateProduct(
          id: widget.productToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          imageUrl: imageUrl, // Send null if removed, existing URL if kept, new URL if uploaded
          startingPrice: price,
          realPrice: realPrice,
          condition: _selectedCondition,
          categoryId: _selectedCategoryId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else {
        // Create new product
        await apiService.createProduct(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          imageUrl: imageUrl,
          startingPrice: price,
          realPrice: realPrice,
          condition: _selectedCondition,
          duration: _duration,
          categoryId: _selectedCategoryId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully! Pending admin approval.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = widget.productToEdit != null 
            ? 'Error updating product' 
            : 'Error creating product';
        if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
          errorMessage = 'Access denied. Only sellers can ${widget.productToEdit != null ? 'edit' : 'create'} products. Please verify your account role or contact support.';
        } else if (e.toString().contains('Only sellers can')) {
          errorMessage = 'Only sellers can ${widget.productToEdit != null ? 'edit' : 'create'} products. Your account may need to be updated. Please contact support.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDurationButton(int days, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _duration == days;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _duration = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue600
              : (isDark ? AppColors.slate800 : AppColors.slate100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.blue600
                : (isDark ? AppColors.slate700 : AppColors.slate300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.cardWhite
                  : (isDark ? AppColors.slate300 : AppColors.slate700),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isEditMode = widget.productToEdit != null;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Listing' : 'Add New Listing'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Product Title *',
                    hintText: 'Enter product title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter product description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  ),
                ),

                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Starting Price *',
                    hintText: 'Enter starting price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Real Price
                TextFormField(
                  controller: _realPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Real Price *',
                    hintText: 'Enter real market price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Real price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingCategories)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            hintText: 'Select a category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.slate900 : AppColors.slate50,
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem<int>(
                              value: category['id'] as int,
                              child: Text(category['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Category is required';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Condition Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Condition *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        decoration: InputDecoration(
                          hintText: 'Select condition',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.slate900 : AppColors.slate50,
                        ),
                        items: ['New', 'Used', 'Working'].map((condition) {
                          return DropdownMenuItem<String>(
                            value: condition,
                            child: Text(condition),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Condition is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Image Picker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Image',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImage != null || _selectedImageBytes != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.slate700 : AppColors.slate200,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb && _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox(),
                          ),
                        )
                      else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.slate700 : AppColors.slate200,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              ImageUrlHelper.fixImageUrl(_existingImageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark ? AppColors.slate900 : AppColors.slate100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: isDark ? AppColors.slate600 : AppColors.slate400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: isDark ? AppColors.slate600 : AppColors.slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate900 : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.slate700 : AppColors.slate200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: isDark ? AppColors.slate600 : AppColors.slate400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No image selected',
                                style: TextStyle(
                                  color: isDark ? AppColors.slate600 : AppColors.slate400,
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
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedImage != null || _selectedImageBytes != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                                _existingImageUrl = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove Image'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Duration (only show for new products, not when editing)
                // Fixed options: 1, 2, or 3 days only
                if (!isEditMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auction Duration',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDurationButton(1, '1 Day'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDurationButton(2, '2 Days'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDurationButton(3, '3 Days'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Create/Update Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: AppColors.cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cardWhite),
                            ),
                          )
                        : Text(isEditMode ? 'Update Listing' : 'Create Listing'),
                  ),
                ),

                const SizedBox(height: 16),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.blue700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your product will be reviewed by admin before going live.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




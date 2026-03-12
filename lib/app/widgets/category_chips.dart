import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/rtl_helper.dart';
import '../services/app_localizations.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  void _showCategoryDropdown(BuildContext context) {
    // Show all categories including 'All'
    final categoryList = categories.toList();
    
    if (categoryList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.noCategoriesAvailable ?? 'No categories available')),
      );
      return;
    }

    // Show dropdown menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.selectCategory ?? 'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Category list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categoryList.length,
                itemBuilder: (context, index) {
                  final category = categoryList[index];
                  final isSelected = selectedCategory == category;
                  final isAllCategory = category == 'All';
                  
                  return ListTile(
                    title: Text(
                      isAllCategory 
                          ? (AppLocalizations.of(context)?.allProducts ?? 'All Products')
                          : (AppLocalizations.of(context)?.translateCategory(category) ?? category),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 20)
                        : null,
                    onTap: () {
                      onCategorySelected(category);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Always show at least 'All' category, even if list is empty
    final displayCategories = categories.isEmpty ? ['All'] : categories;
    
    return SizedBox(
      height: 48, // Fixed height for the list view
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // Better sliding feel
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(displayCategories.length, (index) {
          final category = displayCategories[index];
          final isSelected = selectedCategory == category;
          final isAllCategory = category == 'All';
          
          final child = Center(
            child: InkWell(
              onTap: () {
                // If already selected and it's 'All', show dropdown
                // Otherwise just select it
                if (isAllCategory && isSelected) {
                  _showCategoryDropdown(context);
                } else {
                  onCategorySelected(category);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? colorScheme.primary.withOpacity(0.12)
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary 
                        : (isDark ? AppColors.slate700 : AppColors.slate300),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category == 'All' 
                          ? (AppLocalizations.of(context)?.allProducts ?? 'All Products')
                          : category,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (isAllCategory) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showCategoryDropdown(context),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
          
          if (index < displayCategories.length - 1) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [child, const SizedBox(width: 8)],
            );
          }
          return child;
          }),
        ),
      ),
    );
  }
}






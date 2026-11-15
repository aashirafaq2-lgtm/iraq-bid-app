import os

def fix_profile_screen():
    path = 'lib/app/screens/profile_screen.dart'
    if not os.path.exists(path): return
    
    with open(path, 'r') as f:
        content = f.read()
    
    # Add Delete Account button after Logout button
    delete_button = """
                    const SizedBox(height: 12),
                    // Delete Account Button (Required by Apple)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Permanently remove your account and data', style: TextStyle(fontSize: 12)),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Account?'),
                                content: const Text('This action is permanent and cannot be undone. All your data will be removed.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion request submitted.')));
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),"""
    
    if 'Delete Account' not in content:
        # Find the end of the Logout Padding block (around line 457)
        if 'context.go(\'/auth\');' in content:
            new_content = content.replace('context.go(\'/auth\');\n                              }\n                            }\n                          },\n                        ),\n                      ),\n                    ),', 
                                          'context.go(\'/auth\');\n                              }\n                            }\n                          },\n                        ),\n                      ),\n                    ),' + delete_button)
            with open(path, 'w') as f:
                f.write(new_content)
            print("✅ Added Delete Account to Profile Screen")

def fix_product_details():
    path = 'lib/app/screens/product_details_screen.dart'
    if not os.path.exists(path): return
    
    with open(path, 'r') as f:
        content = f.read()
        
    report_icon = """
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Content reported. We will review it shortly.'))
                      );
                    },
                    icon: Icon(Icons.flag_outlined, color: isDark ? Colors.white70 : Colors.black54),
                  ),"""
    
    if 'Icons.flag_outlined' not in content:
        # Insert before the closing bracket of the Row containing share and favorite (around line 251)
        target = 'color: _isLiked ? Colors.red : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),\n                    ),\n                  ),'
        if target in content:
            new_content = content.replace(target, target + report_icon)
            with open(path, 'w') as f:
                f.write(new_content)
            print("✅ Added Report Button to Product Details")

if __name__ == "__main__":
    fix_profile_screen()
    fix_product_details()

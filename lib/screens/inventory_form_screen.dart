import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../services/unified_image_service.dart';
import 'package:intl/intl.dart'; // Import for currency formatting

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item;
  final bool isEditing;

  const InventoryFormScreen({
    super.key,
    this.item,
    this.isEditing = false,
  });

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Currency formatter
  // final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _currencyFormat = NumberFormat('#,##0.00');

  // Expiry date fields
  DateTime? _selectedExpiryDate;
  bool _isPerishable = false;

  bool _isLoading = false;
  List<String> _categories = [];
  String? _selectedCategory;
  XFile? _selectedImageFile;
  String? _itemImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.item != null) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    final item = widget.item!;
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _categoryController.text = item.category;
    _selectedCategory = item.category;
    _quantityController.text = item.quantity.toString();
    // Format currency for display
    _unitPriceController.text = _currencyFormat.format(item.unitPrice);
    // _unitPriceController.text = item.unitPrice.toString();
    _supplierController.text = item.supplier;
    _reorderLevelController.text = item.reorderLevel.toString();
    _imageUrlController.text = item.imageUrl ?? '';
    _isPerishable = item.isPerishable;
    _selectedExpiryDate = item.expiryDate;
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Item Image',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final imageFile =
                            await UnifiedImageService.pickImageFromCamera();
                        if (imageFile != null) {
                          setState(() {
                            _selectedImageFile = imageFile;
                            _imageUrlController.text = imageFile.path;
                          });
                        }
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final imageFile =
                            await UnifiedImageService.pickImageFromGallery();
                        if (imageFile != null) {
                          setState(() {
                            _selectedImageFile = imageFile;
                            _imageUrlController.text = imageFile.path;
                          });
                        }
                      },
                    ),
                    if (_selectedImageFile != null ||
                        _imageUrlController.text.isNotEmpty)
                      _buildImageOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedImageFile = null;
                            _imageUrlController.clear();
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: effectiveColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: effectiveColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryDateSection([bool isSmallScreen = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Expiry Information', Icons.schedule, isSmallScreen),
        const SizedBox(height: 16),

        // Perishable toggle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isPerishable
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPerishable
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!
                      : Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPerishable ? Icons.warning : Icons.info_outline,
                  color: _isPerishable
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perishable Item',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isPerishable
                            ? Theme.of(context).primaryColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPerishable
                          ? 'This item has an expiry date'
                          : 'This item does not expire',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _isPerishable ? 1.1 : 1.0,
                child: Switch.adaptive(
                  value: _isPerishable,
                  onChanged: (value) {
                    setState(() {
                      _isPerishable = value;
                      if (!value) {
                        _selectedExpiryDate = null;
                      }
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Expiry date picker (only shown when perishable)
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: _isPerishable ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isPerishable ? 1.0 : 0.0,
            child: _isPerishable
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Expiry Date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedExpiryDate != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(_selectedExpiryDate!)
                                          : 'Select expiry date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: _selectedExpiryDate != null
                                            ? (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.grey[800])
                                            : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white60
                                                : Colors.grey[500]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedExpiryDate != null) ...[
                                const SizedBox(width: 8),
                                _buildExpiryStatusChip(),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedExpiryDate != null) ...[
                        const SizedBox(height: 12),
                        _buildExpiryWarning(),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryStatusChip() {
    if (_selectedExpiryDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysUntilExpiry = _selectedExpiryDate!.difference(now).inDays;

    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (daysUntilExpiry < 0) {
      chipColor = Colors.red;
      chipText = 'Expired';
      chipIcon = Icons.error;
    } else if (daysUntilExpiry <= 30) {
      chipColor = Colors.orange;
      chipText = 'Soon';
      chipIcon = Icons.warning;
    } else if (daysUntilExpiry <= 180) {
      chipColor = Colors.yellow[700]!;
      chipText = '6 months';
      chipIcon = Icons.schedule;
    } else {
      chipColor = Colors.green;
      chipText = 'Fresh';
      chipIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryWarning() {
    if (_selectedExpiryDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysUntilExpiry = _selectedExpiryDate!.difference(now).inDays;

    if (daysUntilExpiry <= 180) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Colors.orange[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                daysUntilExpiry < 0
                    ? 'This item has already expired!'
                    : daysUntilExpiry <= 30
                        ? 'This item expires in $daysUntilExpiry days. You will receive notifications.'
                        : 'This item expires within 6 months. You will receive notifications.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedExpiryDate ?? now.add(const Duration(days: 30));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now)
          ? initialDate
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)), // 5 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedExpiryDate = selectedDate;
      });
    }
  }

  Widget _buildItemImageSection([bool isSmallScreen = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Item Image', Icons.photo_camera, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Center(
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!
                      : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImageFile != null ||
                      _imageUrlController.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildImageWidget(isSmallScreen: isSmallScreen),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: isSmallScreen ? 32 : 40,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_selectedImageFile != null ||
            _imageUrlController.text.isNotEmpty) ...[
          SizedBox(height: isSmallScreen ? 8 : 12),
          Center(
            child: TextButton.icon(
              onPressed: _showImagePickerOptions,
              icon: Icon(Icons.edit, size: isSmallScreen ? 14 : 16),
              label: Text(
                'Change Image',
                style: GoogleFonts.poppins(fontSize: isSmallScreen ? 10 : 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget({bool isSmallScreen = false}) {
    final imageSize = isSmallScreen ? 96.0 : 116.0;

    if (_selectedImageFile != null) {
      if (kIsWeb) {
        // For web, show image from XFile bytes
        return FutureBuilder<Uint8List>(
          future: _selectedImageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              );
            } else if (snapshot.hasError) {
              return _buildImagePlaceholder(isSmallScreen: isSmallScreen);
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      } else {
        // Local file image (mobile/desktop)
        return Image.file(
          File(_selectedImageFile!.path),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(isSmallScreen: isSmallScreen);
          },
        );
      }
    } else if (_imageUrlController.text.isNotEmpty) {
      // Network image URL
      if (_imageUrlController.text.startsWith('http')) {
        return Image.network(
          _imageUrlController.text,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(isSmallScreen: isSmallScreen);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      } else {
        return _buildImagePlaceholder(isSmallScreen: isSmallScreen);
      }
    }
    return _buildImagePlaceholder(isSmallScreen: isSmallScreen);
  }

  Widget _buildImagePlaceholder({bool isSmallScreen = false}) {
    final imageSize = isSmallScreen ? 96.0 : 116.0;
    final iconSize = isSmallScreen ? 24.0 : 32.0;
    final fontSize = isSmallScreen ? 8.0 : 10.0;

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: iconSize,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategories() async {
    try {
      // Get predefined categories plus existing ones from database
      final predefinedCategories = InventoryService.getPredefinedCategories();
      final existingCategories = await InventoryService.getCategories();

      // Combine and deduplicate
      final allCategories = <String>{};
      allCategories.addAll(predefinedCategories);
      allCategories.addAll(existingCategories);

      setState(() {
        _categories = allCategories.toList()..sort();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      // Parse price with proper handling for currency format
      double unitPrice;
      try {
        // Remove currency symbol, commas, and other non-numeric characters before parsing
        String priceText =
            _unitPriceController.text.replaceAll(RegExp(r'[^\d.]'), '');
        unitPrice = double.parse(priceText);
      } catch (e) {
        throw Exception('Invalid price format');
      }

      // Handle image upload if there's a local image
      String? finalImageUrl;
      if (_selectedImageFile != null) {
        try {
          // Show upload progress
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Uploading image...'),
                  ],
                ),
                duration: Duration(seconds: 10),
              ),
            );
          }

          // Upload the local image to Firebase Storage
          final uploadedUrl = await UnifiedImageService.uploadInventoryImage(
              _selectedImageFile!);

          // Hide upload progress
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }

          if (uploadedUrl != null) {
            finalImageUrl = uploadedUrl;
            debugPrint('Image uploaded successfully: $uploadedUrl');
          } else {
            throw Exception('Failed to upload image - no URL returned');
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          debugPrint('Image upload error: $uploadError');
          throw Exception('Failed to upload image: $uploadError');
        }
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        // Use existing URL (for editing existing items)
        finalImageUrl = _imageUrlController.text.trim();
        debugPrint('Using existing image URL: $finalImageUrl');
      }

      final item = InventoryItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? _categoryController.text.trim(),
        quantity: int.parse(_quantityController.text),
        unitPrice: unitPrice,
        supplier: _supplierController.text.trim(),
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
        reorderLevel: int.parse(_reorderLevelController.text),
        imageUrl: finalImageUrl,
        isPerishable: _isPerishable,
        expiryDate: _selectedExpiryDate,
      );

      if (widget.isEditing) {
        await InventoryService.updateInventoryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await InventoryService.addInventoryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to determine layout
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isWideScreen = screenWidth > 600;
    final isSmallScreen = screenWidth < 350;
    final isShortScreen = screenHeight < 600;

    // Adjust padding and font sizes based on screen size
    final double horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final double verticalPadding = isShortScreen ? 12.0 : 16.0;
    final double cardPadding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.isEditing ? 'Edit Item' : 'Add New Item',
            key: ValueKey(widget.isEditing),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: TextButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Form(
                key: _formKey,
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Information Card
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnimatedCard(
                              index: 0,
                              isSmallScreen: isSmallScreen,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Basic Information',
                                      Icons.info_outline, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildAnimatedTextFormField(
                                    controller: _nameController,
                                    label: 'Item Name',
                                    icon: Icons.inventory_2,
                                    isSmallScreen: isSmallScreen,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter item name';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildAnimatedTextFormField(
                                    controller: _descriptionController,
                                    label: 'Description',
                                    icon: Icons.description,
                                    isSmallScreen: isSmallScreen,
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter description';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Category Card
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnimatedCard(
                              index: 1,
                              isSmallScreen: isSmallScreen,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Category', Icons.category,
                                      isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  if (_categories.isNotEmpty)
                                    _buildAnimatedDropdown(
                                        isSmallScreen: isSmallScreen)
                                  else
                                    _buildAnimatedTextFormField(
                                      controller: _categoryController,
                                      label: 'Category',
                                      icon: Icons.category,
                                      isSmallScreen: isSmallScreen,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter category';
                                        }
                                        return null;
                                      },
                                    ),
                                  if (_selectedCategory == null &&
                                      _categories.isNotEmpty) ...[
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    _buildAnimatedTextFormField(
                                      controller: _categoryController,
                                      label: 'New Category Name',
                                      icon: Icons.add,
                                      isSmallScreen: isSmallScreen,
                                      validator: (value) {
                                        if (_selectedCategory == null &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'Please enter new category name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quantity and Pricing Card
                      AnimationConfiguration.staggeredList(
                        position: 2,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnimatedCard(
                              index: 2,
                              isSmallScreen: isSmallScreen,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Quantity & Pricing',
                                      Icons.attach_money, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  // Use Column layout for better responsiveness and prevent overflow
                                  if (isWideScreen)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildAnimatedTextFormField(
                                            controller: _quantityController,
                                            label: 'Quantity',
                                            icon: Icons.numbers,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              final quantity =
                                                  int.tryParse(value);
                                              if (quantity == null ||
                                                  quantity < 0) {
                                                return 'Invalid quantity';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(width: isSmallScreen ? 8 : 16),
                                        Expanded(
                                          child: _buildAnimatedTextFormField(
                                            controller: _unitPriceController,
                                            label: 'Unit Price (\$)',
                                            icon: Icons.attach_money,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              final price =
                                                  double.tryParse(value);
                                              if (price == null || price < 0) {
                                                return 'Invalid price';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildAnimatedTextFormField(
                                          controller: _quantityController,
                                          label: 'Quantity',
                                          icon: Icons.numbers,
                                          isSmallScreen: isSmallScreen,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            final quantity =
                                                int.tryParse(value);
                                            if (quantity == null ||
                                                quantity < 0) {
                                              return 'Invalid quantity';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(
                                            height: isSmallScreen ? 12 : 16),
                                        _buildAnimatedTextFormField(
                                          controller: _unitPriceController,
                                          label: 'Unit Price (\$)',
                                          icon: Icons.attach_money,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d*')),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            final price =
                                                double.tryParse(value);
                                            if (price == null || price < 0) {
                                              return 'Invalid price';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildReorderLevelDropdown(
                                      isSmallScreen: isSmallScreen),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Expiry Date Card
                      AnimationConfiguration.staggeredList(
                        position: 3,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnimatedCard(
                              index: 3,
                              isSmallScreen: isSmallScreen,
                              child: _buildExpiryDateSection(isSmallScreen),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Item Image Card
                      AnimationConfiguration.staggeredList(
                        position: 4,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnimatedCard(
                              index: 4,
                              child: _buildItemImageSection(isSmallScreen),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isEditing
                              ? 'Updating item...'
                              : 'Adding item...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      [IconData? icon, bool isSmallScreen = false]) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
        ],
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(
      {required int index, required Widget child, bool isSmallScreen = false}) {
    final padding = isSmallScreen ? 16.0 : 20.0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2 + (2 * value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildAnimatedTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool isSmallScreen = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(hasFocus ? 1.02 : 1.0),
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: label,
                        prefixIcon: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            icon,
                            color: hasFocus
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        labelStyle: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      validator: validator,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      maxLines: maxLines,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDropdown({bool isSmallScreen = false}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true, // Prevent overflow
              decoration: InputDecoration(
                labelText: 'Select Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              items: [
                ..._categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )),
                DropdownMenuItem(
                  value: 'custom',
                  child: SizedBox(
                    width: double.infinity,
                    child: const Text(
                      '+ Add New Category',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value == 'custom' ? null : value;
                  if (value != 'custom') {
                    _categoryController.text = value ?? '';
                  }
                });
              },
              validator: (value) {
                if ((value == null || value == 'custom') &&
                    _categoryController.text.trim().isEmpty) {
                  return 'Please select or enter a category';
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderLevelDropdown({bool isSmallScreen = false}) {
    final reorderLevels = InventoryService.getReorderLevelOptions();
    final currentValue = _reorderLevelController.text.isNotEmpty
        ? int.tryParse(_reorderLevelController.text)
        : null;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: DropdownButtonFormField<int>(
              initialValue:
                  reorderLevels.contains(currentValue) ? currentValue : null,
              decoration: InputDecoration(
                labelText: 'Reorder Level',
                prefixIcon: const Icon(Icons.warning),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                helperText: 'Alert when stock falls below this level',
                helperStyle: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
              items: [
                ...reorderLevels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(
                        '$level units',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    )),
                const DropdownMenuItem(
                  value: -1,
                  child: Text('+ Custom Level'),
                ),
              ],
              onChanged: (value) {
                if (value == -1) {
                  // Show custom input dialog
                  _showCustomReorderLevelDialog(isSmallScreen: isSmallScreen);
                } else if (value != null) {
                  setState(() {
                    _reorderLevelController.text = value.toString();
                  });
                }
              },
              validator: (value) {
                if (_reorderLevelController.text.isEmpty) {
                  return 'Please select or enter reorder level';
                }
                final level = int.tryParse(_reorderLevelController.text);
                if (level == null || level < 0) {
                  return 'Invalid reorder level';
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  void _showCustomReorderLevelDialog({bool isSmallScreen = false}) {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Custom Reorder Level',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a custom reorder level for this item:',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            TextField(
              controller: customController,
              decoration: InputDecoration(
                labelText: 'Custom Reorder Level',
                prefixIcon: const Icon(Icons.warning),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'units',
                labelStyle: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final customLevel = int.tryParse(customController.text);
              if (customLevel != null && customLevel > 0) {
                setState(() {
                  _reorderLevelController.text = customLevel.toString();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Set Level',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSaveButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 4,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isEditing ? Icons.update : Icons.add,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isEditing ? 'Update Item' : 'Add Item',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _reorderLevelController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}

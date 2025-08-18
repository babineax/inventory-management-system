import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../services/image_picker_service.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item;
  final bool isEditing;

  const InventoryFormScreen({
    Key? key,
    this.item,
    this.isEditing = false,
  }) : super(key: key);

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

  bool _isLoading = false;
  List<String> _categories = [];
  String? _selectedCategory;
  String? _itemImagePath;

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
    _unitPriceController.text = item.unitPrice.toString();
    _supplierController.text = item.supplier;
    _reorderLevelController.text = item.reorderLevel.toString();
    _imageUrlController.text = item.imageUrl ?? '';
    // Note: For editing, we use imageUrl as the image source
    // In a real app, we might want to handle local vs remote images differently
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Item Image',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
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
                        final imagePath =
                            await ImagePickerService.pickFromCamera();
                        if (imagePath != null) {
                          setState(() {
                            _itemImagePath = imagePath;
                            _imageUrlController.text = imagePath;
                          });
                        }
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final imagePath =
                            await ImagePickerService.pickFromGallery();
                        if (imagePath != null) {
                          setState(() {
                            _itemImagePath = imagePath;
                            _imageUrlController.text = imagePath;
                          });
                        }
                      },
                    ),
                    if (_itemImagePath != null ||
                        _imageUrlController.text.isNotEmpty)
                      _buildImageOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _itemImagePath = null;
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

  Widget _buildItemImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Item Image', Icons.photo_camera),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child:
                  _itemImagePath != null || _imageUrlController.text.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImageWidget(),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
        if (_itemImagePath != null || _imageUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                'Change Image',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget() {
    if (_itemImagePath != null) {
      if (kIsWeb) {
        // For web, treat as blob URL or data URL
        if (_itemImagePath!.startsWith('blob:') ||
            _itemImagePath!.startsWith('data:')) {
          return Image.network(
            _itemImagePath!,
            width: 116,
            height: 116,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
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
          return _buildImagePlaceholder();
        }
      } else {
        // Local file image (mobile/desktop)
        return Image.file(
          File(_itemImagePath!),
          width: 116,
          height: 116,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        );
      }
    } else if (_imageUrlController.text.isNotEmpty) {
      // Network image URL
      if (_imageUrlController.text.startsWith('http')) {
        return Image.network(
          _imageUrlController.text,
          width: 116,
          height: 116,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
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
        return _buildImagePlaceholder();
      }
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 10,
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
      final item = InventoryItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? _categoryController.text.trim(),
        quantity: int.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
        supplier: _supplierController.text.trim(),
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
        reorderLevel: int.parse(_reorderLevelController.text),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.isEditing ? 'Edit Item' : 'Add New Item',
            key: ValueKey(widget.isEditing),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
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
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    'Basic Information', Icons.info_outline),
                                const SizedBox(height: 16),
                                _buildAnimatedTextFormField(
                                  controller: _nameController,
                                  label: 'Item Name',
                                  icon: Icons.inventory_2,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter item name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextFormField(
                                  controller: _descriptionController,
                                  label: 'Description',
                                  icon: Icons.description,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Category', Icons.category),
                                const SizedBox(height: 16),
                                if (_categories.isNotEmpty)
                                  _buildAnimatedDropdown()
                                else
                                  _buildAnimatedTextFormField(
                                    controller: _categoryController,
                                    label: 'Category',
                                    icon: Icons.category,
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
                                  const SizedBox(height: 16),
                                  _buildAnimatedTextFormField(
                                    controller: _categoryController,
                                    label: 'New Category Name',
                                    icon: Icons.add,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    'Quantity & Pricing', Icons.attach_money),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAnimatedTextFormField(
                                        controller: _quantityController,
                                        label: 'Quantity',
                                        icon: Icons.numbers,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          final quantity = int.tryParse(value);
                                          if (quantity == null ||
                                              quantity < 0) {
                                            return 'Invalid quantity';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildAnimatedTextFormField(
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
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          final price = double.tryParse(value);
                                          if (price == null || price < 0) {
                                            return 'Invalid price';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildReorderLevelDropdown(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Item Image Card
                    AnimationConfiguration.staggeredList(
                      position: 3,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildAnimatedCard(
                            index: 3,
                            child: _buildItemImageSection(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Information Card
                    AnimationConfiguration.staggeredList(
                      position: 4,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildAnimatedCard(
                            index: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    'Additional Information', Icons.more_horiz),
                                const SizedBox(height: 16),
                                _buildAnimatedTextFormField(
                                  controller: _supplierController,
                                  label: 'Supplier',
                                  icon: Icons.business,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter supplier';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextFormField(
                                  controller: _imageUrlController,
                                  label: 'Image URL (Optional)',
                                  icon: Icons.image,
                                  keyboardType: TextInputType.url,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    AnimationConfiguration.staggeredList(
                      position: 5,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildAnimatedSaveButton(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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

  Widget _buildSectionTitle(String title, [IconData? icon]) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
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
                padding: const EdgeInsets.all(20.0),
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
                            color: Colors.grey[300]!,
                          ),
                        ),
                      ),
                      validator: validator,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      maxLines: maxLines,
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

  Widget _buildAnimatedDropdown() {
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
                      child: Text(category),
                    )),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('+ Add New Category'),
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

  Widget _buildReorderLevelDropdown() {
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
              ),
              items: [
                ...reorderLevels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text('$level units'),
                    )),
                const DropdownMenuItem(
                  value: -1,
                  child: Text('+ Custom Level'),
                ),
              ],
              onChanged: (value) {
                if (value == -1) {
                  // Show custom input dialog
                  _showCustomReorderLevelDialog();
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

  void _showCustomReorderLevelDialog() {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Custom Reorder Level',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a custom reorder level for this item:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customController,
              decoration: InputDecoration(
                labelText: 'Custom Reorder Level',
                prefixIcon: const Icon(Icons.warning),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'units',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
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
              style: GoogleFonts.poppins(color: Colors.white),
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

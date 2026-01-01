import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../supabase_config.dart';

class AddProductPopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onProductAdded;
  final int? selectedInventoryId;
  const AddProductPopup({
    super.key,
    required this.onClose,
    this.onProductAdded,
    this.selectedInventoryId,
  });

  @override
  State<AddProductPopup> createState() => _AddProductPopupState();
}

class _AddProductPopupState extends State<AddProductPopup> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _minProfitController = TextEditingController();

  int? _selectedBrandId;
  int? _selectedCategoryId;
  int? _selectedUnitId;

  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> units = [];

  bool isLoading = true;
  bool isSaving = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Load brands
      final brandsResp = await supabase
          .from('brand')
          .select('brand_id, name')
          .order('name');
      brands = List<Map<String, dynamic>>.from(brandsResp);

      // Load categories
      final categoriesResp = await supabase
          .from('product_category')
          .select('product_category_id, name')
          .order('name');
      categories = List<Map<String, dynamic>>.from(categoriesResp);

      // Load units
      final unitsResp = await supabase
          .from('unit')
          .select('unit_id, unit_name')
          .order('unit_id');
      units = List<Map<String, dynamic>>.from(unitsResp);

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBrandId == null) {
      _showError('Please select a brand');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }
    if (_selectedUnitId == null) {
      _showError('Please select a unit');
      return;
    }

    setState(() => isSaving = true);

    try {
      // Insert the product first without image
      final productData = {
        'name': _productNameController.text.trim(),
        'brand_id': _selectedBrandId,
        'category_id': _selectedCategoryId,
        'wholesale_price': double.parse(_wholesalePriceController.text),
        'selling_price': double.parse(_sellingPriceController.text),
        'minimum_profit_percent': double.parse(_minProfitController.text),
        'unit_id': _selectedUnitId,
        'is_active': true,
        'total_quantity': 0,
      };

      final productResponse = await supabase
          .from('product')
          .insert(productData)
          .select('product_id')
          .single();

      final productId = productResponse['product_id'] as int;

      // Upload image with product ID if selected
      if (_selectedImageBytes != null) {
        final imageUrl = await _uploadImageToSupabase(productId);
        if (imageUrl != null) {
          // Update product with image URL
          await supabase
              .from('product')
              .update({'product_image': imageUrl})
              .eq('product_id', productId);
        }
      }

      // If a specific inventory is selected, create a batch entry
      if (widget.selectedInventoryId != null) {
        await supabase.from('batch').insert({
          'product_id': productId,
          'inventory_id': widget.selectedInventoryId,
          'quantity': 0,
          'supplier_id': null,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.selectedInventoryId == null
                  ? 'Product added successfully'
                  : 'Product added to inventory successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onProductAdded?.call();
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error adding product: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<String?> _uploadImageToSupabase(int productId) async {
    if (_selectedImageBytes == null || _selectedImageName == null) return null;

    try {
      // Generate filename with product ID and timestamp: product_{id}_{timestamp}.ext
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _selectedImageName!.toLowerCase().split('.').last;
      final fileName = 'product_${productId}_$timestamp.$extension';

      // Upload to Supabase storage in 'images' bucket
      await supabase.storage
          .from('images')
          .uploadBinary(fileName, _selectedImageBytes!);

      // Get the public URL
      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        _showError('Failed to upload image: $e');
      }
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _wholesalePriceController.dispose();
    _sellingPriceController.dispose();
    _minProfitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 850,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Product',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFE14D),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              children: [
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Product Name',
                                    child: _textField(
                                      controller: _productNameController,
                                      hint: 'Product Name',
                                      validator: (v) => v?.isEmpty ?? true
                                          ? 'Required'
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Brand Name',
                                    child: isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFFE14D),
                                            ),
                                          )
                                        : _dropdownFieldInt(
                                            hint: 'Brand Name',
                                            value: _selectedBrandId,
                                            items: brands
                                                .map(
                                                  (b) => {
                                                    'id': b['brand_id'],
                                                    'name': b['name']
                                                        .toString(),
                                                  },
                                                )
                                                .toList(),
                                            onChanged: (v) => setState(
                                              () => _selectedBrandId = v,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Category',
                                    child: isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFFE14D),
                                            ),
                                          )
                                        : _dropdownFieldInt(
                                            hint: 'Category Name',
                                            value: _selectedCategoryId,
                                            items: categories
                                                .map(
                                                  (c) => {
                                                    'id':
                                                        c['product_category_id'],
                                                    'name': c['name']
                                                        .toString(),
                                                  },
                                                )
                                                .toList(),
                                            onChanged: (v) => setState(
                                              () => _selectedCategoryId = v,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Wholesale Price',
                                    child: _textField(
                                      controller: _wholesalePriceController,
                                      hint: 'Enter Value',
                                      type: TextInputType.number,
                                      validator: (v) {
                                        if (v?.isEmpty ?? true) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(v!) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Selling  Price',
                                    child: _textField(
                                      controller: _sellingPriceController,
                                      hint: 'Enter Value',
                                      type: TextInputType.number,
                                      validator: (v) {
                                        if (v?.isEmpty ?? true) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(v!) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Minimum Profit %',
                                    child: _textField(
                                      controller: _minProfitController,
                                      hint: 'Enter Percent',
                                      type: TextInputType.number,
                                      validator: (v) {
                                        if (v?.isEmpty ?? true) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(v!) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Unit',
                                    child: isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFFE14D),
                                            ),
                                          )
                                        : _dropdownFieldInt(
                                            hint: 'cm, pcs, kg..etc',
                                            value: _selectedUnitId,
                                            items: units
                                                .map(
                                                  (u) => {
                                                    'id': u['unit_id'],
                                                    'name': u['unit_name']
                                                        .toString(),
                                                  },
                                                )
                                                .toList(),
                                            onChanged: (v) => setState(
                                              () => _selectedUnitId = v,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Product Image',
                                    child: InkWell(
                                      onTap: _pickImage,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF3D3D3D),
                                            width: 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.upload_file,
                                              color: Color(0xFFFFE14D),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _selectedImageName ??
                                                    'Upload Image',
                                                style: TextStyle(
                                                  color:
                                                      _selectedImageName != null
                                                      ? Colors.white
                                                      : Colors.white54,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (_selectedImageName != null)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white54,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedImageBytes = null;
                                                    _selectedImageName = null;
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 280,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _saveProduct,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFE14D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 26,
                                          width: 26,
                                          child: CircularProgressIndicator(
                                            color: Colors.black87,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_box_rounded,
                                              color: Colors.black87,
                                              size: 26,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Submit',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
      ],
    );
  }

  // 🟡 Text Field Style
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: validator,
        inputFormatters: type == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // 🟡 Dropdown Field Style for Int IDs
  Widget _dropdownFieldInt({
    required String hint,
    required List<Map<String, dynamic>> items,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: const Color(0xFF1E1E1E),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<int>(
            value: item['id'] as int,
            child: Text(
              item['name'].toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  const FormFieldWrapper({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFE14D),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_config.dart';

class ProductDetailsPopup extends StatefulWidget {
  final String productId;
  final String productName;
  final String brandName;
  final String category;
  final String wholesalePrice;
  final String sellingPrice;
  final String minProfit;
  final VoidCallback onClose;
  final VoidCallback? onDataChanged;
  final int? inventoryIdFilter; // null => show all inventories (Total)
  final int? brandId;
  final int? categoryId;

  const ProductDetailsPopup({
    super.key,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.category,
    required this.wholesalePrice,
    required this.sellingPrice,
    required this.minProfit,
    required this.onClose,
    this.onDataChanged,
    this.inventoryIdFilter,
    this.brandId,
    this.categoryId,
  });

  @override
  State<ProductDetailsPopup> createState() => _ProductDetailsPopupState();
}

class _ProductDetailsPopupState extends State<ProductDetailsPopup> {
  bool isEditMode = false;
  bool isSaving = false;
  bool isLoadingEditData = false;
  String? productImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  // Edit data
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> storageLocations =
      []; // {batch_id, inventory_id, inventory_location, storage_location_descrption}

  int? selectedBrandId;
  int? selectedCategoryId;
  late TextEditingController wholesalePriceController;
  late TextEditingController sellingPriceController;
  late TextEditingController minProfitController;
  Map<int, TextEditingController> storageControllers =
      {}; // inventory_id -> controller

  @override
  void initState() {
    super.initState();
    selectedBrandId = widget.brandId;
    selectedCategoryId = widget.categoryId;
    wholesalePriceController = TextEditingController(
      text: widget.wholesalePrice.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    sellingPriceController = TextEditingController(
      text: widget.sellingPrice.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    minProfitController = TextEditingController(
      text: widget.minProfit.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    _loadProductImage();
  }

  Future<void> _loadProductImage() async {
    try {
      final pid = int.tryParse(widget.productId);
      if (pid == null) return;

      final response = await supabase
          .from('product')
          .select('product_image')
          .eq('product_id', pid)
          .single();

      if (mounted) {
        setState(() {
          productImageUrl = response['product_image'] as String?;
        });
      }
    } catch (e) {
      print('Error loading product image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToSupabase() async {
    if (_selectedImageBytes == null || _selectedImageName == null) return null;

    try {
      // Generate a unique filename using timestamp and product ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _selectedImageName!.toLowerCase().split('.').last;
      final fileName = 'product_${widget.productId}_$timestamp.$extension';

      // Upload to Supabase storage in 'images' bucket
      await supabase.storage
          .from('images')
          .uploadBinary(fileName, _selectedImageBytes!);

      // Get the public URL
      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    wholesalePriceController.dispose();
    sellingPriceController.dispose();
    minProfitController.dispose();
    for (var ctrl in storageControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEditData() async {
    setState(() => isLoadingEditData = true);

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

      // Load storage locations for this product
      final pid = int.tryParse(widget.productId);
      if (pid != null) {
        var batchQuery = supabase
            .from('batch')
            .select('''
              batch_id,
              inventory_id,
              storage_location_descrption,
              inventory:inventory_id(inventory_location)
            ''')
            .eq('product_id', pid);

        if (widget.inventoryIdFilter != null) {
          batchQuery = batchQuery.eq('inventory_id', widget.inventoryIdFilter!);
        }

        final batchResp = await batchQuery;
        final rows = List<Map<String, dynamic>>.from(batchResp);

        // Group by inventory_id - pick first batch per inventory for editing
        Map<int, Map<String, dynamic>> byInventory = {};
        for (final row in rows) {
          final invId = row['inventory_id'] as int?;
          if (invId == null) continue;
          if (!byInventory.containsKey(invId)) {
            byInventory[invId] = {
              'batch_id': row['batch_id'],
              'inventory_id': invId,
              'inventory_location':
                  ((row['inventory'] as Map?)?['inventory_location'] ??
                          'Inventory #$invId')
                      .toString(),
              'storage_location_descrption':
                  (row['storage_location_descrption'] ?? '').toString(),
            };
          }
        }

        storageLocations = byInventory.values.toList();

        // Initialize controllers for each inventory (no auto-save listeners)
        for (final loc in storageLocations) {
          final invId = loc['inventory_id'] as int;
          final controller = TextEditingController(
            text: loc['storage_location_descrption'] ?? '',
          );
          storageControllers[invId] = controller;
        }
      }

      setState(() => isLoadingEditData = false);
    } catch (e) {
      print('Error loading edit data: $e');
      setState(() => isLoadingEditData = false);
    }
  }

  Future<void> _saveChanges() async {
    // Check if any data has changed
    bool hasProductChanges = 
        selectedBrandId != widget.brandId ||
        selectedCategoryId != widget.categoryId ||
        wholesalePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '') !=
            widget.wholesalePrice.replaceAll(RegExp(r'[^0-9.]'), '') ||
        sellingPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '') !=
            widget.sellingPrice.replaceAll(RegExp(r'[^0-9.]'), '') ||
        minProfitController.text.replaceAll(RegExp(r'[^0-9.]'), '') !=
            widget.minProfit.replaceAll(RegExp(r'[^0-9.]'), '') ||
        _selectedImageBytes != null;

    // Check if any storage location has changed
    bool hasStorageChanges = false;
    for (final loc in storageLocations) {
      final invId = loc['inventory_id'] as int;
      final originalStorage = (loc['storage_location_descrption'] ?? '').toString();
      final newStorage = storageControllers[invId]?.text ?? '';
      if (originalStorage != newStorage) {
        hasStorageChanges = true;
        break;
      }
    }

    // If no changes, just exit edit mode without saving
    if (!hasProductChanges && !hasStorageChanges) {
      setState(() {
        isEditMode = false;
      });
      return;
    }

    setState(() => isSaving = true);

    try {
      final pid = int.tryParse(widget.productId);
      if (pid == null) throw 'Invalid product ID';

      // Prepare product data
      final Map<String, dynamic> productData = {
        'brand_id': selectedBrandId,
        'category_id': selectedCategoryId,
        'wholesale_price': double.tryParse(wholesalePriceController.text) ?? 0,
        'selling_price': double.tryParse(sellingPriceController.text) ?? 0,
        'minimum_profit_percent':
            double.tryParse(minProfitController.text) ?? 0,
      };

      // Upload image to Supabase storage if a new one was selected
      if (_selectedImageBytes != null) {
        final imageUrl = await _uploadImageToSupabase();
        if (imageUrl != null) {
          productData['product_image'] = imageUrl;
          // Update local state
          productImageUrl = imageUrl;
        }
      }

      // Update product table
      await supabase.from('product').update(productData).eq('product_id', pid);

      // Update storage locations for each batch
      for (final loc in storageLocations) {
        final batchId = loc['batch_id'] as int;
        final invId = loc['inventory_id'] as int;
        final newStorage = storageControllers[invId]?.text ?? '';

        await supabase
            .from('batch')
            .update({'storage_location_descrption': newStorage})
            .eq('batch_id', batchId);
      }

      // Clear selected image after saving
      _selectedImageBytes = null;
      _selectedImageName = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        widget.onDataChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _toggleEditMode() async {
    if (isEditMode) {
      // Exit edit mode and save changes
      await _saveChanges();
      if (mounted) {
        setState(() => isEditMode = false);
      }
    } else {
      // Enter edit mode
      await _loadEditData();
      setState(() => isEditMode = true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInventoryData() async {
    final pid = int.tryParse(widget.productId);
    if (pid == null) return [];

    try {
      // 1) Get inventories (all or a specific one) to ensure listing even when quantity is 0
      var invQuery = supabase
          .from('inventory')
          .select('inventory_id, inventory_location');
      if (widget.inventoryIdFilter != null) {
        invQuery = invQuery.eq('inventory_id', widget.inventoryIdFilter!);
      }
      final invResp = await invQuery.order('inventory_id');
      final allInventories = List<Map<String, dynamic>>.from(invResp);

      // 2) Get batch rows for this product (all or a specific inventory)
      var batchQuery = supabase
          .from('batch')
          .select('inventory_id, quantity, storage_location_descrption')
          .eq('product_id', pid);
      if (widget.inventoryIdFilter != null) {
        batchQuery = batchQuery.eq('inventory_id', widget.inventoryIdFilter!);
      }
      final batchResp = await batchQuery;
      final rows = List<Map<String, dynamic>>.from(batchResp);

      // 3) Aggregate batch data per inventory
      final Map<int, Map<String, dynamic>> byInventory = {};
      for (final row in rows) {
        final invId = row['inventory_id'] as int?;
        if (invId == null) continue;
        final qty = (row['quantity'] as int?) ?? 0;
        final stor = (row['storage_location_descrption'] ?? '').toString();

        final entry = byInventory.putIfAbsent(
          invId,
          () => {'quantity': 0, 'storage_locations': <String>[]},
        );
        entry['quantity'] = (entry['quantity'] as int) + qty;
        if (stor.trim().isNotEmpty) {
          final list = entry['storage_locations'] as List<String>;
          if (!list.contains(stor)) list.add(stor);
        }
      }

      // 4) Merge: include all inventories, fill missing with zeros
      final List<Map<String, dynamic>> merged = [];
      for (final inv in allInventories) {
        final invId = inv['inventory_id'] as int;
        final invLoc = (inv['inventory_location'] ?? 'Inventory #$invId')
            .toString();
        final agg = byInventory[invId];
        merged.add({
          'inventory_location': invLoc,
          'quantity': (agg?['quantity'] as int?) ?? 0,
          'storage_locations':
              (agg?['storage_locations'] as List<String>?) ?? <String>[],
        });
      }

      return merged;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // خلفية غامقة لإغلاق الـ popup عند الكبس خارجها
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black54),
          ),
        ),

        // محتوى الـ Popup
        Center(
          child: GestureDetector(
            onTap: () {}, // عشان ما يسكر لما تكبس داخل
            child: Container(
              width: 900,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 900,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 العنوان + زر Edit + X
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.productName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFE14D),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: isSaving ? null : _toggleEditMode,
                              icon: Icon(
                                isEditMode ? Icons.done_all : Icons.edit,
                                color: Colors.black87,
                              ),
                              label: Text(
                                isEditMode ? 'Done' : 'Edit Product',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE14D),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🔹 المحتوى (صور + تفاصيل) قابل للسكرول
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ◀ القسم اليسار: الصورة
                          Container(
                            width: 400,
                            height: 500,
                            margin: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: _selectedImageBytes != null
                                        ? Image.memory(
                                            _selectedImageBytes!,
                                            fit: BoxFit.contain,
                                          )
                                        : productImageUrl != null &&
                                              productImageUrl!.isNotEmpty
                                        ? Image.network(
                                            productImageUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.image_not_supported,
                                                    size: 100,
                                                    color: Colors.grey,
                                                  );
                                                },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                color: const Color(0xFFFFE14D),
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.image_not_supported,
                                            size: 100,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                // Edit button overlay
                                if (isEditMode)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Column(
                                      children: [
                                        FloatingActionButton(
                                          heroTag: 'upload_image',
                                          mini: true,
                                          backgroundColor: const Color(
                                            0xFFFFE14D,
                                          ),
                                          onPressed: _pickImage,
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (_selectedImageName != null) ...[
                                          const SizedBox(height: 8),
                                          FloatingActionButton(
                                            heroTag: 'clear_image',
                                            mini: true,
                                            backgroundColor: Colors.red,
                                            onPressed: () {
                                              setState(() {
                                                _selectedImageBytes = null;
                                                _selectedImageName = null;
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ▶ القسم اليمين: التفاصيل (مثل الصورة الثانية)
                          Expanded(
                            child: isLoadingEditData
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFE14D),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // الصف الأول: id / brand / category
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: _DetailField(
                                              label: 'Product id#',
                                              value: widget.productId,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          Expanded(
                                            flex: 1,
                                            child: isEditMode
                                                ? (brands.isEmpty
                                                      ? _DetailField(
                                                          label: 'Brand Name',
                                                          value:
                                                              widget.brandName,
                                                        )
                                                      : _buildDropdownField(
                                                          label: 'Brand Name',
                                                          value:
                                                              selectedBrandId,
                                                          items: brands.map((
                                                            b,
                                                          ) {
                                                            return DropdownMenuItem<
                                                              int
                                                            >(
                                                              value:
                                                                  b['brand_id']
                                                                      as int,
                                                              child: Text(
                                                                b['name']
                                                                    .toString(),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (val) {
                                                            setState(
                                                              () =>
                                                                  selectedBrandId =
                                                                      val,
                                                            );
                                                          },
                                                        ))
                                                : _DetailField(
                                                    label: 'Brand Name',
                                                    value: widget.brandName,
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: isEditMode
                                                ? (categories.isEmpty
                                                      ? _DetailField(
                                                          label: 'Category',
                                                          value:
                                                              widget.category,
                                                        )
                                                      : _buildDropdownField(
                                                          label: 'Category',
                                                          value:
                                                              selectedCategoryId,
                                                          items: categories.map((
                                                            c,
                                                          ) {
                                                            return DropdownMenuItem<
                                                              int
                                                            >(
                                                              value:
                                                                  c['product_category_id']
                                                                      as int,
                                                              child: Text(
                                                                c['name']
                                                                    .toString(),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (val) {
                                                            setState(
                                                              () =>
                                                                  selectedCategoryId =
                                                                      val,
                                                            );
                                                          },
                                                        ))
                                                : _DetailField(
                                                    label: 'Category',
                                                    value: widget.category,
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // الصف الثاني: wholesale / selling / min profit
                                      Row(
                                        children: [
                                          Expanded(
                                            child: isEditMode
                                                ? _buildTextField(
                                                    label: 'Wholesale Price',
                                                    controller:
                                                        wholesalePriceController,
                                                    prefix: '\$',
                                                  )
                                                : _DetailField(
                                                    label: 'Wholesale Price',
                                                    value:
                                                        widget.wholesalePrice,
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: isEditMode
                                                ? _buildTextField(
                                                    label: 'Selling Price',
                                                    controller:
                                                        sellingPriceController,
                                                    prefix: '\$',
                                                  )
                                                : _DetailField(
                                                    label: 'Selling  Price',
                                                    value: widget.sellingPrice,
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: isEditMode
                                                ? _buildTextField(
                                                    label: 'Minimum Profit %',
                                                    controller:
                                                        minProfitController,
                                                    suffix: '%',
                                                  )
                                                : _DetailField(
                                                    label: 'Minimum Profit %',
                                                    value: widget.minProfit,
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),

                                      // 🔹 البيانات الديناميكية: الكمية + مواقع التخزين
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _fetchInventoryData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFFFFE14D),
                                                    ),
                                              ),
                                            );
                                          }

                                          final data = snapshot.data ?? [];

                                          Widget buildQuantitySection() {
                                            final children = <Widget>[
                                              const Text(
                                                'Quantity',
                                                style: TextStyle(
                                                  color: Color(0xFFB7A447),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ];

                                            if (data.isEmpty) {
                                              children.add(
                                                const _InlineDetailRow(
                                                  label: 'N/A',
                                                  value: 'N/A',
                                                ),
                                              );
                                            } else {
                                              for (
                                                int i = 0;
                                                i < data.length;
                                                i++
                                              ) {
                                                final item = data[i];
                                                final label =
                                                    (item['inventory_location'] ??
                                                            'Inventory')
                                                        .toString();
                                                final qty =
                                                    (item['quantity'] ?? 0)
                                                        .toString();
                                                children.add(
                                                  _InlineDetailRow(
                                                    label: label,
                                                    value: '$qty pcs',
                                                  ),
                                                );
                                                if (i != data.length - 1)
                                                  children.add(
                                                    const SizedBox(height: 12),
                                                  );
                                              }
                                            }

                                            children.add(
                                              const SizedBox(height: 30),
                                            );
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: children,
                                            );
                                          }

                                          Widget buildStorageSection() {
                                            final children = <Widget>[
                                              const Text(
                                                'Storage Location',
                                                style: TextStyle(
                                                  color: Color(0xFFB7A447),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ];

                                            if (data.isEmpty) {
                                              children.add(
                                                const _InlineDetailRow(
                                                  label: 'N/A',
                                                  value: 'N/A',
                                                ),
                                              );
                                            } else {
                                              for (
                                                int i = 0;
                                                i < data.length;
                                                i++
                                              ) {
                                                final item = data[i];
                                                final label =
                                                    (item['inventory_location'] ??
                                                            'Inventory')
                                                        .toString();
                                                final storList =
                                                    (item['storage_locations']
                                                            as List?)
                                                        ?.cast<String>() ??
                                                    const <String>[];
                                                final storValue =
                                                    storList.isEmpty
                                                    ? 'N/A'
                                                    : storList.join(', ');

                                                // Check if this location has a batch (can be edited)
                                                final existingLoc =
                                                    storageLocations.firstWhere(
                                                      (loc) =>
                                                          loc['inventory_location'] ==
                                                          label,
                                                      orElse: () => {},
                                                    );
                                                final canEdit =
                                                    isEditMode &&
                                                    existingLoc.isNotEmpty &&
                                                    storValue != 'N/A';

                                                if (canEdit) {
                                                  // Editable row with same design as view mode
                                                  final invId =
                                                      existingLoc['inventory_id']
                                                          as int;
                                                  children.add(
                                                    _EditableInlineDetailRow(
                                                      label: label,
                                                      controller:
                                                          storageControllers[invId]!,
                                                    ),
                                                  );
                                                } else {
                                                  // Read-only row
                                                  children.add(
                                                    _InlineDetailRow(
                                                      label: label,
                                                      value: storValue,
                                                    ),
                                                  );
                                                }

                                                if (i != data.length - 1)
                                                  children.add(
                                                    const SizedBox(height: 12),
                                                  );
                                              }
                                            }

                                            children.add(
                                              const SizedBox(height: 24),
                                            );
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: children,
                                            );
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              buildQuantitySection(),
                                              buildStorageSection(),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
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
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB7A447),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2),
            ),
            prefixText: prefix,
            suffixText: suffix,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          keyboardType: (prefix == '\$' || suffix == '%')
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: (prefix == '\$' || suffix == '%')
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB7A447),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        DropdownButtonFormField<int>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item.value,
              child: Text(
                (item.child as Text).data ?? '',
                overflow: TextOverflow.ellipsis, // 🔥 يمنع overflow
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,

          isExpanded: true, // توسعة لملء العرض وتجنب overflow
          menuMaxHeight: 300,

          // 🔥 يجعل العنصر المختار نفسه يقص النص
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Text(
                (item.child as Text).data ?? '',
                overflow: TextOverflow.ellipsis, // 🔥 أيضا هنا
                maxLines: 1,
              );
            }).toList();
          },

          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: const Color(0xFF1E1E1E),
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isDense: true,
        ),
      ],
    );
  }
}

// 🔹 عنصر عرض حقل التفاصيل (لصفوف الثلاثية فوق)
class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB7A447),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// 🔹 Row على شكل:  Inventory #1  [value]
class _InlineDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _InlineDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 🔹 Editable Row على شكل:  Inventory #1  [editable field]
class _EditableInlineDetailRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _EditableInlineDetailRow({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF3D3D3D),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF3D3D3D),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFFE14D),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

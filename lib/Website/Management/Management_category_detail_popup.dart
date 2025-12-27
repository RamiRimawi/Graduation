import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';

class CategoryDetailPopup extends StatefulWidget {
  final int categoryId;
  final VoidCallback? onUpdate;
  const CategoryDetailPopup({
    super.key,
    required this.categoryId,
    this.onUpdate,
  });
  @override
  State<CategoryDetailPopup> createState() => _CategoryDetailPopupState();
}

class _CategoryDetailPopupState extends State<CategoryDetailPopup> {
  Map<String, dynamic>? categoryData;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true, isEditMode = false, isSaving = false;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategoryDetails();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryDetails() async {
    try {
      final data = await supabase
          .from('product_category')
          .select('product_category_id, name')
          .eq('product_category_id', widget.categoryId)
          .single();
      final productsList = await supabase
          .from('product')
          .select('product_id, name, total_quantity')
          .eq('category_id', widget.categoryId)
          .order('name');
      if (!mounted) return;
      setState(() {
        categoryData = data;
        products = List<Map<String, dynamic>>.from(productsList);
        nameController.text = data['name'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading category details: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      await supabase
          .from('product_category')
          .update({'name': nameController.text.trim()})
          .eq('product_category_id', widget.categoryId);
      await _loadCategoryDetails();
      setState(() {
        isEditMode = false;
        isSaving = false;
      });
      if (widget.onUpdate != null) widget.onUpdate!();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Details',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              children: [
                if (!isEditMode)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB7A447),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => setState(() => isEditMode = true),
                    icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                    label: const Text(
                      'Edit Category',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isEditMode)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF50B2E7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: isSaving ? null : _saveChanges,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 18,
                          ),
                    label: Text(
                      isSaving ? 'Saving...' : 'Done',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFB7A447)),
              ),
            ),
          )
        else if (categoryData == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                'Failed to load category details',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Category ID',
                value: '${categoryData!['product_category_id']}',
                isHighlight: true,
              ),
              const SizedBox(height: 14),
              isEditMode
                  ? _EditField(
                      label: 'Category Name',
                      controller: nameController,
                    )
                  : _DetailRow(
                      label: 'Category Name',
                      value: categoryData!['name'] ?? '—',
                    ),
              const SizedBox(height: 20),
              Text(
                'Products (${products.length})',
                style: GoogleFonts.roboto(
                  color: const Color(0xFFB7A447),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
                ),
                child: products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No products in this category',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xFF3D3D3D), height: 1),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  '${product['product_id']}',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    product['name'] ?? '—',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF50B2E7,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF50B2E7),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Qty: ${product['total_quantity'] ?? 0}',
                                    style: const TextStyle(
                                      color: Color(0xFF50B2E7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: const Color(0xFFB7A447),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
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
              borderSide: const BorderSide(color: Color(0xFFB7A447), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isHighlight;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: const Color(0xFFB7A447),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
          ),
          child: Text(
            value,
            style: GoogleFonts.roboto(
              color: isHighlight ? Colors.amberAccent : Colors.white,
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

void showCategoryDetailPopup(
  BuildContext context,
  int categoryId, {
  VoidCallback? onUpdate,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 180, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CategoryDetailPopup(
            categoryId: categoryId,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

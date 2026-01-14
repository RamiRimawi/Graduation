import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../supabase_config.dart';

class SupplierDetailPopup extends StatefulWidget {
  final int supplierId;
  final VoidCallback? onUpdate;
  const SupplierDetailPopup({
    super.key,
    required this.supplierId,
    this.onUpdate,
  });
  @override
  State<SupplierDetailPopup> createState() => _SupplierDetailPopupState();
}

class _SupplierDetailPopupState extends State<SupplierDetailPopup> {
  Map<String, dynamic>? supplierData;
  List<Map<String, dynamic>> allCities = [];
  List<Map<String, dynamic>> allCategories = [];
  bool isLoading = true, isEditMode = false, isSaving = false;
  final nameController = TextEditingController(),
      emailController = TextEditingController(),
      mobileController = TextEditingController(),
      telephoneController = TextEditingController(),
      addressController = TextEditingController();

  int? selectedCityId;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadSupplierDetails();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    telephoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplierDetails() async {
    try {
      final data = await supabase
          .from('supplier')
          .select(
            'supplier_id, name, mobile_number, telephone_number, supplier_city, address, email, creditor_balance, supplier_category_id',
          )
          .eq('supplier_id', widget.supplierId)
          .single();

      // Get city name separately
      String? cityName;
      if (data['supplier_city'] != null) {
        final cityData = await supabase
            .from('supplier_city')
            .select('name')
            .eq('supplier_city_id', data['supplier_city'])
            .maybeSingle();
        cityName = cityData?['name'];
      }

      // Get category name separately
      String? categoryName;
      if (data['supplier_category_id'] != null) {
        final categoryData = await supabase
            .from('supplier_category')
            .select('name')
            .eq('supplier_category_id', data['supplier_category_id'])
            .maybeSingle();
        categoryName = categoryData?['name'];
      }

      final cities = await supabase
          .from('supplier_city')
          .select('supplier_city_id, name')
          .order('name');

      final categories = await supabase
          .from('supplier_category')
          .select('supplier_category_id, name')
          .order('name');

      if (!mounted) return;
      setState(() {
        supplierData = {
          ...data,
          'supplier_city_name': cityName,
          'supplier_category_name': categoryName,
        };
        allCities = List<Map<String, dynamic>>.from(cities);
        allCategories = List<Map<String, dynamic>>.from(categories);
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        mobileController.text = data['mobile_number'] ?? '';
        telephoneController.text = data['telephone_number'] ?? '';
        addressController.text = data['address'] ?? '';
        selectedCityId = data['supplier_city'] as int?;
        selectedCategoryId = data['supplier_category_id'] as int?;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading supplier details: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      await supabase
          .from('supplier')
          .update({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'mobile_number': mobileController.text.trim(),
            'telephone_number': telephoneController.text.trim(),
            'address': addressController.text.trim(),
            'supplier_city': selectedCityId,
            'supplier_category_id': selectedCategoryId,
          })
          .eq('supplier_id', widget.supplierId);
      await _loadSupplierDetails();
      setState(() {
        isEditMode = false;
        isSaving = false;
      });
      if (widget.onUpdate != null) widget.onUpdate!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier updated successfully')),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Supplier Details',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
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
                      'Edit Supplier',
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
        else if (supplierData == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                'Failed to load supplier details',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DetailRow(
                      label: 'Supplier ID',
                      value: '${supplierData!['supplier_id']}',
                      isHighlight: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditMode
                        ? _EditField(
                            label: 'Company Name',
                            controller: nameController,
                          )
                        : _DetailRow(
                            label: 'Company Name',
                            value: supplierData!['name'] ?? '—',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: isEditMode
                        ? _EditField(
                            label: 'Email',
                            controller: emailController,
                          )
                        : _DetailRow(
                            label: 'Email',
                            value: supplierData!['email']?.isNotEmpty == true
                                ? supplierData!['email']
                                : '—',
                          ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: isEditMode
                        ? _EditField(
                            label: 'Mobile',
                            controller: mobileController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                          )
                        : _DetailRow(
                            label: 'Mobile',
                            value:
                                supplierData!['mobile_number']?.isNotEmpty ==
                                    true
                                ? supplierData!['mobile_number']
                                : '—',
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditMode
                        ? _EditField(
                            label: 'Telephone',
                            controller: telephoneController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 9,
                          )
                        : _DetailRow(
                            label: 'Telephone',
                            value:
                                supplierData!['telephone_number']?.isNotEmpty ==
                                    true
                                ? supplierData!['telephone_number']
                                : '—',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: isEditMode
                        ? _CityAutocomplete(
                            cities: allCities,
                            selectedCityId: selectedCityId,
                            onChanged: (cityId) {
                              setState(() => selectedCityId = cityId);
                            },
                          )
                        : _DetailRow(
                            label: 'City',
                            value: supplierData!['supplier_city_name'] ?? '—',
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditMode
                        ? _EditField(
                            label: 'Address',
                            controller: addressController,
                          )
                        : _DetailRow(
                            label: 'Address',
                            value: supplierData!['address']?.isNotEmpty == true
                                ? supplierData!['address']
                                : '—',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: isEditMode
                        ? _CategoryAutocomplete(
                            categories: allCategories,
                            selectedCategoryId: selectedCategoryId,
                            onChanged: (categoryId) {
                              setState(() => selectedCategoryId = categoryId);
                            },
                          )
                        : _DetailRow(
                            label: 'Category',
                            value:
                                supplierData!['supplier_category_name'] ?? '—',
                          ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DetailRow(
                      label: 'Creditor Balance',
                      value: supplierData!['creditor_balance'] != null
                          ? '\$${supplierData!['creditor_balance']}'
                          : '\$0',
                      valueColor: const Color(0xFF50B2E7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
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
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  const _EditField({
    required this.label,
    required this.controller,
    this.inputFormatters,
    this.maxLength,
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
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            counterText: '',
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

class _CityAutocomplete extends StatelessWidget {
  final List<Map<String, dynamic>> cities;
  final int? selectedCityId;
  final ValueChanged<int?> onChanged;

  const _CityAutocomplete({
    required this.cities,
    required this.selectedCityId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCity = cities.firstWhere(
      (city) => city['supplier_city_id'] == selectedCityId,
      orElse: () => {},
    );
    final initialValue = selectedCity.isNotEmpty ? selectedCity['name'] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: GoogleFonts.roboto(
            color: const Color(0xFFB7A447),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<Map<String, dynamic>>(
          initialValue: initialValue != null
              ? TextEditingValue(text: initialValue)
              : null,
          displayStringForOption: (option) => option['name'].toString(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return cities;
            }
            final search = textEditingValue.text.toLowerCase();
            return cities.where(
              (city) => city['name'].toString().toLowerCase().contains(search),
            );
          },
          onSelected: (Map<String, dynamic> selection) {
            onChanged(selection['supplier_city_id'] as int);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3D3D3D),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type to search cities',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFB7A447),
                      ),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFB7A447),
                      width: 1,
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < options.length - 1
                                    ? const Color(0xFF3D3D3D)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            option['name'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryAutocomplete extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;

  const _CategoryAutocomplete({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories.firstWhere(
      (category) => category['supplier_category_id'] == selectedCategoryId,
      orElse: () => {},
    );
    final initialValue = selectedCategory.isNotEmpty
        ? selectedCategory['name']
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.roboto(
            color: const Color(0xFFB7A447),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<Map<String, dynamic>>(
          initialValue: initialValue != null
              ? TextEditingValue(text: initialValue)
              : null,
          displayStringForOption: (option) => option['name'].toString(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return categories;
            }
            final search = textEditingValue.text.toLowerCase();
            return categories.where(
              (category) =>
                  category['name'].toString().toLowerCase().contains(search),
            );
          },
          onSelected: (Map<String, dynamic> selection) {
            onChanged(selection['supplier_category_id'] as int);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3D3D3D),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type to search categories',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFB7A447),
                      ),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFB7A447),
                      width: 1,
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < options.length - 1
                                    ? const Color(0xFF3D3D3D)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            option['name'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isHighlight;
  final Color? valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.valueColor,
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
              color:
                  valueColor ??
                  (isHighlight ? Colors.amberAccent : Colors.white),
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

void showSupplierDetailPopup(
  BuildContext context,
  int supplierId, {
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
          child: SupplierDetailPopup(
            supplierId: supplierId,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

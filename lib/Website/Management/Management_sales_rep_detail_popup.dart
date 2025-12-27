import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../supabase_config.dart';

class SalesRepDetailPopup extends StatefulWidget {
  final int salesRepId;
  final VoidCallback? onUpdate;

  const SalesRepDetailPopup({
    super.key,
    required this.salesRepId,
    this.onUpdate,
  });

  @override
  State<SalesRepDetailPopup> createState() => _SalesRepDetailPopupState();
}

class _SalesRepDetailPopupState extends State<SalesRepDetailPopup> {
  Map<String, dynamic>? salesRepData;
  List<Map<String, dynamic>> assignedCustomers = [];
  List<Map<String, dynamic>> allCities = [];
  List<Map<String, dynamic>> allCustomers = [];
  bool isLoading = true;
  bool isEditMode = false;
  bool isSaving = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final telephoneController = TextEditingController();

  int? selectedCityId;
  List<int> selectedCustomerIds = [];

  @override
  void initState() {
    super.initState();
    _loadSalesRepDetails();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    telephoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesRepDetails() async {
    try {
      final data = await supabase
          .from('sales_representative')
          .select('''
            sales_rep_id, name, mobile_number, telephone_number, sales_rep_city, email
          ''')
          .eq('sales_rep_id', widget.salesRepId)
          .single();

      // Get city name separately
      String? cityName;
      if (data['sales_rep_city'] != null) {
        final cityData = await supabase
            .from('sales_rep_city')
            .select('name')
            .eq('sales_rep_city_id', data['sales_rep_city'])
            .maybeSingle();
        cityName = cityData?['name'];
      }

      final customers = await supabase
          .from('customer')
          .select('customer_id, name')
          .eq('sales_rep_id', widget.salesRepId)
          .order('name');

      final cities = await supabase
          .from('sales_rep_city')
          .select('sales_rep_city_id, name')
          .order('name');

      final allCustomersList = await supabase
          .from('customer')
          .select('customer_id, name')
          .order('name');

      if (!mounted) return;
      setState(() {
        // Store the data with city name added
        salesRepData = {...data, 'sales_rep_city_name': cityName};
        assignedCustomers = List<Map<String, dynamic>>.from(customers);
        allCities = List<Map<String, dynamic>>.from(cities);
        allCustomers = List<Map<String, dynamic>>.from(allCustomersList);
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        mobileController.text = data['mobile_number'] ?? '';
        telephoneController.text = data['telephone_number'] ?? '';
        selectedCityId = data['sales_rep_city'] as int?;
        selectedCustomerIds = customers
            .map<int>((c) => c['customer_id'] as int)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sales rep details: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      // Update sales rep basic info
      await supabase
          .from('sales_representative')
          .update({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'mobile_number': mobileController.text.trim(),
            'telephone_number': telephoneController.text.trim(),
            'sales_rep_city': selectedCityId,
          })
          .eq('sales_rep_id', widget.salesRepId);

      // Update customer assignments
      // First, unassign all current customers
      final currentCustomerIds = assignedCustomers
          .map((c) => c['customer_id'] as int)
          .toList();
      if (currentCustomerIds.isNotEmpty) {
        await supabase
            .from('customer')
            .update({'sales_rep_id': null})
            .inFilter('customer_id', currentCustomerIds);
      }

      // Then assign selected customers
      if (selectedCustomerIds.isNotEmpty) {
        await supabase
            .from('customer')
            .update({'sales_rep_id': widget.salesRepId})
            .inFilter('customer_id', selectedCustomerIds);
      }

      await _loadSalesRepDetails();
      setState(() {
        isEditMode = false;
        isSaving = false;
      });
      if (widget.onUpdate != null) widget.onUpdate!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales representative updated successfully'),
          ),
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Representative Details',
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
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 18,
                      ),
                      label: const Text(
                        'Edit Sales Rep',
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
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.black,
                                ),
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
          else if (salesRepData == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'Failed to load sales representative details',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        label: 'Sales Rep ID',
                        value: '${salesRepData!['sales_rep_id']}',
                        isHighlight: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: isEditMode
                          ? _EditField(
                              label: 'Name',
                              controller: nameController,
                            )
                          : _DetailRow(
                              label: 'Name',
                              value: salesRepData!['name'] ?? '—',
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
                              value: salesRepData!['email']?.isNotEmpty == true
                                  ? salesRepData!['email']
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
                                  salesRepData!['mobile_number']?.isNotEmpty ==
                                      true
                                  ? salesRepData!['mobile_number']
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
                                  salesRepData!['telephone_number']
                                          ?.isNotEmpty ==
                                      true
                                  ? salesRepData!['telephone_number']
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
                          ? _CityDropdown(
                              cities: allCities,
                              selectedCityId: selectedCityId,
                              onChanged: (cityId) {
                                setState(() => selectedCityId = cityId);
                              },
                            )
                          : _DetailRow(
                              label: 'City',
                              value:
                                  salesRepData!['sales_rep_city_name'] ?? '—',
                            ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Customers',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFFB7A447),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          isEditMode
                              ? _CustomerSelector(
                                  allCustomers: allCustomers,
                                  selectedCustomerIds: selectedCustomerIds,
                                  onSelectionChanged: (ids) {
                                    setState(() => selectedCustomerIds = ids);
                                  },
                                )
                              : Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF3D3D3D),
                                      width: 1,
                                    ),
                                  ),
                                  child: assignedCustomers.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Center(
                                            child: Text(
                                              'No customers assigned',
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
                                          itemCount: assignedCustomers.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                color: Color(0xFF3D3D3D),
                                                height: 1,
                                              ),
                                          itemBuilder: (context, index) {
                                            final customer =
                                                assignedCustomers[index];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '${customer['customer_id']}',
                                                    style: const TextStyle(
                                                      color: Colors.amberAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      customer['name'] ?? '—',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
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
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
        ],
      ),
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

class _CityDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> cities;
  final int? selectedCityId;
  final ValueChanged<int?> onChanged;

  const _CityDropdown({
    required this.cities,
    required this.selectedCityId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Find the selected city name
    final selectedCity = cities.firstWhere(
      (city) => city['sales_rep_city_id'] == selectedCityId,
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
            onChanged(selection['sales_rep_city_id'] as int);
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

class _CustomerSelector extends StatefulWidget {
  final List<Map<String, dynamic>> allCustomers;
  final List<int> selectedCustomerIds;
  final ValueChanged<List<int>> onSelectionChanged;

  const _CustomerSelector({
    required this.allCustomers,
    required this.selectedCustomerIds,
    required this.onSelectionChanged,
  });

  @override
  State<_CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<_CustomerSelector> {
  List<Map<String, dynamic>> get _selectedCustomers {
    return widget.allCustomers
        .where((c) => widget.selectedCustomerIds.contains(c['customer_id']))
        .toList();
  }

  List<Map<String, dynamic>> get _availableCustomers {
    return widget.allCustomers
        .where((c) => !widget.selectedCustomerIds.contains(c['customer_id']))
        .toList();
  }

  void _removeCustomer(int customerId) {
    final newSelection = List<int>.from(widget.selectedCustomerIds);
    newSelection.remove(customerId);
    widget.onSelectionChanged(newSelection);
  }

  void _addCustomer(int customerId) {
    final newSelection = List<int>.from(widget.selectedCustomerIds);
    newSelection.add(customerId);
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected customers as chips
        if (_selectedCustomers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCustomers.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c['name'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _removeCustomer(c['customer_id'] as int),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          const Text(
            'No customers selected',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 12),
        // Autocomplete search with Add button
        Row(
          children: [
            Expanded(
              child: _availableCustomers.isEmpty
                  ? Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF3D3D3D),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'All customers assigned',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) =>
                          option['name'].toString(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _availableCustomers;
                        }
                        final search = textEditingValue.text.toLowerCase();
                        return _availableCustomers.where(
                          (customer) => customer['name']
                              .toString()
                              .toLowerCase()
                              .contains(search),
                        );
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        _addCustomer(selection['customer_id'] as int);
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Type to search customers',
                                  hintStyle: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
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
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
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

void showSalesRepDetailPopup(
  BuildContext context,
  int salesRepId, {
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
          child: SalesRepDetailPopup(
            salesRepId: salesRepId,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

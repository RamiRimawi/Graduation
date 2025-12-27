import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../MobileAccounts/MobileAccounts_shared_popup_widgets.dart';
import '../../supabase_config.dart';

class CustomerDetailPopup extends StatefulWidget {
  final int customerId;
  final VoidCallback? onUpdate;

  const CustomerDetailPopup({
    super.key,
    required this.customerId,
    this.onUpdate,
  });

  @override
  State<CustomerDetailPopup> createState() => _CustomerDetailPopupState();
}

class _CustomerDetailPopupState extends State<CustomerDetailPopup> {
  Map<String, dynamic>? customerData;
  bool isLoading = true;
  bool isEditMode = false;
  bool isSaving = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final telephoneController = TextEditingController();
  final addressController = TextEditingController();

  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> salesReps = [];
  int? selectedCityId;
  int? selectedSalesRepId;
  String locationValue = '';
  List<Map<String, dynamic>> _quarters = [];
  bool _loadingQuarters = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
    _loadDropdownData();
    _loadQuarters();
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

  Future<void> _loadCustomerDetails() async {
    try {
      final data = await supabase
          .from('customer')
          .select('''
            customer_id,
            name,
            mobile_number,
            telephone_number,
            customer_city,
            customer_city_row:customer_city(name),
            address,
            email,
            balance_debit,
            sales_rep_id,
            sales_representative:sales_rep_id(sales_rep_id, name)
          ''')
          .eq('customer_id', widget.customerId)
          .single();

      if (!mounted) return;
      setState(() {
        customerData = data;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        mobileController.text = data['mobile_number'] ?? '';
        telephoneController.text = data['telephone_number'] ?? '';
        addressController.text = data['address'] ?? '';
        selectedCityId = data['customer_city'];
        selectedSalesRepId = data['sales_rep_id'];
        locationValue = (data['customer_city_row']?['name'] ?? '').toString();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final citiesData = await supabase
          .from('customer_city')
          .select('customer_city_id, name')
          .order('name');
      final salesRepsData = await supabase
          .from('sales_representative')
          .select('sales_rep_id, name')
          .order('name');

      if (!mounted) return;
      setState(() {
        cities = List<Map<String, dynamic>>.from(citiesData);
        salesReps = List<Map<String, dynamic>>.from(salesRepsData);
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadQuarters() async {
    try {
      final data = await supabase
          .from('customer_quarters')
          .select('name, customer_city(name)')
          .order('name');
      if (!mounted) return;
      setState(() {
        _quarters = (data as List)
            .where(
              (e) =>
                  e['name'] != null &&
                  e['customer_city'] != null &&
                  e['customer_city']['name'] != null,
            )
            .map<Map<String, dynamic>>(
              (e) => {'quarter': e['name'], 'city': e['customer_city']['name']},
            )
            .toList();
        _loadingQuarters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingQuarters = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      int? cityIdToUse = selectedCityId;
      final loc = locationValue.trim();
      if (loc.isNotEmpty) {
        String cityName = loc;
        String quarterName = '';
        if (loc.contains(' - ')) {
          final parts = loc.split(' - ');
          cityName = parts[0].trim();
          quarterName = parts.length > 1 ? parts[1].trim() : '';
        }
        final existingCity = await supabase
            .from('customer_city')
            .select('customer_city_id')
            .eq('name', cityName)
            .maybeSingle();
        if (existingCity != null && existingCity['customer_city_id'] != null) {
          cityIdToUse = existingCity['customer_city_id'] as int;
        } else {
          final insertedCity = await supabase
              .from('customer_city')
              .insert({'name': cityName})
              .select()
              .single();
          cityIdToUse = insertedCity['customer_city_id'] as int;
        }
        if (quarterName.isNotEmpty) {
          final existingQuarter = await supabase
              .from('customer_quarters')
              .select('quarter_id')
              .eq('name', quarterName)
              .eq('customer_city', cityIdToUse)
              .maybeSingle();
          if (existingQuarter == null) {
            await supabase.from('customer_quarters').insert({
              'name': quarterName,
              'customer_city': cityIdToUse,
            });
          }
        }
      }
      await supabase
          .from('customer')
          .update({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'mobile_number': mobileController.text.trim(),
            'telephone_number': telephoneController.text.trim(),
            'address': addressController.text.trim(),
            'customer_city': cityIdToUse,
            'sales_rep_id': selectedSalesRepId,
          })
          .eq('customer_id', widget.customerId);

      await _loadCustomerDetails();
      setState(() {
        isEditMode = false;
        isSaving = false;
      });
      if (widget.onUpdate != null) widget.onUpdate!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Details',
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
                      'Edit Customer',
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
        else if (customerData == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                'Failed to load customer details',
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
                      label: 'Customer ID',
                      value: '${customerData!['customer_id']}',
                      isHighlight: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditMode
                        ? _EditField(label: 'Name', controller: nameController)
                        : _DetailRow(
                            label: 'Name',
                            value: customerData!['name'] ?? '—',
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
                            value: customerData!['email']?.isNotEmpty == true
                                ? customerData!['email']
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
                                customerData!['mobile_number']?.isNotEmpty ==
                                    true
                                ? customerData!['mobile_number']
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
                                customerData!['telephone_number']?.isNotEmpty ==
                                    true
                                ? customerData!['telephone_number']
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
                        ? (_loadingQuarters
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: GoogleFonts.roboto(
                                        color: const Color(0xFFB7A447),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF3D3D3D),
                                          width: 1,
                                        ),
                                      ),
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Color(0xFFB7A447),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : AutocompleteCityQuarter(
                                  label: 'Location',
                                  cityQuarters: _quarters
                                      .map(
                                        (e) => {
                                          'city': e['city'] as String,
                                          'quarter': e['quarter'] as String,
                                        },
                                      )
                                      .toList(),
                                  initialValue: locationValue.isEmpty
                                      ? null
                                      : locationValue,
                                  onChanged: (value) {
                                    setState(() {
                                      locationValue = value;
                                    });
                                  },
                                  errorText: null,
                                ))
                        : _DetailRow(
                            label: 'Location',
                            value:
                                customerData!['customer_city_row']?['name'] ??
                                '—',
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
                            value: customerData!['address']?.isNotEmpty == true
                                ? customerData!['address']
                                : '—',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DetailRow(
                      label: 'Balance Debit',
                      value: customerData!['balance_debit'] != null
                          ? '\$${customerData!['balance_debit']}'
                          : '\$0',
                      valueColor: const Color(0xFF50B2E7),
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
                        ? _SearchableSalesRep(
                            label: 'Sales Representative',
                            salesReps: salesReps,
                            initialName:
                                (customerData!['sales_representative']?['name'] ??
                                        '')
                                    .toString(),
                            onSelected: (rep) {
                              setState(() {
                                selectedSalesRepId =
                                    rep?['sales_rep_id'] as int?;
                              });
                            },
                          )
                        : _DetailRow(
                            label: 'Sales Representative',
                            value:
                                customerData!['sales_representative']?['name'] ??
                                'Not Assigned',
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
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



class _SearchableSalesRep extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> salesReps;
  final String initialName;
  final ValueChanged<Map<String, dynamic>?> onSelected;

  const _SearchableSalesRep({
    required this.label,
    required this.salesReps,
    required this.initialName,
    required this.onSelected,
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
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (opt) => (opt['name'] ?? '').toString(),
          optionsBuilder: (TextEditingValue tev) {
            final q = tev.text.toLowerCase();
            if (q.isEmpty) return salesReps;
            return salesReps.where(
              (r) => (r['name'] ?? '').toString().toLowerCase().contains(q),
            );
          },
          onSelected: (opt) => onSelected(opt),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text.isEmpty && initialName.isNotEmpty) {
              controller.text = initialName;
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onFieldSubmitted(),
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
                  borderSide: const BorderSide(
                    color: Color(0xFFB7A447),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: const Color(0xFF2D2D2D),
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    minWidth: 300,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                    itemBuilder: (context, index) {
                      final opt = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            (opt['name'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white),
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

void showCustomerDetailPopup(
  BuildContext context,
  int customerId, {
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
          child: CustomerDetailPopup(
            customerId: customerId,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

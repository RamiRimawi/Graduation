import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'shared_popup_widgets.dart';
import '../supabase_config.dart';

class SupplierFormPopup extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;

  const SupplierFormPopup({
    super.key,
    required this.cities,
    required this.onSubmit,
  });

  @override
  State<SupplierFormPopup> createState() => _SupplierFormPopupState();
}

class _SupplierFormPopupState extends State<SupplierFormPopup> {
  final company = TextEditingController();
  final id = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();
  final address = TextEditingController();
  final creditor = TextEditingController(text: '0');

  String cityQuarter = ''; // Will hold "City - Quarter"
  List<Map<String, String>> _cityQuarters = [];
  bool _loadingCities = true;

  // Error messages for each field
  String? idError;
  String? companyError;
  String? emailError;
  String? mobileError;
  String? telError;
  String? addressError;
  String? cityQuarterError;

  @override
  void initState() {
    super.initState();
    _loadCityQuarters();
    // ensure creditor shows default 0 and caret at end
    if (creditor.text.isEmpty) creditor.text = '0';
    creditor.selection = TextSelection.fromPosition(
      TextPosition(offset: creditor.text.length),
    );
  }

  Future<void> _loadCityQuarters() async {
    try {
      // For suppliers, we'll create dummy quarters based on cities
      // In a real scenario, you'd fetch from a supplier_quarters table
      final data = await supabase
          .from('supplier_city')
          .select('name')
          .order('name');
      if (!mounted) return;
      setState(() {
        // Create city-quarter combinations
        _cityQuarters = (data as List).where((e) => e['name'] != null).expand((
          e,
        ) {
          final cityName = e['name'] as String;
          // Add default quarters for each city
          return [
            {'city': cityName, 'quarter': 'Center'},
            {'city': cityName, 'quarter': 'Industrial Zone'},
            {'city': cityName, 'quarter': 'Commercial District'},
          ];
        }).toList();
        _loadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
      });
    }
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'id':
          idError = null;
          break;
        case 'company':
          companyError = null;
          break;
        case 'email':
          emailError = null;
          break;
        case 'mobile':
          mobileError = null;
          break;
        case 'tel':
          telError = null;
          break;
        case 'address':
          addressError = null;
          break;
        case 'cityQuarter':
          cityQuarterError = null;
          break;
      }
    });
  }

  @override
  void dispose() {
    id.dispose();
    company.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    address.dispose();
    creditor.dispose();
    super.dispose();
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
              'Add Supplier',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const SizedBox(height: 6),
        TwoColRow(
          left: FieldInput(
            controller: id,
            label: 'Supplier ID',
            hint: 'Enter supplier id',
            type: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
            errorText: idError,
            onChanged: () => _clearError('id'),
          ),
          right: const SizedBox(),
        ),
        const SizedBox(height: 12),

        TwoColRow(
          left: FieldInput(
            controller: company,
            label: 'Company Name',
            hint: 'Entre Company Name',
            errorText: companyError,
            onChanged: () => _clearError('company'),
          ),
          right: FieldInput(
            controller: email,
            label: 'Email',
            hint: 'Entre Email',
            type: TextInputType.emailAddress,
            errorText: emailError,
            onChanged: () => _clearError('email'),
          ),
        ),

        const SizedBox(height: 18),

        TwoColRow(
          left: FieldInput(
            controller: mobile,
            label: 'Mobile Number',
            hint: 'Entre Mobile Number',
            type: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            errorText: mobileError,
            onChanged: () => _clearError('mobile'),
          ),
          right: FieldInput(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
            errorText: telError,
            onChanged: () => _clearError('tel'),
          ),
        ),

        const SizedBox(height: 18),

        TwoColRow(
          left: _loadingCities
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFFB7A447),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
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
                          valueColor: AlwaysStoppedAnimation(Color(0xFFB7A447)),
                        ),
                      ),
                    ),
                  ],
                )
              : AutocompleteCityQuarter(
                  label: 'Location',
                  cityQuarters: _cityQuarters,
                  initialValue: cityQuarter.isEmpty ? null : cityQuarter,
                  onChanged: (value) {
                    setState(() {
                      cityQuarter = value;
                      cityQuarterError = null;
                    });
                  },
                  errorText: cityQuarterError,
                ),
          right: FieldInput(
            controller: address,
            label: 'Address',
            hint: 'Entre Address',
            errorText: addressError,
            onChanged: () => _clearError('address'),
          ),
        ),

        const SizedBox(height: 18),

        TwoColRow(
          left: FieldInput(
            controller: creditor,
            label: 'Creditor balance',
            hint: '',
            type: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            suffix: const Text(
              '\$',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          right: null,
        ),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SubmitButton(
              text: 'Submit',
              icon: Icons.person_add_alt_1,
              onTap: () async {
                // Clear all previous errors
                setState(() {
                  idError = null;
                  companyError = null;
                  emailError = null;
                  mobileError = null;
                  telError = null;
                  addressError = null;
                  cityQuarterError = null;
                });

                bool hasError = false;

                // Validate id
                final idText = id.text.trim();
                final idVal = int.tryParse(idText);
                if (idText.isEmpty || idVal == null) {
                  setState(() {
                    idError = 'Please enter a valid ID';
                  });
                  hasError = true;
                } else if (idText.length != 9) {
                  setState(() {
                    idError = 'ID must be exactly 9 digits';
                  });
                  hasError = true;
                }

                // Validate company name
                final companyText = company.text.trim();
                if (companyText.isEmpty) {
                  setState(() {
                    companyError = 'Company name is required';
                  });
                  hasError = true;
                }

                // Validate email
                final emailText = email.text.trim();
                if (emailText.isNotEmpty) {
                  final emailRegex = RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}");
                  if (!emailRegex.hasMatch(emailText)) {
                    setState(() {
                      emailError = 'Please enter a valid email';
                    });
                    hasError = true;
                  }
                }

                // Validate phone lengths
                final mob = mobile.text.trim();
                final telText = tel.text.trim();
                if (mob.isNotEmpty && mob.length != 10) {
                  setState(() {
                    mobileError = 'Mobile must be 10 digits';
                  });
                  hasError = true;
                }
                if (telText.isNotEmpty && telText.length != 9) {
                  setState(() {
                    telError = 'Telephone must be 9 digits';
                  });
                  hasError = true;
                }

                // Validate address
                final addressText = address.text.trim();
                if (addressText.isEmpty) {
                  setState(() {
                    addressError = 'Address is required';
                  });
                  hasError = true;
                }

                // Validate city-quarter
                if (cityQuarter.isEmpty || !cityQuarter.contains(' - ')) {
                  setState(() {
                    cityQuarterError = 'Location is required';
                  });
                  hasError = true;
                }

                if (hasError) return;

                try {
                  // Check if ID already exists
                  final existingSupplier = await supabase
                      .from('supplier')
                      .select('supplier_id')
                      .eq('supplier_id', idVal!)
                      .maybeSingle();

                  if (existingSupplier != null) {
                    setState(() {
                      idError = 'This ID already exists in database';
                    });
                    return;
                  }

                  // Parse city from city-quarter format
                  final parts = cityQuarter.split(' - ');
                  final cityName = parts[0].trim();

                  final existing = await supabase
                      .from('supplier_city')
                      .select('supplier_city_id')
                      .eq('name', cityName)
                      .maybeSingle();
                  int cityId;
                  if (existing != null &&
                      existing['supplier_city_id'] != null) {
                    cityId = existing['supplier_city_id'] as int;
                  } else {
                    final insertedCity = await supabase
                        .from('supplier_city')
                        .insert({'name': cityName})
                        .select()
                        .single();
                    cityId = insertedCity['supplier_city_id'] as int;
                  }

                  final inserted = await supabase
                      .from('supplier')
                      .insert({
                        'supplier_id': idVal!,
                        'name': company.text.trim(),
                        'mobile_number': mobile.text.trim(),
                        'telephone_number': tel.text.trim(),
                        'supplier_city': cityId,
                        'address': address.text.trim(),
                        'creditor_balance': double.tryParse(creditor.text) ?? 0,
                      })
                      .select()
                      .maybeSingle();

                  if (inserted == null) throw Exception('Insert failed');

                  widget.onSubmit({
                    'company': inserted['name'],
                    'city': cityName,
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add supplier: $e')),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

void showSupplierPopup(
  BuildContext context,
  List<String> cities,
  Function(Map<String, dynamic>) onSubmit,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Dialog(
          backgroundColor: const Color(0xFF2D2D2D),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 180,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SupplierFormPopup(cities: cities, onSubmit: onSubmit),
          ),
        ),
      );
    },
  );
}

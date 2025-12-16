import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'MobileAccounts_shared_popup_widgets.dart';
import '../supabase_config.dart';

class CustomerFormPopup extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;

  const CustomerFormPopup({
    super.key,
    required this.cities,
    required this.onSubmit,
  });

  @override
  State<CustomerFormPopup> createState() => _CustomerFormPopupState();
}

class _CustomerFormPopupState extends State<CustomerFormPopup> {
  final name = TextEditingController();
  final id = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();
  final address = TextEditingController();
  final debit = TextEditingController(text: '0');

  String cityQuarter = ''; // Will hold "City - Quarter"
  List<Map<String, dynamic>> _quarters = [];
  bool _loadingQuarters = true;

  // Error messages for each field
  String? idError;
  String? nameError;
  String? emailError;
  String? mobileError;
  String? telError;
  String? addressError;
  String? cityQuarterError;

  @override
  void initState() {
    super.initState();
    _loadQuarters();
    // ensure debit shows default 0 and caret at end
    if (debit.text.isEmpty) debit.text = '0';
    debit.selection = TextSelection.fromPosition(
      TextPosition(offset: debit.text.length),
    );
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
      setState(() {
        _loadingQuarters = false;
      });
    }
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'id':
          idError = null;
          break;
        case 'name':
          nameError = null;
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
    name.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    address.dispose();
    debit.dispose();
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
              'Add Customer',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        TwoColRow(
          left: FieldInput(
            controller: id,
            label: 'Customer ID',
            hint: 'Enter customer id',
            type: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
            errorText: idError,
            onChanged: () => _clearError('id'),
          ),
          right: const SizedBox(),
        ),
        const SizedBox(height: 16),

        TwoColRow(
          left: FieldInput(
            controller: name,
            label: 'Customer Name',
            hint: 'Entre full Name',
            errorText: nameError,
            onChanged: () => _clearError('name'),
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
            type: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: mobileError,
            onChanged: () => _clearError('mobile'),
          ),
          right: FieldInput(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: telError,
            onChanged: () => _clearError('tel'),
          ),
        ),
        const SizedBox(height: 18),

        TwoColRow(
          left: _loadingQuarters
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
                      height: 42,
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
                        height: 22,
                        width: 22,
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
                  cityQuarters: _quarters
                      .map(
                        (e) => {
                          'city': e['city'] as String,
                          'quarter': e['quarter'] as String,
                        },
                      )
                      .toList(),
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
            controller: debit,
            label: 'Debit balance',
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

        const SizedBox(height: 18),

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
                  nameError = null;
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

                // Validate name
                final nameText = name.text.trim();
                if (nameText.isEmpty) {
                  setState(() {
                    nameError = 'Customer name is required';
                  });
                  hasError = true;
                }

                // Validate email format if provided
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

                // Validate mobile/telephone lengths
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
                  final existingCustomer = await supabase
                      .from('customer')
                      .select('customer_id')
                      .eq('customer_id', idVal!)
                      .maybeSingle();

                  if (existingCustomer != null) {
                    setState(() {
                      idError = 'This ID already exists in database';
                    });
                    return;
                  }

                  // Parse city and quarter
                  final parts = cityQuarter.split(' - ');
                  final cityName = parts[0].trim();
                  final quarterName = parts.length > 1 ? parts[1].trim() : '';

                  // ensure customer city exists (or create)
                  final existingCity = await supabase
                      .from('customer_city')
                      .select('customer_city_id')
                      .eq('name', cityName)
                      .maybeSingle();
                  int cityId;
                  if (existingCity != null &&
                      existingCity['customer_city_id'] != null) {
                    cityId = existingCity['customer_city_id'] as int;
                  } else {
                    final insertedCity = await supabase
                        .from('customer_city')
                        .insert({'name': cityName})
                        .select()
                        .single();
                    cityId = insertedCity['customer_city_id'] as int;
                  }

                  // ensure quarter exists (or create)
                  if (quarterName.isNotEmpty) {
                    final existingQuarter = await supabase
                        .from('customer_quarters')
                        .select('quarter_id')
                        .eq('name', quarterName)
                        .eq('customer_city', cityId)
                        .maybeSingle();
                    if (existingQuarter == null) {
                      await supabase.from('customer_quarters').insert({
                        'name': quarterName,
                        'customer_city': cityId,
                      });
                    }
                  }

                  // insert customer
                  final inserted = await supabase
                      .from('customer')
                      .insert({
                        'customer_id': idVal,
                        'name': name.text.trim(),
                        'mobile_number': mobile.text.trim(),
                        'telephone_number': tel.text.trim(),
                        'customer_city': cityId,
                        'address': address.text.trim(),
                        'email': email.text.trim(),
                        'balance_debit': double.tryParse(debit.text) ?? 0,
                      })
                      .select()
                      .maybeSingle();

                  if (inserted == null) throw Exception('Insert failed');

                  // call parent callback with the form values (parent will close dialog and update lists)
                  widget.onSubmit({'name': inserted['name'], 'city': cityName});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add customer: $e')),
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

void showCustomerPopup(
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
            horizontal: 120,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CustomerFormPopup(cities: cities, onSubmit: onSubmit),
          ),
        ),
      );
    },
  );
}

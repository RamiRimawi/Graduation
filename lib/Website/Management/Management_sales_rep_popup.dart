import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../MobileAccounts/MobileAccounts_shared_popup_widgets.dart';
import '../../supabase_config.dart';

class SalesRepFormPopup extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;

  const SalesRepFormPopup({
    super.key,
    required this.cities,
    required this.onSubmit,
  });

  @override
  State<SalesRepFormPopup> createState() => _SalesRepFormPopupState();
}

class _SalesRepFormPopupState extends State<SalesRepFormPopup> {
  final name = TextEditingController();
  final id = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();

  late String city;

  // Customers data
  List<Map<String, dynamic>> _customers = [];
  final List<Map<String, dynamic>> _selectedCustomers = [];
  String? _selectedAddCustomerId; // holds customer_id as String
  bool _loadingCustomers = true;

  // Cities data
  List<String> _cities = [];
  bool _loadingCities = true;

  // Error messages for each field
  String? idError;
  String? nameError;
  String? emailError;
  String? mobileError;
  String? telError;
  String? cityError;

  @override
  void initState() {
    super.initState();
    city = '';
    _loadCustomers();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final data = await supabase
          .from('sales_rep_city')
          .select('name')
          .order('name');
      if (!mounted) return;
      setState(() {
        _cities = (data as List)
            .where((e) => e['name'] != null)
            .map<String>((e) => e['name'] as String)
            .toList();
        _loadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
      });
    }
  }

  Future<void> _loadCustomers() async {
    try {
      // Retrieve only customers whose sales_rep_id is null
      // Supabase Dart: use filter with 'is' operator and string 'null'
      final data = await supabase
          .from('customer')
          .select('customer_id,name')
          .filter('sales_rep_id', 'is', 'null')
          .order('name');
      if (!mounted) return;
      setState(() {
        _customers = (data as List)
            .where((e) => e['customer_id'] != null && e['name'] != null)
            .map<Map<String, dynamic>>(
              (e) => {'customer_id': e['customer_id'], 'name': e['name']},
            )
            .toList();
        _loadingCustomers = false;
        _selectedAddCustomerId = _availableCustomers().isEmpty
            ? null
            : _availableCustomers().first['customer_id'].toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCustomers = false;
      });
      // Silent fail; could show snackbar if needed
    }
  }

  List<Map<String, dynamic>> _availableCustomers() {
    final selectedIds = _selectedCustomers.map((e) => e['customer_id']).toSet();
    return _customers
        .where((c) => !selectedIds.contains(c['customer_id']))
        .toList();
  }

  void _addSelectedCustomer() {
    if (_selectedAddCustomerId == null) return;
    final idInt = int.tryParse(_selectedAddCustomerId!);
    if (idInt == null) return;
    final match = _customers.firstWhere(
      (c) => c['customer_id'] == idInt,
      orElse: () => {},
    );
    if (match.isEmpty) return;
    setState(() {
      _selectedCustomers.add(match);
      final avail = _availableCustomers();
      _selectedAddCustomerId = avail.isEmpty
          ? null
          : avail.first['customer_id'].toString();
    });
  }

  void _removeSelectedCustomer(int customerId) {
    setState(() {
      _selectedCustomers.removeWhere(
        (element) => element['customer_id'] == customerId,
      );
      final avail = _availableCustomers();
      if (_selectedAddCustomerId == null && avail.isNotEmpty) {
        _selectedAddCustomerId = avail.first['customer_id'].toString();
      }
    });
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
        case 'city':
          cityError = null;
          break;
      }
    });
  }

  @override
  void dispose() {
    try {
      id.dispose();
    } catch (_) {}
    try {
      name.dispose();
    } catch (_) {}
    try {
      email.dispose();
    } catch (_) {}
    try {
      mobile.dispose();
    } catch (_) {}
    try {
      tel.dispose();
    } catch (_) {}
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
              'Add Sales Rep',
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
        TwoColRow(
          left: FieldInput(
            controller: id,
            label: 'Sales Rep ID',
            hint: 'Enter sales rep id',
            type: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
            errorText: idError,
            onChanged: () => _clearError('id'),
          ),
          right: const SizedBox(),
        ),
        const SizedBox(height: 14),

        TwoColRow(
          left: FieldInput(
            controller: name,
            label: 'Full Name',
            hint: 'Entre Full Name',
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
        const SizedBox(height: 14),

        TwoColRow(
          left: _loadingCities
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City',
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
              : AutocompleteCity(
                  label: 'City',
                  cities: _cities,
                  initialValue: city.isEmpty ? null : city,
                  onChanged: (value) {
                    setState(() {
                      city = value;
                      cityError = null;
                    });
                  },
                  errorText: cityError,
                ),
          right: const SizedBox(),
        ),

        const SizedBox(height: 16),

        // Assign Customers section (styled to match FieldInput width/height layout)
        TwoColRow(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Customers',
                style: GoogleFonts.roboto(
                  color: const Color(0xFFB7A447),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              // Selected chips
              if (_loadingCustomers)
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
                )
              else ...[
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
                          border: Border.all(
                            color: const Color(0xFF3D3D3D),
                            width: 1,
                          ),
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
                              onTap: () => _removeSelectedCustomer(
                                c['customer_id'] as int,
                              ),
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
                Row(
                  children: [
                    Expanded(
                      child: (_availableCustomers().isEmpty)
                          ? Container(
                              height: 55,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _availableCustomers();
                                    }
                                    final search = textEditingValue.text
                                        .toLowerCase();
                                    return _availableCustomers().where(
                                      (customer) => customer['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(search),
                                    );
                                  },
                              onSelected: (Map<String, dynamic> selection) {
                                setState(() {
                                  _selectedAddCustomerId =
                                      selection['customer_id'].toString();
                                });
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onEditingComplete,
                                  ) {
                                    return Container(
                                      height: 38,
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
                                            vertical: 9,
                                          ),
                                          suffixIcon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Color(0xFFB7A447),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E1E),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                              final option = options.elementAt(
                                                index,
                                              );
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            index <
                                                                options.length -
                                                                    1
                                                            ? const Color(
                                                                0xFF3D3D3D,
                                                              )
                                                            : Colors
                                                                  .transparent,
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
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _availableCustomers().isEmpty
                          ? null
                          : _addSelectedCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7A447),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          right: const SizedBox(),
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
                  cityError = null;
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
                    nameError = 'Sales rep name is required';
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

                // Validate city
                if (city.isEmpty) {
                  setState(() {
                    cityError = 'City is required';
                  });
                  hasError = true;
                }

                if (hasError) return;

                try {
                  // Check if ID already exists
                  final existingSalesRep = await supabase
                      .from('sales_representative')
                      .select('sales_rep_id')
                      .eq('sales_rep_id', idVal!)
                      .maybeSingle();

                  if (existingSalesRep != null) {
                    setState(() {
                      idError = 'This ID already exists in database';
                    });
                    return;
                  }

                  final cityName = city;
                  final existing = await supabase
                      .from('sales_rep_city')
                      .select('sales_rep_city_id')
                      .eq('name', cityName)
                      .maybeSingle();
                  int cityId;
                  if (existing != null &&
                      existing['sales_rep_city_id'] != null) {
                    cityId = existing['sales_rep_city_id'] as int;
                  } else {
                    final insertedCity = await supabase
                        .from('sales_rep_city')
                        .insert({'name': cityName})
                        .select()
                        .single();
                    cityId = insertedCity['sales_rep_city_id'] as int;
                  }

                  // Create account FIRST (foreign key constraint requires it)
                  try {
                    await supabase.from('accounts').insert({
                      'user_id': idVal,
                      'password': '',
                      'type': 'Sales Rep',
                      'is_active': false,
                    });
                  } catch (e) {
                    // If account already exists, that's okay, continue
                    debugPrint('Account may already exist: $e');
                  }

                  final inserted = await supabase
                      .from('sales_representative')
                      .insert({
                        'sales_rep_id': idVal,
                        'name': name.text.trim(),
                        'email': email.text.trim(),
                        'mobile_number': mobile.text.trim(),
                        'telephone_number': tel.text.trim(),
                        'sales_rep_city': cityId,
                      })
                      .select()
                      .maybeSingle();

                  if (inserted == null) throw Exception('Insert failed');

                  // Update selected customers to point to this sales rep
                  for (final cust in _selectedCustomers) {
                    try {
                      await supabase
                          .from('customer')
                          .update({'sales_rep_id': idVal})
                          .eq('customer_id', cust['customer_id']);
                    } catch (_) {
                      // Continue even if single update fails
                    }
                  }

                  widget.onSubmit({'name': inserted['name'], 'city': cityName});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add sales rep: $e')),
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

void showSalesRepPopup(
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
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(ctx).size.width * 0.2, // ~60% width
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SalesRepFormPopup(cities: cities, onSubmit: onSubmit),
          ),
        ),
      );
    },
  );
}

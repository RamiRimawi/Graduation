import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';
import '../MobileAccounts/MobileAccounts_shared_popup_widgets.dart';

class AddCustomerAccountPopup extends StatefulWidget {
  final VoidCallback? onAccountCreated;
  const AddCustomerAccountPopup({super.key, this.onAccountCreated});

  @override
  State<AddCustomerAccountPopup> createState() =>
      _AddCustomerAccountPopupState();
}

class _AddCustomerAccountPopupState extends State<AddCustomerAccountPopup> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  int? _selectedCustomerId;

  String? nameError;
  String? passError;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      // Fetch customers that don't have an account yet
      final response = await supabase
          .from('customer')
          .select('customer_id, name')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading customers: $e')));
      }
    }
  }

  void _onCustomerSelected(int customerId, String customerName) {
    setState(() {
      _selectedCustomerId = customerId;
      nameCtrl.text = customerName;
      userCtrl.text = customerId.toString();
    });
  }

  Future<void> _submitAccount() async {
    // Clear previous errors
    setState(() {
      nameError = null;
      passError = null;
    });

    bool hasError = false;

    // Validate inputs
    if (_selectedCustomerId == null) {
      setState(() => nameError = 'Please select a customer');
      hasError = true;
    }

    if (passCtrl.text.trim().isEmpty) {
      setState(() => passError = 'Please enter a password');
      hasError = true;
    }

    if (hasError) return;

    try {
      // Check if account already exists
      final existing = await supabase
          .from('accounts')
          .select('user_id')
          .eq('user_id', _selectedCustomerId!)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This customer already has an account'),
            ),
          );
        }
        return;
      }

      // Insert new account into unified accounts table
      await supabase.from('accounts').insert({
        'user_id': _selectedCustomerId,
        'password': passCtrl.text.trim(),
        'type': 'Customer',
        'is_active': true,
        'last_action_by': 'Admin',
        'last_action_time': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAccountCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      insetPadding: const EdgeInsets.symmetric(horizontal: 390, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Customer Account',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Name',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFFB7A447),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF9D949),
                        ),
                      )
                    : _CustomerDropdown(
                        customers: _customers,
                        selectedCustomerId: _selectedCustomerId,
                        onSelected: (id, name) {
                          _onCustomerSelected(id, name);
                          setState(() => nameError = null);
                        },
                        hasError: nameError != null,
                      ),
                if (nameError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    nameError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            TwoColRow(
              left: FieldInput(
                controller: userCtrl,
                label: 'Account ID',
                hint: 'Auto-filled after selection',
              ),
              right: FieldInput(
                controller: passCtrl,
                label: 'Password',
                hint: 'Entre Password',
                errorText: passError,
                onChanged: () => setState(() => passError = null),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SubmitButton(
                  text: 'Submit',
                  icon: Icons.person_add_alt_1,
                  onTap: _submitAccount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final int? selectedCustomerId;
  final Function(int, String) onSelected;
  final bool hasError;

  const _CustomerDropdown({
    required this.customers,
    required this.selectedCustomerId,
    required this.onSelected,
    this.hasError = false,
  });

  @override
  State<_CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<_CustomerDropdown> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.hasError
              ? Colors.red
              : _isFocused
              ? const Color(0xFFB7A447)
              : const Color(0xFF3D3D3D),
          width: widget.hasError || _isFocused ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: widget.selectedCustomerId,
          hint: const Text(
            'Select Customer Name',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFB7A447)),
          dropdownColor: const Color(0xFF1E1E1E),
          focusNode: _focusNode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: widget.customers.map((customer) {
            return DropdownMenuItem<int>(
              value: customer['customer_id'] as int,
              child: Text(customer['name'] ?? 'Unknown'),
            );
          }).toList(),
          onChanged: (int? customerId) {
            if (customerId != null) {
              final customer = widget.customers.firstWhere(
                (c) => c['customer_id'] == customerId,
              );
              widget.onSelected(customerId, customer['name'] ?? '');
            }
          },
        ),
      ),
    );
  }
}

void showAddCustomerAccountPopup(
  BuildContext context, {
  VoidCallback? onAccountCreated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AddCustomerAccountPopup(onAccountCreated: onAccountCreated),
  );
}

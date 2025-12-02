import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';
import '../shared_popup_widgets.dart';

class AddSupplierAccountPopup extends StatefulWidget {
  final VoidCallback? onAccountCreated;
  const AddSupplierAccountPopup({super.key, this.onAccountCreated});

  @override
  State<AddSupplierAccountPopup> createState() =>
      _AddSupplierAccountPopupState();
}

class _AddSupplierAccountPopupState extends State<AddSupplierAccountPopup> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;
  int? _selectedSupplierId;

  String? nameError;
  String? passError;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      // Fetch suppliers that don't have an account yet
      final response = await supabase
          .from('supplier')
          .select('supplier_id, name')
          .order('name');

      setState(() {
        _suppliers = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading suppliers: $e')));
      }
    }
  }

  void _onSupplierSelected(int supplierId, String supplierName) {
    setState(() {
      _selectedSupplierId = supplierId;
      nameCtrl.text = supplierName;
      userCtrl.text = supplierId.toString();
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
    if (_selectedSupplierId == null) {
      setState(() => nameError = 'Please select a supplier');
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
          .from('user_account_supplier')
          .select('supplier_id')
          .eq('supplier_id', _selectedSupplierId!)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This supplier already has an account'),
            ),
          );
        }
        return;
      }

      // Insert new account
      await supabase.from('user_account_supplier').insert({
        'supplier_id': _selectedSupplierId,
        'password': passCtrl.text.trim(),
        'is_active': 'yes',
        'added_by': 'Admin', // You can replace this with actual logged-in user
        'added_time': DateTime.now().toIso8601String(),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 40),
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
                  'Add Supplier Account',
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
                  'Supplier Name',
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
                    : _SupplierDropdown(
                        suppliers: _suppliers,
                        selectedSupplierId: _selectedSupplierId,
                        onSelected: (id, name) {
                          _onSupplierSelected(id, name);
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
                hint: 'Entre Account Password',
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

class _SupplierDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers;
  final int? selectedSupplierId;
  final Function(int, String) onSelected;
  final bool hasError;

  const _SupplierDropdown({
    required this.suppliers,
    required this.selectedSupplierId,
    required this.onSelected,
    this.hasError = false,
  });

  @override
  State<_SupplierDropdown> createState() => _SupplierDropdownState();
}

class _SupplierDropdownState extends State<_SupplierDropdown> {
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
          value: widget.selectedSupplierId,
          hint: const Text(
            'Select Supplier Name',
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
          items: widget.suppliers.map((supplier) {
            return DropdownMenuItem<int>(
              value: supplier['supplier_id'] as int,
              child: Text(supplier['name'] ?? 'Unknown'),
            );
          }).toList(),
          onChanged: (int? supplierId) {
            if (supplierId != null) {
              final supplier = widget.suppliers.firstWhere(
                (c) => c['supplier_id'] == supplierId,
              );
              widget.onSelected(supplierId, supplier['name'] ?? '');
            }
          },
        ),
      ),
    );
  }
}

void showAddSupplierAccountPopup(
  BuildContext context, {
  VoidCallback? onAccountCreated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AddSupplierAccountPopup(onAccountCreated: onAccountCreated),
  );
}

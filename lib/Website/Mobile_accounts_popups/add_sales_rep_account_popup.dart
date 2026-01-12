import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../MobileAccounts/MobileAccounts_shared_popup_widgets.dart';

class AddSalesRepAccountPopup extends StatefulWidget {
  final VoidCallback? onAccountCreated;
  const AddSalesRepAccountPopup({super.key, this.onAccountCreated});

  @override
  State<AddSalesRepAccountPopup> createState() =>
      _AddSalesRepAccountPopupState();
}

class _AddSalesRepAccountPopupState extends State<AddSalesRepAccountPopup> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  List<Map<String, dynamic>> _salesReps = [];
  bool _loading = true;
  int? _selectedSalesRepId;

  String? nameError;
  String? passError;

  @override
  void initState() {
    super.initState();
    _loadSalesReps();
  }

  Future<void> _loadSalesReps() async {
    try {
      // Fetch all accounts with is_active = false and type = 'Sales Rep'
      final accountsResponse = await supabase
          .from('accounts')
          .select('user_id')
          .eq('type', 'Sales Rep')
          .eq('is_active', false);

      final inactiveUserIds = accountsResponse
          .map((account) => account['user_id'] as int)
          .toList();

      if (inactiveUserIds.isEmpty) {
        setState(() {
          _salesReps = [];
          _loading = false;
        });
        return;
      }

      // Fetch sales reps whose IDs are in the inactive accounts list
      final response = await supabase
          .from('sales_representative')
          .select('sales_rep_id, name')
          .inFilter('sales_rep_id', inactiveUserIds)
          .order('name');

      setState(() {
        _salesReps = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sales reps: $e')));
      }
    }
  }

  void _onSalesRepSelected(int salesRepId, String salesRepName) {
    setState(() {
      _selectedSalesRepId = salesRepId;
      nameCtrl.text = salesRepName;
      userCtrl.text = salesRepId.toString();
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
    if (_selectedSalesRepId == null) {
      setState(() => nameError = 'Please select a sales rep');
      hasError = true;
    }

    if (passCtrl.text.trim().isEmpty) {
      setState(() => passError = 'Please enter a password');
      hasError = true;
    }

    if (hasError) return;

    try {
      // Get current username from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? 'System';

      // Check if account already exists
      final existing = await supabase
          .from('accounts')
          .select('user_id, password')
          .eq('user_id', _selectedSalesRepId!)
          .maybeSingle();

      if (existing != null) {
        // Account exists, update it with password and activate it
        await supabase
            .from('accounts')
            .update({
              'password': passCtrl.text.trim(),
              'is_active': true,
              'last_action_by': currentUsername,
              'last_action_time': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _selectedSalesRepId!);
      } else {
        // Account doesn't exist, insert new one
        await supabase.from('accounts').insert({
          'user_id': _selectedSalesRepId,
          'password': passCtrl.text.trim(),
          'type': 'Sales Rep',
          'is_active': true,
          'last_action_by': currentUsername,
          'last_action_time': DateTime.now().toIso8601String(),
        });
      }

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
                  'Add Sales Rep Account',
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
                  'Sales Rep Name',
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
                    : _SalesRepDropdown(
                        salesReps: _salesReps,
                        selectedSalesRepId: _selectedSalesRepId,
                        onSelected: (id, name) {
                          _onSalesRepSelected(id, name);
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

class _SalesRepDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> salesReps;
  final int? selectedSalesRepId;
  final Function(int, String) onSelected;
  final bool hasError;

  const _SalesRepDropdown({
    required this.salesReps,
    required this.selectedSalesRepId,
    required this.onSelected,
    this.hasError = false,
  });

  @override
  State<_SalesRepDropdown> createState() => _SalesRepDropdownState();
}

class _SalesRepDropdownState extends State<_SalesRepDropdown> {
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
          value: widget.selectedSalesRepId,
          hint: const Text(
            'Select Sales Rep Name',
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
          items: widget.salesReps.map((salesRep) {
            final name = salesRep['name'] ?? 'Unknown';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            return DropdownMenuItem<int>(
              value: salesRep['sales_rep_id'] as int,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFB7A447),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: (int? salesRepId) {
            if (salesRepId != null) {
              final salesRep = widget.salesReps.firstWhere(
                (c) => c['sales_rep_id'] == salesRepId,
              );
              widget.onSelected(salesRepId, salesRep['name'] ?? '');
            }
          },
        ),
      ),
    );
  }
}

void showAddSalesRepAccountPopup(
  BuildContext context, {
  VoidCallback? onAccountCreated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AddSalesRepAccountPopup(onAccountCreated: onAccountCreated),
  );
}

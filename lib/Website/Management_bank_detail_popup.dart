import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';

class BankDetailPopup extends StatefulWidget {
  final int bankId;
  final int branchId;
  final VoidCallback? onUpdate;
  const BankDetailPopup({
    super.key,
    required this.bankId,
    required this.branchId,
    this.onUpdate,
  });

  @override
  State<BankDetailPopup> createState() => _BankDetailPopupState();
}

class _BankDetailPopupState extends State<BankDetailPopup> {
  Map<String, dynamic>? bank;
  Map<String, dynamic>? branch;
  bool loading = true, edit = false, saving = false;
  final bankCtrl = TextEditingController();
  final branchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    bankCtrl.dispose();
    branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final b = await supabase
          .from('banks')
          .select('bank_id, bank_name')
          .eq('bank_id', widget.bankId)
          .single();
      final br = await supabase
          .from('branches')
          .select('branch_id, address, bank_id')
          .eq('branch_id', widget.branchId)
          .single();
      if (!mounted) return;
      setState(() {
        bank = b;
        branch = br;
        bankCtrl.text = b['bank_name'] ?? '';
        branchCtrl.text = br['address'] ?? '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => saving = true);
      await supabase
          .from('banks')
          .update({'bank_name': bankCtrl.text.trim()})
          .eq('bank_id', widget.bankId);
      await supabase
          .from('branches')
          .update({'address': branchCtrl.text.trim()})
          .eq('branch_id', widget.branchId);
      await _load();
      if (mounted) {
        setState(() {
          edit = false;
          saving = false;
        });
        widget.onUpdate?.call();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bank updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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
              'Bank Details',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              children: [
                if (!edit)
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
                    onPressed: () => setState(() => edit = true),
                    icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
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
                    onPressed: saving ? null : _save,
                    icon: saving
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
                      saving ? 'Saving...' : 'Done',
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
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFB7A447)),
              ),
            ),
          )
        else ...[
          _detail(
            label: 'Bank ID',
            value: '${bank?['bank_id'] ?? '—'}',
            highlight: true,
          ),
          const SizedBox(height: 12),
          edit
              ? _edit(label: 'Bank Name', controller: bankCtrl)
              : _detail(label: 'Bank Name', value: bank?['bank_name'] ?? '—'),
          const SizedBox(height: 16),
          _detail(label: 'Branch ID', value: '${branch?['branch_id'] ?? '—'}'),
          const SizedBox(height: 12),
          edit
              ? _edit(label: 'Branch Name', controller: branchCtrl)
              : _detail(label: 'Branch Name', value: branch?['address'] ?? '—'),
        ],
      ],
    );
  }

  Widget _detail({
    required String label,
    required String value,
    bool highlight = false,
  }) {
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
              color: highlight ? Colors.amberAccent : Colors.white,
              fontSize: 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _edit({
    required String label,
    required TextEditingController controller,
  }) {
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

void showBankDetailPopup(
  BuildContext context, {
  required int bankId,
  required int branchId,
  VoidCallback? onUpdate,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 160, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BankDetailPopup(
            bankId: bankId,
            branchId: branchId,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

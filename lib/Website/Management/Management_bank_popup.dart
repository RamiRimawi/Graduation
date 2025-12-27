import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';

class BankFormPopup extends StatefulWidget {
  final void Function(bool) onSubmit;
  const BankFormPopup({super.key, required this.onSubmit});

  @override
  State<BankFormPopup> createState() => _BankFormPopupState();
}

class _BankFormPopupState extends State<BankFormPopup> {
  final _bankCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _saving = false;
  String? _bankErr, _branchErr;

  @override
  void dispose() {
    _bankCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bank = _bankCtrl.text.trim();
    final branch = _branchCtrl.text.trim();
    setState(() {
      _bankErr = bank.isEmpty ? 'Bank name is required' : null;
      _branchErr = branch.isEmpty ? 'Branch name is required' : null;
    });
    if (_bankErr != null || _branchErr != null) return;

    try {
      setState(() => _saving = true);
      final insertedBank = await supabase
          .from('banks')
          .insert({'bank_name': bank})
          .select()
          .maybeSingle();
      if (insertedBank == null) throw Exception('Failed inserting bank');
      final bankId = insertedBank['bank_id'] as int;

      final insertedBranch = await supabase
          .from('branches')
          .insert({'bank_id': bankId, 'address': branch})
          .select()
          .maybeSingle();
      if (insertedBranch == null) throw Exception('Failed inserting branch');

      if (mounted) widget.onSubmit(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add bank: $e')));
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
              'Add Bank',
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
        const SizedBox(height: 12),
        _field(label: 'Bank Name', ctrl: _bankCtrl, error: _bankErr),
        const SizedBox(height: 12),
        _field(label: 'Branch Name', ctrl: _branchCtrl, error: _branchErr),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50B2E7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : const Icon(Icons.north_east_rounded, color: Colors.black),
            label: Text(
              _saving ? 'Saving...' : 'Submit',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    String? error,
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
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? Colors.red : const Color(0xFF3D3D3D),
              width: error != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
      ],
    );
  }
}

void showBankPopup(BuildContext context, void Function(bool) onSubmit) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BankFormPopup(onSubmit: onSubmit),
        ),
      ),
    ),
  );
}

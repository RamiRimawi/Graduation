import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';
import '../MobileAccounts/MobileAccounts_shared_popup_widgets.dart';

class AddDeliveryDriverAccountPopup extends StatefulWidget {
  final VoidCallback? onAccountCreated;
  const AddDeliveryDriverAccountPopup({super.key, this.onAccountCreated});

  @override
  State<AddDeliveryDriverAccountPopup> createState() =>
      _AddDeliveryDriverAccountPopupState();
}

class _AddDeliveryDriverAccountPopupState
    extends State<AddDeliveryDriverAccountPopup> {
  final nameCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? idError;
  String? nameError;
  String? mobileError;
  String? telError;
  String? passError;

  @override
  void initState() {
    super.initState();
    // Auto-fill Account ID when Delivery Driver ID changes
    idCtrl.addListener(() {
      userCtrl.text = idCtrl.text;
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    idCtrl.dispose();
    mobileCtrl.dispose();
    telCtrl.dispose();
    addressCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAccount() async {
    // Clear previous errors
    setState(() {
      idError = null;
      nameError = null;
      mobileError = null;
      telError = null;
      passError = null;
    });

    bool hasError = false;

    // Validate inputs
    if (idCtrl.text.trim().isEmpty || idCtrl.text.trim().length != 9) {
      setState(
        () => idError = 'Please enter a valid 9-digit Delivery Driver ID',
      );
      hasError = true;
    }

    if (nameCtrl.text.trim().isEmpty) {
      setState(() => nameError = 'Please enter delivery driver name');
      hasError = true;
    }

    if (mobileCtrl.text.trim().isEmpty || mobileCtrl.text.trim().length != 10) {
      setState(
        () => mobileError = 'Please enter a valid 10-digit mobile number',
      );
      hasError = true;
    }

    if (telCtrl.text.trim().isNotEmpty &&
        (telCtrl.text.trim().length < 9 || telCtrl.text.trim().length > 10)) {
      setState(() => telError = 'Telephone number must be 9 or 10 digits');
      hasError = true;
    }

    if (passCtrl.text.trim().isEmpty) {
      setState(() => passError = 'Please enter a password');
      hasError = true;
    }

    if (hasError) return;

    try {
      final driverId = int.parse(idCtrl.text.trim());

      // Check if delivery driver ID already exists
      final existingDriver = await supabase
          .from('delivery_driver')
          .select('delivery_driver_id')
          .eq('delivery_driver_id', driverId)
          .maybeSingle();

      if (existingDriver != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Delivery Driver ID already exists'),
            ),
          );
        }
        return;
      }

      // Insert delivery driver
      await supabase.from('delivery_driver').insert({
        'delivery_driver_id': driverId,
        'name': nameCtrl.text.trim(),
        'mobile_number': mobileCtrl.text.trim(),
        'telephone_number': telCtrl.text.trim().isNotEmpty
            ? telCtrl.text.trim()
            : null,
        'address': addressCtrl.text.trim().isNotEmpty
            ? addressCtrl.text.trim()
            : null,
        'last_action_by': 'Admin',
        'last_action_time': DateTime.now().toIso8601String(),
      });

      // Insert user account
      await supabase.from('user_account_delivery_driver').insert({
        'delivery_driver_id': driverId,
        'password': passCtrl.text.trim(),
        'is_active': 'yes',
        'added_by': 'Admin',
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
                  'Add Delivery Driver Account',
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
                controller: idCtrl,
                label: 'Delivery Driver ID',
                hint: 'Entre Driver ID',
                type: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                maxLength: 9,
                errorText: idError,
                onChanged: () => setState(() => idError = null),
              ),
              right: FieldInput(
                controller: nameCtrl,
                label: 'Delivery Driver Name',
                hint: 'Entre Full Name',
                errorText: nameError,
                onChanged: () => setState(() => nameError = null),
              ),
            ),
            const SizedBox(height: 18),
            TwoColRow(
              left: FieldInput(
                controller: mobileCtrl,
                label: 'Mobile Number',
                hint: 'Entre Mobile Number',
                type: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
                errorText: mobileError,
                onChanged: () => setState(() => mobileError = null),
              ),
              right: FieldInput(
                controller: telCtrl,
                label: 'Telephone Number',
                hint: 'Entre Telephone Number',
                type: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
                errorText: telError,
                onChanged: () => setState(() => telError = null),
              ),
            ),
            const SizedBox(height: 18),
            TwoColRow(
              left: FieldInput(
                controller: addressCtrl,
                label: 'Address',
                hint: 'Entre Address',
              ),
              right: const SizedBox(),
            ),
            const SizedBox(height: 18),
            TwoColRow(
              left: FieldInput(
                controller: userCtrl,
                label: 'Account ID',
                hint: 'Auto-filled',
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

void showAddDeliveryDriverAccountPopup(
  BuildContext context, {
  VoidCallback? onAccountCreated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) =>
        AddDeliveryDriverAccountPopup(onAccountCreated: onAccountCreated),
  );
}

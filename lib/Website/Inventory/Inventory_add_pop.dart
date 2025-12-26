import 'package:flutter/material.dart';
import '../../supabase_config.dart';

class AddInventoryPopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onInventoryAdded;
  const AddInventoryPopup({
    super.key,
    required this.onClose,
    this.onInventoryAdded,
  });

  @override
  State<AddInventoryPopup> createState() => _AddInventoryPopupState();
}

class _AddInventoryPopupState extends State<AddInventoryPopup> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryLocationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _inventoryLocationController.dispose();
    super.dispose();
  }

  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final location = _inventoryLocationController.text.trim();

      if (location.isEmpty) {
        _showError('Please enter inventory location');
        setState(() => _isSaving = false);
        return;
      }

      // Insert inventory into database (inventory_id is auto-generated)
      await supabase.from('inventory').insert({
        'inventory_location': location,
      });

      if (mounted) {
        _showSuccess('Inventory added successfully');
        widget.onInventoryAdded?.call();
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error adding inventory: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 480,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 480,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Add Inventory',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFE14D),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 360,
                              child: FormFieldWrapper(
                                label: 'Inventory Location',
                                child: _textField(
                                  controller: _inventoryLocationController,
                                  hint: 'Enter warehouse location name',
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: 280,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveInventory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFE14D),
                                  disabledBackgroundColor: const Color(0xFFFFE14D).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            color: Colors.black87,
                                            size: 26,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🟡 Text Field Style
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? type,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }
}

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  const FormFieldWrapper({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFE14D),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

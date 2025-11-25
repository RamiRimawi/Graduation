import 'package:flutter/material.dart';

class AddProductPopup extends StatefulWidget {
  final VoidCallback onClose;
  const AddProductPopup({super.key, required this.onClose});

  @override
  State<AddProductPopup> createState() => _AddProductPopupState();
}

class _AddProductPopupState extends State<AddProductPopup> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _minProfitController = TextEditingController();

  String? _selectedBrand;
  String? _selectedCategory;
  String? _selectedUnit;

  @override
  void dispose() {
    _productNameController.dispose();
    _wholesalePriceController.dispose();
    _sellingPriceController.dispose();
    _minProfitController.dispose();
    super.dispose();
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
              width: 850,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Product',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFE14D),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              children: [
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Product Name',
                                    child: _textField(
                                      controller: _productNameController,
                                      hint: 'Product Name',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Brand Name',
                                    child: _dropdownField(
                                      hint: 'Brand Name',
                                      value: _selectedBrand,
                                      items: ['GROHE', 'Royal', 'Other'],
                                      onChanged: (v) =>
                                          setState(() => _selectedBrand = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Category',
                                    child: _dropdownField(
                                      hint: 'Category Name',
                                      value: _selectedCategory,
                                      items: [
                                        'shower',
                                        'Toilets',
                                        'Extensions',
                                        'Other',
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _selectedCategory = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Wholesale Price',
                                    child: _textField(
                                      controller: _wholesalePriceController,
                                      hint: 'Entre Value',
                                      type: TextInputType.number,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Selling  Price',
                                    child: _textField(
                                      controller: _sellingPriceController,
                                      hint: 'Entre Value',
                                      type: TextInputType.number,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Minimum Profit %',
                                    child: _textField(
                                      controller: _minProfitController,
                                      hint: 'Entre Percent',
                                      type: TextInputType.number,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 230,
                                  child: FormFieldWrapper(
                                    label: 'Unit',
                                    child: _dropdownField(
                                      hint: 'cm,pcs,kg..etc',
                                      value: _selectedUnit,
                                      items: ['cm', 'pcs', 'kg', 'etc'],
                                      onChanged: (v) =>
                                          setState(() => _selectedUnit = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 280,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      widget.onClose();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFE14D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_box_rounded,
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
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 1.8),
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

  // 🟡 Dropdown Field Style
  Widget _dropdownField({
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: const Color(0xFF2D2D2D),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFE14D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFE14D), width: 1.8),
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
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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

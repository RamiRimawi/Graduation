import 'package:flutter/material.dart';
import 'sidebar.dart';

class AddIncomingCashPage extends StatefulWidget {
  const AddIncomingCashPage({super.key});

  @override
  State<AddIncomingCashPage> createState() => _AddIncomingCashPageState();
}

class _AddIncomingCashPageState extends State<AddIncomingCashPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomer;

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment submitted')));
    }
  }

  Text _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Row(
        children: [
          const Sidebar(activeIndex: 4),
          Expanded(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================== HEADER ===================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 40, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // زر الرجوع
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.white,
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        const SizedBox(width: 30), // المسافة بين السهم والعنوان
                        // العنوان مباشرة بجانب زر الرجوع
                        const Text(
                          'Add Incoming Payment',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const Spacer(), // يدفع الإشعارات لأقصى اليمين
                        // زر الإشعارات
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= BODY CONTENT =================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(99, 45, 90, 32),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // =================== Customer Name ===================
                                _label("Customer Name"),
                                const SizedBox(height: 10),

                                DropdownButtonFormField<String>(
                                  initialValue: selectedCustomer,
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.blue,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "Mohammad",
                                      child: Text("Mohammad"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Ayman",
                                      child: Text("Ayman"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Rami",
                                      child: Text("Rami"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => selectedCustomer = value);
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please select customer";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // =================== Amount ===================
                                _label("Amount"),
                                const SizedBox(height: 10),

                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(
                                        Icons.attach_money,
                                        color: AppColors.white,
                                        size: 22,
                                      ),
                                    ),
                                    suffixIconConstraints: BoxConstraints(
                                      maxHeight: 40,
                                      maxWidth: 40,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.blue,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter amount";
                                    }
                                    if (double.tryParse(value) == null) {
                                      return "Invalid number";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // =================== Description ===================
                                _label("Description"),
                                const SizedBox(height: 10),

                                TextFormField(
                                  controller: _descriptionController,
                                  minLines: 7,
                                  maxLines: 10,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      14,
                                      14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColors.blue,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // =================== Submit Button ===================
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.blue,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.attach_money, size: 20),
                                          SizedBox(width: 12),
                                          Text(
                                            'Submit',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= COLORS =================
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const dark = Color(0xFF202020);
  static const black = Color(0xFF000000);
  static const cardBorder = Color(0xFF3D3D3D);
}

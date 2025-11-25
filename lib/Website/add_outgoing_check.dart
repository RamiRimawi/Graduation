import 'package:flutter/material.dart';
import 'sidebar.dart';

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

class AddOutgoingCheckPage extends StatefulWidget {
  const AddOutgoingCheckPage({super.key});

  @override
  State<AddOutgoingCheckPage> createState() => _AddOutgoingCheckPageState();
}

class _AddOutgoingCheckPageState extends State<AddOutgoingCheckPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedSupplier;
  String? selectedBank;
  String? selectedBranch;
  late TextEditingController _checkRateController;
  late TextEditingController _descriptionController;
  DateTime? selectedDate;
  String? selectedCheckImage;

  @override
  void initState() {
    super.initState();
    _checkRateController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _checkRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: ربط إرسال الشيك مع الداتابيس / API
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Outgoing check submitted')));
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
                        const SizedBox(width: 30),
                        const Text(
                          'Add Outgoing Payment',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
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
                      padding: const EdgeInsets.fromLTRB(60, 45, 60, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // ================= LEFT FORM + RIGHT DESCRIPTION =================
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // -------- LEFT: كل الحقول + صورة الشيك --------
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ========== Supplier Name ==========
                                      _label("Supplier Name"),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: selectedSupplier,
                                        dropdownColor: AppColors.card,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 15,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.card,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.cardBorder,
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.cardBorder,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.blue,
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: "Supplier 1",
                                            child: Text("Supplier 1"),
                                          ),
                                          DropdownMenuItem(
                                            value: "Supplier 2",
                                            child: Text("Supplier 2"),
                                          ),
                                          DropdownMenuItem(
                                            value: "Supplier 3",
                                            child: Text("Supplier 3"),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(
                                            () => selectedSupplier = value,
                                          );
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return "Please select supplier";
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 24),

                                      // ========== Bank Name & Branch ==========
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _label("Bank Name"),
                                                const SizedBox(height: 10),
                                                DropdownButtonFormField<String>(
                                                  value: selectedBank,
                                                  dropdownColor: AppColors.card,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 15,
                                                  ),
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: AppColors.card,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .cardBorder,
                                                            width: 1,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .cardBorder,
                                                                width: 1,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .blue,
                                                                width: 1.8,
                                                              ),
                                                        ),
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: "Bank 1",
                                                      child: Text("Bank 1"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "Bank 2",
                                                      child: Text("Bank 2"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "Bank 3",
                                                      child: Text("Bank 3"),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(
                                                      () =>
                                                          selectedBank = value,
                                                    );
                                                  },
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return "Please select bank";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _label("Branch"),
                                                const SizedBox(height: 10),
                                                DropdownButtonFormField<String>(
                                                  value: selectedBranch,
                                                  dropdownColor: AppColors.card,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 15,
                                                  ),
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: AppColors.card,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .cardBorder,
                                                            width: 1,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .cardBorder,
                                                                width: 1,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .blue,
                                                                width: 1.8,
                                                              ),
                                                        ),
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: "Branch 1",
                                                      child: Text("Branch 1"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "Branch 2",
                                                      child: Text("Branch 2"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "Branch 3",
                                                      child: Text("Branch 3"),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(
                                                      () => selectedBranch =
                                                          value,
                                                    );
                                                  },
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return "Please select branch";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      // ========== Check Rate & Exchange Date ==========
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _label("Check Rate"),
                                                const SizedBox(height: 10),
                                                TextFormField(
                                                  controller:
                                                      _checkRateController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                  ),
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: AppColors.card,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .cardBorder,
                                                            width: 1,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .cardBorder,
                                                                width: 1,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .blue,
                                                                width: 1.8,
                                                              ),
                                                        ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Please enter check rate";
                                                    }
                                                    if (double.tryParse(
                                                          value,
                                                        ) ==
                                                        null) {
                                                      return "Invalid number";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _label("Exchange Date"),
                                                const SizedBox(height: 10),
                                                TextFormField(
                                                  readOnly: true,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                  ),
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: AppColors.card,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12,
                                                        ),
                                                    suffixIcon: const Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 12,
                                                      ),
                                                      child: Icon(
                                                        Icons.calendar_today,
                                                        color: AppColors.white,
                                                        size: 22,
                                                      ),
                                                    ),
                                                    suffixIconConstraints:
                                                        const BoxConstraints(
                                                          maxHeight: 40,
                                                          maxWidth: 40,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .cardBorder,
                                                            width: 1,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .cardBorder,
                                                                width: 1,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppColors
                                                                    .blue,
                                                                width: 1.8,
                                                              ),
                                                        ),
                                                  ),
                                                  controller: TextEditingController(
                                                    text: selectedDate != null
                                                        ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                                                        : "",
                                                  ),
                                                  onTap: () async {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    final picked =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              DateTime.now(),
                                                          firstDate: DateTime(
                                                            2020,
                                                          ),
                                                          lastDate: DateTime(
                                                            2030,
                                                          ),
                                                        );
                                                    if (picked != null) {
                                                      setState(() {
                                                        selectedDate = picked;
                                                      });
                                                    }
                                                  },
                                                  validator: (value) {
                                                    if (selectedDate == null) {
                                                      return "Please select date";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // ========== Check Image ==========
                                      _label("Check Image"),
                                      const SizedBox(height: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.blue,
                                              foregroundColor: AppColors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 28,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Upload Image',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // ---  الصورة بالحجم الطبيعي بدون border أو تمدد ---
                                          Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.asset(
                                                'assets/icon/bank.png',
                                                fit: BoxFit.contain,
                                                width:
                                                    null, // مهم جداً (عشان ما يتمدد)
                                                height: null, // مهم جداً
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(top: 25),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _label("Description"),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _descriptionController,
                                          minLines: 18,
                                          maxLines: 24,
                                          style: const TextStyle(
                                            color: AppColors.white,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.cardAlt,
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                                  14,
                                                  14,
                                                  14,
                                                  14,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: AppColors.cardBorder,
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: AppColors.cardBorder,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: AppColors.blue,
                                                width: 1.8,
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

                            const SizedBox(height: 2),

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
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.check, size: 24),
                                      SizedBox(width: 20),
                                      Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

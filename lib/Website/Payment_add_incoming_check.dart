import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sidebar.dart';

Future<int?> getAccountantId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('accountant_id');
  if (id != null) return id;
  // If not found in prefs, get from DB where is_active = 'yes'
  final response = await Supabase.instance.client
      .from('user_account_accountant')
      .select('accountant_id')
      .eq('is_active', 'yes')
      .maybeSingle();
  return response != null ? response['accountant_id'] as int? : null;
}

Future<String?> getAccountantName(int accountantId) async {
  final response = await Supabase.instance.client
      .from('accountant')
      .select('name')
      .eq('accountant_id', accountantId)
      .maybeSingle();
  return response != null ? response['name'] as String? : null;
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

class AddIncomingCheckPage extends StatefulWidget {
  const AddIncomingCheckPage({super.key});

  @override
  State<AddIncomingCheckPage> createState() => _AddIncomingCheckPageState();
}

class _AddIncomingCheckPageState extends State<AddIncomingCheckPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomer;
  String? selectedBank;
  String? selectedBranch;
  late TextEditingController _checkRateController;
  late TextEditingController _descriptionController;
  late TextEditingController _customerSearchController;
  DateTime? selectedDate;
  String? selectedCheckImage;

  List<Map<String, dynamic>> customers = [];
  bool isLoadingCustomers = true;
  List<Map<String, dynamic>> filteredCustomers = [];

  OverlayEntry? _customerOverlayEntry;
  final LayerLink _customerLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _checkRateController = TextEditingController();
    _descriptionController = TextEditingController();
    _customerSearchController = TextEditingController();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _checkRateController.dispose();
    _descriptionController.dispose();
    _customerSearchController.dispose();
    _hideCustomerOverlay();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    try {
      setState(() => isLoadingCustomers = true);

      final response = await Supabase.instance.client
          .from('customer')
          .select('customer_id, name')
          .order('name', ascending: true);

      setState(() {
        customers = List<Map<String, dynamic>>.from(response);
        filteredCustomers = customers;
        isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() => isLoadingCustomers = false);
      // Handle error - could show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load customers: $e')));
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers
            .where(
              (customer) => customer['name']
                  .toString()
                  .toLowerCase()
                  .startsWith(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _showCustomerOverlay() {
    _hideCustomerOverlay(); // Remove existing overlay first to force rebuild

    _customerOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent background to detect taps outside dropdown
          GestureDetector(
            onTap: _hideCustomerOverlay,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          // The actual dropdown
          Positioned(
            width: 720, // Match the ConstrainedBox width
            child: CompositedTransformFollower(
              link: _customerLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60), // Position below the text field
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedCustomer = customer['customer_id']
                                .toString();
                            _customerSearchController.text = customer['name'];
                          });
                          _hideCustomerOverlay();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Text(
                            customer['name'] ?? 'Unknown',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_customerOverlayEntry!);
  }

  void _hideCustomerOverlay() {
    _customerOverlayEntry?.remove();
    _customerOverlayEntry = null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: ربط إرسال الشيك مع الداتابيس / API
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incoming check submitted')));
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
                          'Add Incoming Payment',
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
                                      // ========== Customer Name ==========
                                      _label("Customer Name"),
                                      const SizedBox(height: 10),

                                      StatefulBuilder(
                                        builder: (context, setState) {
                                          return CompositedTransformTarget(
                                            link: _customerLayerLink,
                                            child: TextFormField(
                                              controller:
                                                  _customerSearchController,
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 15,
                                              ),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: isLoadingCustomers
                                                    ? AppColors.cardAlt
                                                    : AppColors.card,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: const BorderSide(
                                                    color: AppColors.cardBorder,
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
                                                            color:
                                                                AppColors.blue,
                                                            width: 1.8,
                                                          ),
                                                    ),
                                                hintText: isLoadingCustomers
                                                    ? 'Loading customers...'
                                                    : 'Search customers...',
                                                hintStyle: TextStyle(
                                                  color: AppColors.white
                                                      .withOpacity(0.6),
                                                ),
                                                suffixIcon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                _filterCustomers(value);
                                                if (value.isEmpty) {
                                                  _hideCustomerOverlay();
                                                } else {
                                                  _showCustomerOverlay();
                                                }
                                              },
                                              onTap: () {
                                                if (_customerSearchController
                                                    .text
                                                    .isEmpty) {
                                                  // Show all customers when field is empty and tapped
                                                  setState(() {
                                                    filteredCustomers =
                                                        customers;
                                                  });
                                                  _showCustomerOverlay();
                                                } else {
                                                  _filterCustomers(
                                                    _customerSearchController
                                                        .text,
                                                  );
                                                  _showCustomerOverlay();
                                                }
                                              },
                                              validator: (value) {
                                                if (selectedCustomer == null ||
                                                    selectedCustomer!.isEmpty) {
                                                  return "Please select customer";
                                                }
                                                return null;
                                              },
                                            ),
                                          );
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
                                                  initialValue: selectedBank,
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
                                                  initialValue: selectedBranch,
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
                                                'assets/icons/bank.png',
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

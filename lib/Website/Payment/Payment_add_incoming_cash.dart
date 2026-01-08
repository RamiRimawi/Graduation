import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sidebar.dart';

Future<int?> getAccountantId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('accountant_id');
  if (id != null) return id;
  // If not found in prefs, get from DB where is_active = true and type = 'Accountant'
  final response = await Supabase.instance.client
      .from('accounts')
      .select('user_id')
      .eq('is_active', true)
      .eq('type', 'Accountant')
      .maybeSingle();
  return response != null ? response['user_id'] as int? : null;
}

Future<String?> getAccountantName(int accountantId) async {
  final response = await Supabase.instance.client
      .from('accountant')
      .select('name')
      .eq('accountant_id', accountantId)
      .maybeSingle();
  return response != null ? response['name'] as String? : null;
}

class AddIncomingCashPage extends StatefulWidget {
  const AddIncomingCashPage({super.key});

  @override
  State<AddIncomingCashPage> createState() => _AddIncomingCashPageState();
}

class _AddIncomingCashPageState extends State<AddIncomingCashPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomer;
  DateTime? paymentDateTime;

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _customerSearchController;

  List<Map<String, dynamic>> customers = [];
  bool isLoadingCustomers = true;
  List<Map<String, dynamic>> filteredCustomers = [];

  bool _isSubmitting = false; // Add loading state for submit button

  OverlayEntry? _customerOverlayEntry;
  final LayerLink _customerLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _customerSearchController = TextEditingController();
    _fetchCustomers();
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
                            paymentDateTime = DateTime.now();
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerSearchController.dispose();
    _hideCustomerOverlay();
    super.dispose();
  }

  Future<void> _submitIncomingPayment() async {
    final amount = double.parse(_amountController.text);

    // Get accountant name for last_action_by
    final accountantId = await getAccountantId();
    final accountantName = accountantId != null
        ? await getAccountantName(accountantId)
        : 'System';

    // 1. Get current balance_debit
    final customerResponse = await Supabase.instance.client
        .from('customer')
        .select('balance_debit')
        .eq('customer_id', selectedCustomer!)
        .single();

    final currentBalance = customerResponse['balance_debit'] as double;

    // 2. Insert payment record into incoming_payment table
    await Supabase.instance.client.from('incoming_payment').insert({
      'customer_id': selectedCustomer!,
      'amount': amount,
      'date_time': paymentDateTime?.toIso8601String(),
      'description': _descriptionController.text,
      'last_action_by': accountantName,
      'last_action_time': DateTime.now().toIso8601String(),
    });

    // 3. Update customer's balance_debit (reduce amount owed by customer)
    await Supabase.instance.client
        .from('customer')
        .update({
          'balance_debit': currentBalance - amount,
          'last_action_time': DateTime.now().toIso8601String(),
        })
        .eq('customer_id', selectedCustomer!);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      final shouldProceed = await _showPaymentConfirmationDialog();
      if (!shouldProceed) return;

      setState(() => _isSubmitting = true);

      try {
        await _submitIncomingPayment();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incoming payment submitted successfully!'),
          ),
        );

        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit payment: $error')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _showPaymentConfirmationDialog() async {
    final customerName = customers.firstWhere(
      (customer) => customer['customer_id'].toString() == selectedCustomer,
      orElse: () => {'name': 'Unknown'},
    )['name'];

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Confirm Payment',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              content: Container(
                width: 400,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Customer:', customerName ?? 'Unknown'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Amount:', '\$${_amountController.text}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Date:',
                      paymentDateTime != null
                          ? '${paymentDateTime!.day}/${paymentDateTime!.month}/${paymentDateTime!.year}'
                          : 'Not set',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Time:',
                      paymentDateTime != null
                          ? '${paymentDateTime!.hour.toString().padLeft(2, '0')}:${paymentDateTime!.minute.toString().padLeft(2, '0')}:${paymentDateTime!.second.toString().padLeft(2, '0')}'
                          : 'Not set',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Description:',
                      _descriptionController.text.isEmpty
                          ? 'No description'
                          : _descriptionController.text,
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
            );
          },
        ) ??
        false;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
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
                      padding: const EdgeInsets.fromLTRB(60, 45, 60, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // ================= LEFT FORM + RIGHT DESCRIPTION =================
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // -------- LEFT: كل الحقول --------
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // =================== Customer Name ===================
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

                                      const SizedBox(height: 20),

                                      // =================== Payment Date & Time ===================
                                      _label("Payment Date & Time"),
                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          // Date Field
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.card,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppColors.cardBorder,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    color: AppColors.blue,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      paymentDateTime != null
                                                          ? '${paymentDateTime!.day}/${paymentDateTime!.month}/${paymentDateTime!.year}'
                                                          : 'Auto-filled on customer selection',
                                                      style: TextStyle(
                                                        color:
                                                            paymentDateTime !=
                                                                null
                                                            ? AppColors.white
                                                            : AppColors.white
                                                                  .withOpacity(
                                                                    0.6,
                                                                  ),
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Time Field
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                left: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.card,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppColors.cardBorder,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: AppColors.blue,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      paymentDateTime != null
                                                          ? '${paymentDateTime!.hour.toString().padLeft(2, '0')}:${paymentDateTime!.minute.toString().padLeft(2, '0')}:${paymentDateTime!.second.toString().padLeft(2, '0')}'
                                                          : 'Auto-filled on customer selection',
                                                      style: TextStyle(
                                                        color:
                                                            paymentDateTime !=
                                                                null
                                                            ? AppColors.white
                                                            : AppColors.white
                                                                  .withOpacity(
                                                                    0.6,
                                                                  ),
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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

                            const SizedBox(height: 30),

                            // =================== Submit Button ===================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSubmitting
                                        ? AppColors.cardBorder
                                        : AppColors.blue,
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
                                    children: [
                                      if (_isSubmitting)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.white,
                                                ),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.check, size: 24),
                                      const SizedBox(width: 20),
                                      Text(
                                        _isSubmitting
                                            ? 'Submitting...'
                                            : 'Submit',
                                        style: const TextStyle(
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

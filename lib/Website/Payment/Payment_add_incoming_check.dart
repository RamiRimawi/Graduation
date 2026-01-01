import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../sidebar.dart';

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
  late TextEditingController _dateController;
  DateTime? selectedDate;
  String? selectedCheckImage;
  Uint8List? _checkImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  List<Map<String, dynamic>> customers = [];
  bool isLoadingCustomers = true;
  List<Map<String, dynamic>> filteredCustomers = [];

  List<Map<String, dynamic>> banks = [];
  bool isLoadingBanks = true;
  List<Map<String, dynamic>> branches = [];
  bool isLoadingBranches = false;

  OverlayEntry? _customerOverlayEntry;
  final LayerLink _customerLayerLink = LayerLink();

  // Date picker overlay
  OverlayEntry? _dateOverlayEntry;
  final LayerLink _dateLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _checkRateController = TextEditingController();
    _descriptionController = TextEditingController();
    _customerSearchController = TextEditingController();
    _dateController = TextEditingController();
    _fetchCustomers();
    _fetchBanks();
  }

  @override
  void dispose() {
    _checkRateController.dispose();
    _descriptionController.dispose();
    _customerSearchController.dispose();
    _dateController.dispose();
    _hideCustomerOverlay();
    _hideDateOverlay();
    super.dispose();
  }

  void _showDateOverlay() {
    _hideDateOverlay();
    _dateOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideDateOverlay,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            child: CompositedTransformFollower(
              link: _dateLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 330),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: CalendarDatePicker2WithActionButtons(
                    value: selectedDate != null ? [selectedDate] : const [],
                    config: CalendarDatePicker2WithActionButtonsConfig(
                      calendarType: CalendarDatePicker2Type.single,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      selectedDayHighlightColor: AppColors.blue,
                      controlsTextStyle: const TextStyle(
                        color: AppColors.white,
                      ),
                      dayTextStyle: const TextStyle(color: AppColors.white),
                      selectedDayTextStyle: const TextStyle(
                        color: AppColors.black,
                      ),
                      cancelButtonTextStyle: const TextStyle(
                        color: AppColors.white,
                      ),
                      okButtonTextStyle: const TextStyle(
                        color: AppColors.white,
                      ),
                    ),
                    onValueChanged: (dates) {
                      if (dates.isNotEmpty && dates.first != null) {
                        final d = dates.first!;
                        setState(() {
                          selectedDate = d;
                          _dateController.text =
                              "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
                        });
                      }
                    },
                    onCancelTapped: _hideDateOverlay,
                    onOkTapped: _hideDateOverlay,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_dateOverlayEntry!);
  }

  void _hideDateOverlay() {
    _dateOverlayEntry?.remove();
    _dateOverlayEntry = null;
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

  Future<void> _fetchBanks() async {
    try {
      setState(() => isLoadingBanks = true);

      final response = await Supabase.instance.client
          .from('banks')
          .select('bank_id, bank_name')
          .order('bank_name', ascending: true);

      setState(() {
        banks = List<Map<String, dynamic>>.from(response);
        isLoadingBanks = false;
      });
    } catch (e) {
      setState(() => isLoadingBanks = false);
      // Handle error - could show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load banks: $e')));
      }
    }
  }

  Future<void> _fetchBranches(String bankId) async {
    try {
      setState(() => isLoadingBranches = true);

      final response = await Supabase.instance.client
          .from('branches')
          .select('branch_id, address')
          .eq('bank_id', int.parse(bankId))
          .order('address', ascending: true);

      setState(() {
        branches = List<Map<String, dynamic>>.from(response);
        isLoadingBranches = false;
      });
    } catch (e) {
      setState(() => isLoadingBranches = false);
      // Handle error - could show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load branches: $e')));
      }
    }
  }

  Future<void> _pickCheckImage() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [WebUiSettings(context: context)],
      );

      if (croppedFile == null) return;

      final bytes = await croppedFile.readAsBytes();
      setState(() {
        _checkImageBytes = bytes;
        selectedCheckImage = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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

  Future<String> _uploadCheckImage() async {
    final fileName = 'incoming_${DateTime.now().millisecondsSinceEpoch}.png';
    final storagePath = 'checks/$fileName';
    final storage = Supabase.instance.client.storage.from('images');
    await storage.uploadBinary(
      storagePath,
      _checkImageBytes!,
      fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
    );
    return storage.getPublicUrl(storagePath);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload check image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final accountantId = await getAccountantId();
      final accountantName = accountantId != null
          ? await getAccountantName(accountantId)
          : null;

      final imageUrl = await _uploadCheckImage();

      await Supabase.instance.client.from('customer_checks').insert({
        'customer_id': int.parse(selectedCustomer!),
        'bank_id': int.parse(selectedBank!),
        'bank_branch': int.parse(selectedBranch!),
        'check_image': imageUrl,
        'exchange_rate': double.parse(_checkRateController.text),
        'exchange_date': selectedDate?.toIso8601String(),
        'status': 'Company Box',
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'last_action_by': accountantName ?? 'Unknown',
        'last_action_time': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incoming check submitted')));
      if (mounted) Navigator.of(context).pushReplacementNamed('/payment');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                                                    fillColor: isLoadingBanks
                                                        ? AppColors.cardAlt
                                                        : AppColors.card,
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
                                                  items: isLoadingBanks
                                                      ? null
                                                      : banks.map((bank) {
                                                          return DropdownMenuItem<
                                                            String
                                                          >(
                                                            value:
                                                                bank['bank_id']
                                                                    .toString(),
                                                            child: Text(
                                                              bank['bank_name'],
                                                            ),
                                                          );
                                                        }).toList(),
                                                  onChanged: isLoadingBanks
                                                      ? null
                                                      : (value) {
                                                          setState(() {
                                                            selectedBank =
                                                                value;
                                                            selectedBranch =
                                                                null; // Reset branch selection
                                                            branches =
                                                                []; // Clear branches
                                                          });
                                                          if (value != null) {
                                                            _fetchBranches(
                                                              value,
                                                            );
                                                          }
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
                                                    fillColor:
                                                        selectedBank == null
                                                        ? AppColors.cardAlt
                                                        : isLoadingBranches
                                                        ? AppColors.cardAlt
                                                        : AppColors.card,
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
                                                  items: selectedBank == null
                                                      ? null
                                                      : isLoadingBranches
                                                      ? null
                                                      : branches.map((branch) {
                                                          return DropdownMenuItem<
                                                            String
                                                          >(
                                                            value:
                                                                branch['branch_id']
                                                                    .toString(),
                                                            child: Text(
                                                              branch['address'] ??
                                                                  'Unknown',
                                                            ),
                                                          );
                                                        }).toList(),
                                                  onChanged:
                                                      selectedBank == null ||
                                                          isLoadingBranches
                                                      ? null
                                                      : (value) {
                                                          setState(
                                                            () =>
                                                                selectedBranch =
                                                                    value,
                                                          );
                                                        },
                                                  validator: (value) {
                                                    if (selectedBank == null) {
                                                      return "Please select bank first";
                                                    }
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
                                                    suffixIcon: const Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 12,
                                                      ),
                                                      child: Text(
                                                        '\$',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
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
                                                CompositedTransformTarget(
                                                  link: _dateLayerLink,
                                                  child: TextFormField(
                                                    controller: _dateController,
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
                                                      hintText: 'DD-MM-YYYY',
                                                      hintStyle: TextStyle(
                                                        color: AppColors.white
                                                            .withOpacity(0.6),
                                                      ),
                                                      suffixIcon: IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        icon: const Icon(
                                                          Icons.calendar_today,
                                                          color:
                                                              AppColors.white,
                                                          size: 22,
                                                        ),
                                                        onPressed:
                                                            _showDateOverlay,
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
                                                      enabledBorder: OutlineInputBorder(
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
                                                                      AppColors
                                                                          .blue,
                                                                  width: 1.8,
                                                                ),
                                                          ),
                                                    ),
                                                    onChanged: (value) {
                                                      // Try to parse the entered date
                                                      if (value.length == 10) {
                                                        try {
                                                          final parts = value
                                                              .split('-');
                                                          if (parts.length ==
                                                              3) {
                                                            final day =
                                                                int.tryParse(
                                                                  parts[0],
                                                                );
                                                            final month =
                                                                int.tryParse(
                                                                  parts[1],
                                                                );
                                                            final year =
                                                                int.tryParse(
                                                                  parts[2],
                                                                );
                                                            if (year != null &&
                                                                month != null &&
                                                                day != null) {
                                                              final parsedDate =
                                                                  DateTime(
                                                                    year,
                                                                    month,
                                                                    day,
                                                                  );
                                                              selectedDate =
                                                                  parsedDate;
                                                            }
                                                          }
                                                        } catch (e) {
                                                          // Invalid date format, selectedDate remains null
                                                        }
                                                      } else {
                                                        selectedDate = null;
                                                      }
                                                    },
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return "Please enter exchange date";
                                                      }
                                                      if (selectedDate ==
                                                          null) {
                                                        return "Invalid date format. Use DD-MM-YYYY";
                                                      }
                                                      return null;
                                                    },
                                                  ),
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
                                            onPressed: _pickCheckImage,
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

                                          Container(
                                            height: 220,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: AppColors.cardAlt,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.cardBorder,
                                                width: 1,
                                              ),
                                            ),
                                            child: _checkImageBytes == null
                                                ? const Center(
                                                    child: Text(
                                                      'No image selected',
                                                      style: TextStyle(
                                                        color: AppColors.white,
                                                      ),
                                                    ),
                                                  )
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: Image.memory(
                                                      _checkImageBytes!,
                                                      fit: BoxFit.contain,
                                                      width: double.infinity,
                                                      height: double.infinity,
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
                                  onPressed: _isSubmitting ? null : _submitForm,
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
                                    children: [
                                      if (_isSubmitting) ...const [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                      ] else ...const [
                                        Icon(Icons.check, size: 24),
                                        SizedBox(width: 20),
                                      ],
                                      const Text(
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';

class AppColors {
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D);
  static const blue = Color(0xFF50B2E7);
  static const white = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFF999999);
  static const divider = Color(0xFF3A3A3A);
  static const yellowBtn = Color(0xFFF9D949);
  static const card = Color(0xFF2D2D2D);
}

void showAddMeetingPopup(BuildContext context, VoidCallback onSuccess) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddMeetingPopup(onSuccess: onSuccess),
  );
}

class AddMeetingPopup extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddMeetingPopup({super.key, required this.onSuccess});

  @override
  State<AddMeetingPopup> createState() => _AddMeetingPopupState();
}

class _AddMeetingPopupState extends State<AddMeetingPopup> {
  int currentStep = 0; // 0 = Meeting Info, 1 = Products

  // Step 1: Meeting Info
  final TextEditingController topicsController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController resultController = TextEditingController();
  DateTime? selectedDateTime;
  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  List<int> selectedMemberIds = [];
  final TextEditingController memberSearchController = TextEditingController();

  // Step 2: Products
  List<Map<String, dynamic>> allBatches = [];
  List<Map<String, dynamic>> addedProducts =
      []; // {batch_id, product_id, product_name, quantity, reason}

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadBatches();
  }

  @override
  void dispose() {
    topicsController.dispose();
    addressController.dispose();
    resultController.dispose();
    memberSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final List<Map<String, dynamic>> members = [];

      // Fetch accountants
      final accountants = await supabase
          .from('accountant')
          .select('accountant_id, name');
      for (var accountant in accountants) {
        members.add({
          'user_id': accountant['accountant_id'],
          'name': accountant['name'] ?? 'Unknown',
          'type': 'accountant',
        });
      }

      // Fetch managers (storage_manager)
      final managers = await supabase
          .from('storage_manager')
          .select('storage_manager_id, name');
      for (var manager in managers) {
        members.add({
          'user_id': manager['storage_manager_id'],
          'name': manager['name'] ?? 'Unknown',
          'type': 'manager',
        });
      }

      // Fetch staff (storage_staff)
      final staff = await supabase
          .from('storage_staff')
          .select('storage_staff_id, name');
      for (var staffMember in staff) {
        members.add({
          'user_id': staffMember['storage_staff_id'],
          'name': staffMember['name'] ?? 'Unknown',
          'type': 'staff',
        });
      }

      // Fetch delivery drivers
      final deliveryDrivers = await supabase
          .from('delivery_driver')
          .select('delivery_driver_id, name');
      for (var driver in deliveryDrivers) {
        members.add({
          'user_id': driver['delivery_driver_id'],
          'name': driver['name'] ?? 'Unknown',
          'type': 'delivery',
        });
      }

      if (mounted) {
        setState(() {
          allMembers = members;
          filteredMembers = members;
          // Auto-select all accountants by default
          selectedMemberIds = members
              .where((member) => member['type'] == 'accountant')
              .map<int>((member) => member['user_id'] as int)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await supabase.from('batch').select('''
        batch_id,
        product_id,
        product:product_id(name),
        inventory:inventory_id(inventory_name),
        storage_location_descrption
      ''');

      if (mounted) {
        setState(() {
          allBatches = batches.map<Map<String, dynamic>>((batch) {
            return {
              'batch_id': batch['batch_id'],
              'product_id': batch['product_id'],
              'product_name': batch['product']?['name'] ?? 'Unknown',
              'inventory_name': batch['inventory']?['inventory_name'] ?? 'N/A',
              'storage_location': batch['storage_location_descrption'] ?? 'N/A',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading batches: $e');
    }
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMembers = allMembers;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredMembers = allMembers.where((member) {
          final name = member['name'].toString().toLowerCase();
          final type = member['type'].toString().toLowerCase();
          return name.contains(lowerQuery) || type.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              surface: AppColors.panel,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.blue,
                surface: AppColors.panel,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _nextStep() {
    if (currentStep == 0) {
      // Validate Step 1
      if (topicsController.text.trim().isEmpty) {
        _showError('Please enter meeting topics');
        return;
      }
      if (addressController.text.trim().isEmpty) {
        _showError('Please enter meeting address');
        return;
      }
      if (selectedDateTime == null) {
        _showError('Please select date and time');
        return;
      }
      if (resultController.text.trim().isEmpty) {
        _showError('Please enter result of meeting');
        return;
      }
      if (selectedMemberIds.isEmpty) {
        _showError('Please select at least one member');
        return;
      }

      setState(() => currentStep = 1);
    }
  }

  void _previousStep() {
    if (currentStep == 1) {
      setState(() => currentStep = 0);
    }
  }

  Future<void> _submitMeeting() async {
    if (addedProducts.isEmpty) {
      _showError('Please add at least one damaged product');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Insert meeting
      final meetingResponse = await supabase
          .from('damaged_products_meeting')
          .insert({
            'meeting_address': addressController.text.trim(),
            'meeting_time': selectedDateTime!.toIso8601String(),
            'meeting_topics': topicsController.text.trim(),
            'result_of_meeting': resultController.text.trim(),
          })
          .select('meeting_id')
          .single();

      final meetingId = meetingResponse['meeting_id'];

      // Insert members
      final memberInserts = selectedMemberIds.map((userId) {
        return {'meeting_id': meetingId, 'member_id': userId};
      }).toList();

      await supabase.from('meeting_memeber').insert(memberInserts);

      // Insert damaged products
      final productInserts = addedProducts.map((product) {
        return {
          'meeting_id': meetingId,
          'batch_id': product['batch_id'],
          'product_id': product['product_id'],
          'quantity': product['quantity'],
          'reason': product['reason'],
        };
      }).toList();

      await supabase.from('damaged_products').insert(productInserts);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        _showSuccess('Meeting created successfully');
      }
    } catch (e) {
      print('Error creating meeting: $e');
      _showError('Failed to create meeting: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    currentStep == 0
                        ? 'Add Meeting - Meeting Info'
                        : 'Add Meeting - Damaged Products',
                    style: GoogleFonts.roboto(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentStep == 1)
                    TextButton(
                      onPressed: _previousStep,
                      child: Text(
                        'Back',
                        style: GoogleFonts.roboto(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellowBtn,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : (currentStep == 0 ? _nextStep : _submitMeeting),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            currentStep == 0 ? 'Next' : 'Create Meeting',
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topics
        _buildLabel('Meeting Topics'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: topicsController,
          hint: 'Enter meeting topics',
        ),

        const SizedBox(height: 20),

        // Address
        _buildLabel('Meeting Address'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: addressController,
          hint: 'Enter meeting address',
        ),

        const SizedBox(height: 20),

        // Date & Time
        _buildLabel('Date & Time'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textGrey,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedDateTime == null
                      ? 'Select date and time'
                      : '${selectedDateTime!.day.toString().padLeft(2, '0')}/${selectedDateTime!.month.toString().padLeft(2, '0')}/${selectedDateTime!.year} ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.roboto(
                    color: selectedDateTime == null
                        ? AppColors.textGrey
                        : AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Result
        _buildLabel('Result of Meeting'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: resultController,
          hint: 'Enter result of meeting',
          maxLines: 3,
        ),

        const SizedBox(height: 20),

        // Members
        _buildLabel('Select Members'),
        const SizedBox(height: 8),

        // Search field
        _buildTextField(
          controller: memberSearchController,
          hint: 'Search members...',
        ),
        const SizedBox(height: 8),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: allMembers.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                )
              : filteredMembers.isEmpty
              ? Center(
                  child: Text(
                    'No members found',
                    style: GoogleFonts.roboto(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final isSelected = selectedMemberIds.contains(
                      member['user_id'],
                    );

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMemberIds.add(member['user_id']);
                          } else {
                            selectedMemberIds.remove(member['user_id']);
                          }
                        });
                      },
                      title: Text(
                        '${member['name']} (${member['type']})',
                        style: GoogleFonts.roboto(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      activeColor: AppColors.blue,
                      checkColor: Colors.white,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Product Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _showAddProductDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Damaged Product',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Products List
        if (addedProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text(
                'No products added yet',
                style: GoogleFonts.roboto(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...addedProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['product_name'],
                          style: GoogleFonts.roboto(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity: ${product['quantity']} | Reason: ${product['reason']}',
                          style: GoogleFonts.roboto(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        addedProducts.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddProductDialog() {
    Map<String, dynamic>? selectedBatch;
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.panel,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Damaged Product',
                  style: GoogleFonts.roboto(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                // Select Batch
                _buildLabel('Select Product/Batch'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedBatch,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.card,
                    hint: Text(
                      'Select a batch',
                      style: GoogleFonts.roboto(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                    items: allBatches.map((batch) {
                      return DropdownMenuItem(
                        value: batch,
                        child: Text(
                          '${batch['product_name']} (Batch #${batch['batch_id']})',
                          style: GoogleFonts.roboto(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBatch = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Quantity
                _buildLabel('Quantity'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: quantityController,
                  hint: 'Enter quantity',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Reason
                _buildLabel('Reason'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: reasonController,
                  hint: 'Enter reason for damage',
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (selectedBatch == null) {
                          _showError('Please select a batch');
                          return;
                        }
                        if (quantityController.text.trim().isEmpty) {
                          _showError('Please enter quantity');
                          return;
                        }
                        if (reasonController.text.trim().isEmpty) {
                          _showError('Please enter reason');
                          return;
                        }

                        final quantity = int.tryParse(
                          quantityController.text.trim(),
                        );
                        if (quantity == null || quantity <= 0) {
                          _showError('Please enter a valid quantity');
                          return;
                        }

                        setState(() {
                          addedProducts.add({
                            'batch_id': selectedBatch!['batch_id'],
                            'product_id': selectedBatch!['product_id'],
                            'product_name': selectedBatch!['product_name'],
                            'quantity': quantity,
                            'reason': reasonController.text.trim(),
                          });
                        });

                        Navigator.pop(context);
                      },
                      child: Text(
                        'Add',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        color: AppColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: controller == memberSearchController ? _filterMembers : null,
      style: GoogleFonts.roboto(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: AppColors.textGrey, fontSize: 14),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: controller == memberSearchController
            ? const Icon(Icons.search, color: AppColors.textGrey, size: 20)
            : null,
      ),
    );
  }
}

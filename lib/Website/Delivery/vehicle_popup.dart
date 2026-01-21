import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../supabase_config.dart';

class VehiclePopup extends StatefulWidget {
  final int plateId;
  final String brand;
  final String model;
  final String? vehicleImage;
  final bool isActive;

  const VehiclePopup({
    super.key,
    required this.plateId,
    required this.brand,
    required this.model,
    this.vehicleImage,
    this.isActive = false,
  });

  @override
  State<VehiclePopup> createState() => _VehiclePopupState();
}

class _VehiclePopupState extends State<VehiclePopup> {
  String _activeTab = 'vehicle'; // 'vehicle' or 'archive'
  Map<String, dynamic>? currentDriver;
  List<Map<String, dynamic>> driverHistory = [];
  bool _loading = true;
  int? hoveredRow;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    setState(() {
      _loading = true;
    });

    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // Fetch current driver assignment
      final currentRes = await supabase
          .from('delivery_vehicle')
          .select(
            'delivery_driver_id, from_date, to_date, delivery_driver!delivery_vehicle_delivery_driver_id_fkey(name, accounts!delivery_driver_delivery_driver_id_fkey(profile_image))',
          )
          .eq('plate_id', widget.plateId)
          .lte('from_date', todayStr)
          .gte('to_date', todayStr)
          .maybeSingle();

      // Fetch all driver history
      final historyRes =
          await supabase
                  .from('delivery_vehicle')
                  .select(
                    'delivery_driver_id, from_date, to_date, delivery_driver!delivery_vehicle_delivery_driver_id_fkey(name)',
                  )
                  .eq('plate_id', widget.plateId)
                  .order('from_date', ascending: false)
              as List<dynamic>;

      if (mounted) {
        setState(() {
          if (currentRes != null) {
            final driver = currentRes['delivery_driver'];
            String? profileImage;
            if (driver is Map<String, dynamic>) {
              final account = driver['accounts'];
              if (account is List && account.isNotEmpty) {
                profileImage = account.first['profile_image'] as String?;
              } else if (account is Map<String, dynamic>) {
                profileImage = account['profile_image'] as String?;
              }

              currentDriver = {
                'driver_id': currentRes['delivery_driver_id'],
                'driver_name': driver['name'],
                'profile_image': profileImage,
                'from_date': currentRes['from_date'],
                'to_date': currentRes['to_date'],
              };
            }
          }

          driverHistory = historyRes.map((record) {
            final driver = record['delivery_driver'];
            String? driverName;
            if (driver is Map<String, dynamic>) {
              driverName = driver['name'] as String?;
            }

            return {
              'driver_id': record['delivery_driver_id'],
              'driver_name': driverName ?? 'Unknown',
              'from_date': record['from_date'],
              'to_date': record['to_date'],
            };
          }).toList();

          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicle data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header with Title and Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.brand} ${widget.model}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tabs under the title
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _PopupTextTab(
                        label: 'Vehicle',
                        isActive: _activeTab == 'vehicle',
                        onTap: () {
                          setState(() {
                            _activeTab = 'vehicle';
                          });
                        },
                      ),
                      _PopupTextTab(
                        label: 'Archive',
                        isActive: _activeTab == 'archive',
                        onTap: () {
                          setState(() {
                            _activeTab = 'archive';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _activeTab == 'vehicle'
                  ? _buildVehicleTab()
                  : _buildArchiveTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Vehicle Image
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  widget.vehicleImage != null && widget.vehicleImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.vehicleImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.local_shipping,
                              size: 80,
                              color: Colors.white54,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.local_shipping,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 24),

          // Right side - Details
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Details
                  _buildDetailRow('Plate ID', widget.plateId.toString()),
                  const SizedBox(height: 12),
                  _buildDetailRow('Brand', widget.brand),
                  const SizedBox(height: 12),
                  _buildDetailRow('Model', widget.model),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Status',
                    widget.isActive ? 'Active' : 'Inactive',
                    valueColor: widget.isActive
                        ? const Color(0xFF67CD67)
                        : Colors.grey,
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Current Driver
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currently Assigned To',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (currentDriver != null)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF50B2E7),
                            size: 20,
                          ),
                          onPressed: () => _showEditToDateDialog(),
                          tooltip: 'Edit To Date',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (currentDriver != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                currentDriver!['profile_image'] != null &&
                                    currentDriver!['profile_image'].isNotEmpty
                                ? NetworkImage(currentDriver!['profile_image'])
                                : null,
                            backgroundColor: const Color(0xFF67CD67),
                            child:
                                currentDriver!['profile_image'] == null ||
                                    currentDriver!['profile_image'].isEmpty
                                ? Text(
                                    currentDriver!['driver_name'][0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentDriver!['driver_name'],
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(currentDriver!['from_date']))}',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'To: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(currentDriver!['to_date']))}',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Not currently assigned to any driver',
                          style: GoogleFonts.roboto(
                            color: Colors.white60,
                            fontSize: 14,
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

  Widget _buildArchiveTab() {
    if (driverHistory.isEmpty) {
      return Center(
        child: Text(
          'No assignment history',
          style: GoogleFonts.roboto(color: Colors.white60, fontSize: 14),
        ),
      );
    }

    const headerStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignment History',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Row(
            children: const [
              Expanded(flex: 4, child: Text('Driver Name', style: headerStyle)),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('From Date', style: headerStyle),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('To Date', style: headerStyle),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          // Line under header
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withOpacity(0.4),
          ),

          const SizedBox(height: 10),

          // Table Rows with zebra striping
          Expanded(
            child: ListView.builder(
              itemCount: driverHistory.length,
              padding: const EdgeInsets.only(top: 6),
              itemBuilder: (context, index) {
                final record = driverHistory[index];
                final isEven = index % 2 == 0;

                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => hoveredRow = index),
                    onExit: (_) => setState(() => hoveredRow = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isEven
                            ? const Color(0xFF262626)
                            : const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(26),
                        border: hoveredRow == index
                            ? Border.all(
                                color: const Color(0xFF50B2E7),
                                width: 1.5,
                              )
                            : null,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              record['driver_name'],
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(DateTime.parse(record['from_date'])),
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF50B2E7),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(DateTime.parse(record['to_date'])),
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF50B2E7),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showEditToDateDialog() async {
    if (currentDriver == null) return;

    final currentToDate = DateTime.parse(currentDriver!['to_date']);
    DateTime selectedDate = currentToDate;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Assignment End Date',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Driver: ${currentDriver!['driver_name']}',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(currentDriver!['from_date']))}',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.parse(
                            currentDriver!['from_date'],
                          ),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF50B2E7),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF2D2D2D),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202020),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF50B2E7).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'To Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF50B2E7),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.roboto(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(selectedDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF50B2E7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await _updateToDate(result);
    }
  }

  Future<void> _updateToDate(DateTime newToDate) async {
    try {
      final newToDateStr = DateFormat('yyyy-MM-dd').format(newToDate);
      final fromDateStr = currentDriver!['from_date'];
      final driverId = currentDriver!['driver_id'];

      await supabase
          .from('delivery_vehicle')
          .update({'to_date': newToDateStr})
          .match({
            'plate_id': widget.plateId,
            'delivery_driver_id': driverId,
            'from_date': fromDateStr,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assignment end date updated successfully',
              style: GoogleFonts.roboto(),
            ),
            backgroundColor: const Color(0xFF67CD67),
          ),
        );

        // Refresh data
        await _fetchVehicleData();
      }
    } catch (e) {
      debugPrint('Error updating to_date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update end date: $e',
              style: GoogleFonts.roboto(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ------------------------------------------------------------------
// Popup Text Tab Widget (matching payment_header.dart style)
// ------------------------------------------------------------------
class _PopupTextTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PopupTextTab({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF50B2E7) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.roboto(
              color: isActive ? Colors.white : const Color(0xFF999999),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../manager_theme.dart';
import '../../supabase_config.dart';

class SelectVehicleSheet extends StatefulWidget {
  final int driverId;
  final String driverName;
  final void Function(int vehicleId, DateTime fromDate, DateTime toDate)
  onSelected;

  const SelectVehicleSheet({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.onSelected,
  });

  @override
  State<SelectVehicleSheet> createState() => _SelectVehicleSheetState();
}

class _SelectVehicleSheetState extends State<SelectVehicleSheet> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  int? _selectedVehicleId;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _loadAvailableVehicles();
  }

  Future<void> _loadAvailableVehicles() async {
    setState(() => _loading = true);

    try {
      final fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd').format(_toDate);

      // Get all vehicles
      final allVehicles = await supabase
          .from('vehicle')
          .select('plate_id, brand, model, vehicle_image, is_active')
          .eq('is_active', true)
          .order('plate_id');

      // Get vehicles already assigned in the selected date range
      final assignedVehicles = await supabase
          .from('delivery_vehicle')
          .select('plate_id')
          .lte('from_date', toDateStr)
          .gte('to_date', fromDateStr);

      final assignedIds = assignedVehicles
          .map((v) => v['plate_id'] as int)
          .toSet();

      // Filter available vehicles
      final available = allVehicles.where((v) {
        final plateId = v['plate_id'] as int;
        return !assignedIds.contains(plateId);
      }).toList();

      setState(() {
        _vehicles = available;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      setState(() {
        _vehicles = [];
        _loading = false;
      });
    }
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.card,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Ensure to date is after from date
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate.add(const Duration(days: 1));
          }
        } else {
          _toDate = picked;
        }
      });
      // Reload vehicles for new date range
      _loadAvailableVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Vehicle",
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "for ${widget.driverName}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date Range Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assignment Period',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'From',
                        date: _fromDate,
                        onTap: () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'To',
                        date: _toDate,
                        onTap: () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Vehicles List
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else if (_vehicles.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No available vehicles',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try changing the date range',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  final plateId = vehicle['plate_id'] as int;
                  final brand = vehicle['brand'] as String? ?? 'Unknown';
                  final model = vehicle['model'] as String? ?? 'Unknown';
                  final image = vehicle['vehicle_image'] as String?;
                  final isSelected = _selectedVehicleId == plateId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicleId = plateId;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withOpacity(0.15)
                            : AppColors.bgDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Vehicle Image
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                              image: image != null && image.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(image),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: image == null || image.isEmpty
                                ? const Icon(
                                    Icons.directions_car,
                                    color: Colors.white54,
                                    size: 32,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 14),

                          // Vehicle Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$brand $model',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Plate ID: $plateId',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Selection indicator
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Confirm Button
          GestureDetector(
            onTap: _selectedVehicleId == null
                ? null
                : () {
                    widget.onSelected(_selectedVehicleId!, _fromDate, _toDate);
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _selectedVehicleId != null
                    ? const LinearGradient(
                        colors: [AppColors.gold, AppColors.yellow],
                      )
                    : null,
                color: _selectedVehicleId == null ? Colors.white24 : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _selectedVehicleId != null
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: const Text(
                'Confirm Vehicle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';

class LocationFormPopup extends StatefulWidget {
  final void Function(bool) onSubmit;
  const LocationFormPopup({super.key, required this.onSubmit});

  @override
  State<LocationFormPopup> createState() => _LocationFormPopupState();
}

class _LocationFormPopupState extends State<LocationFormPopup> {
  final _cityCtrl = TextEditingController();
  final _quarterCtrl = TextEditingController();
  bool _saving = false;
  String? _cityErr, _quarterErr;

  @override
  void dispose() {
    _cityCtrl.dispose();
    _quarterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final city = _cityCtrl.text.trim();
    final quarter = _quarterCtrl.text.trim();
    setState(() {
      _cityErr = city.isEmpty ? 'City name is required' : null;
      _quarterErr = quarter.isEmpty ? 'Quarter name is required' : null;
    });
    if (_cityErr != null || _quarterErr != null) return;

    try {
      setState(() => _saving = true);
      final insertedCity = await supabase
          .from('customer_city')
          .insert({'name': city})
          .select()
          .maybeSingle();
      if (insertedCity == null) throw Exception('Failed inserting city');
      final cityId = insertedCity['customer_city_id'] as int;

      final insertedQuarter = await supabase
          .from('customer_quarters')
          .insert({'name': quarter, 'customer_city': cityId})
          .select()
          .maybeSingle();
      if (insertedQuarter == null) throw Exception('Failed inserting quarter');

      if (mounted) widget.onSubmit(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Location',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(label: 'City Name', ctrl: _cityCtrl, error: _cityErr),
        const SizedBox(height: 12),
        _field(label: 'Quarter Name', ctrl: _quarterCtrl, error: _quarterErr),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50B2E7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : const Icon(Icons.north_east_rounded, color: Colors.black),
            label: Text(
              _saving ? 'Saving...' : 'Submit',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: const Color(0xFFB7A447),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? Colors.red : const Color(0xFF3D3D3D),
              width: error != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
      ],
    );
  }
}

void showLocationPopup(BuildContext context, void Function(bool) onSubmit) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LocationFormPopup(onSubmit: onSubmit),
        ),
      ),
    ),
  );
}

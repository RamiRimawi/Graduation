import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_popup_widgets.dart';

class SalesRepFormPopup extends StatefulWidget {
  final List<String> cities;
  final void Function(Map<String, dynamic>) onSubmit;

  const SalesRepFormPopup({
    super.key,
    required this.cities,
    required this.onSubmit,
  });

  @override
  State<SalesRepFormPopup> createState() => _SalesRepFormPopupState();
}

class _SalesRepFormPopupState extends State<SalesRepFormPopup> {
  final name = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final tel = TextEditingController();

  late String city;

  @override
  void initState() {
    super.initState();
    city = widget.cities.first;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    mobile.dispose();
    tel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Sales Rep',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),

        TwoColRow(
          left: FieldInput(
            controller: name,
            label: 'Full Name',
            hint: 'Entre Full Name',
          ),
          right: FieldInput(
            controller: email,
            label: 'Email',
            hint: 'Entre Email',
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 18),

        TwoColRow(
          left: FieldInput(
            controller: mobile,
            label: 'Mobile Number',
            hint: 'Entre Mobile Number',
            type: TextInputType.phone,
          ),
          right: FieldInput(
            controller: tel,
            label: 'Telephone Number',
            hint: 'Entre Telephone Number',
            type: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 18),

        TwoColRow(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              CityDropdown(
                items: widget.cities,
                value: city,
                onChanged: (v) => setState(() => city = v),
              ),
            ],
          ),
          right: const SizedBox(),
        ),

        const SizedBox(height: 25),

        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SubmitButton(
              text: 'Submit',
              icon: Icons.person_add_alt_1,
              onTap: () {
                if (name.text.trim().isEmpty) return;
                widget.onSubmit({'name': name.text.trim(), 'city': city});
              },
            ),
          ),
        ),
      ],
    );
  }
}

void showSalesRepPopup(
  BuildContext context,
  List<String> cities,
  Function(Map<String, dynamic>) onSubmit,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SalesRepFormPopup(
              cities: cities,
              onSubmit: onSubmit,
            ),
          ),
        ),
      );
    },
  );
}

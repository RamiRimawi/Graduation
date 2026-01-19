import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Notifications/notification_bell_widget.dart';

class DeliveryHeader extends StatelessWidget {
  final String title;

  const DeliveryHeader({super.key, this.title = "Delivery"});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const NotificationBellWidget(),
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailPopup {
  static void show(
    BuildContext context, {
    required String orderType, // "in" أو "out"
    required String status, // "NEW" أو "UPDATE" أو "HOLD"
    required List<Map<String, dynamic>> products,
    String? partyName,
    String? location,
    DateTime? orderDate,
    num? taxPercent,
    num? totalPrice,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => _OrderDetailDialog(
        orderType: orderType,
        status: status,
        products: products,
        partyName: partyName,
        location: location,
        orderDate: orderDate,
        taxPercent: taxPercent,
        totalPrice: totalPrice,
      ),
    );
  }
}

class _OrderDetailDialog extends StatefulWidget {
  final String orderType;
  final String status;
  final List<Map<String, dynamic>> products;
  final String? partyName;
  final String? location;
  final DateTime? orderDate;
  final num? taxPercent;
  final num? totalPrice;

  const _OrderDetailDialog({
    required this.orderType,
    required this.status,
    required this.products,
    this.partyName,
    this.location,
    this.orderDate,
    this.taxPercent,
    this.totalPrice,
  });

  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  late List<Map<String, dynamic>> _products;

  @override
  void initState() {
    super.initState();
    _products = List<Map<String, dynamic>>.from(widget.products);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}-${dt.month}-${dt.year}';
  }

  String _formatMoney(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(2)}\$';
  }

  num _calculateSubtotal() {
    num sum = 0;
    for (final p in _products) {
      final quantity = (p['quantity'] ?? 0) as num;
      final priceStr = p['price']?.toString() ?? '0';
      final price =
          num.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
      sum += price * quantity;
    }
    return sum;
  }

  String _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final taxPercent = widget.taxPercent ?? 0;
    final taxAmount = subtotal * taxPercent / 100;
    final total = subtotal + taxAmount;
    return total == 0 ? '-' : _formatMoney(total);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomerOut = widget.orderType == "out";
    final bool isNew = widget.status == "NEW";
    final bool isHold = widget.status == "HOLD";
    final bool showDiscountField = isCustomerOut && (isNew || isHold);
    final bool showLaterButton = isNew;

    final orderDateValue = widget.orderDate ?? DateTime.now();
    final totalText = _calculateTotal();
    final taxText = widget.taxPercent != null
        ? '${widget.taxPercent.toString()}%'
        : '-';

    final discountCtrl = TextEditingController();

    return Stack(
      children: [
        // ---------- خلفية مغبشة ----------
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),

        // ---------- محتوى الـ Popup ----------
        Center(
          child: Material(
            // ✅ إصلاح الخطأ هنا
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 1000,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------- العنوان -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Detail',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: widget.status == "NEW"
                                    ? Colors.yellow.shade600
                                    : widget.status == "HOLD"
                                    ? Colors.orange.shade600
                                    : Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.status == "HOLD"
                                    ? "HOLD"
                                    : widget.status,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // -------------------- بيانات العميل / المورد --------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            widget.orderType == "in"
                                ? "Supplier Name: ${widget.partyName ?? '-'}"
                                : "Customer: ${widget.partyName ?? '-'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        if (widget.orderType == "out") ...[
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "City : ${(widget.location?.split(' - ').isNotEmpty ?? false) ? widget.location!.split(' - ')[0] : '-'}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Quarter : ${(widget.location?.split(' - ').length ?? 0) > 1 ? widget.location!.split(' - ')[1] : '-'}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          const Spacer(flex: 3),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date : ${_formatDate(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                              Text(
                                "Time : ${_formatTime(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        if (isCustomerOut)
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Tax percent : $taxText",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          )
                        else
                          const Spacer(flex: 2),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ------------------------- الجدول -------------------------
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Product ID #"),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(child: Text("Product Name")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Brand")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Price per product")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Quantity")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Total Price"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 0),

                        // الصفوف
                        for (final product in _products)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      product["id"].toString(),
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text(
                                      product["name"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["brand"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["price"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),

                                // ------- Quantity with editable field -------
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (product["quantity"] ?? 0) > 0
                                            ? const Color(0xFFB7A447)
                                            : const Color(0xFF6F6F6F),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: TextFormField(
                                              key: ValueKey(
                                                'qty_${product["id"]}',
                                              ),
                                              initialValue:
                                                  product["quantity"] == 0 ||
                                                      product["quantity"]
                                                          is! num
                                                  ? ''
                                                  : product["quantity"]
                                                        .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              cursorColor: Colors.white,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                                hintText: '0',
                                                hintStyle: TextStyle(
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  final newQty =
                                                      int.tryParse(value) ?? 0;
                                                  product["quantity"] = newQty;

                                                  // Update the total for this product
                                                  final priceStr =
                                                      product['price']
                                                          ?.toString() ??
                                                      '0';
                                                  final price =
                                                      num.tryParse(
                                                        priceStr.replaceAll(
                                                          RegExp(r'[^0-9.-]'),
                                                          '',
                                                        ),
                                                      ) ??
                                                      0;
                                                  final newTotal =
                                                      price * newQty;
                                                  product["total"] =
                                                      _formatMoney(newTotal);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            product["unit_name"] ?? 'pcs',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      product["total"].toString(),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- Discount + Total -------------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showDiscountField) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Discount",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  height: 35,
                                  child: TextField(
                                    controller: discountCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "Discount value",
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF232427),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB7A447),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            222,
                                            74,
                                          ),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Total Price : ",
                                style: TextStyle(
                                  color: Color(0xFFB7A447),
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                totalText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- الأزرار -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.status == "NEW") ...[
                          _OrderButton(
                            label: "Later",
                            color: Colors.grey.shade600,
                            icon: Icons.access_time,
                          ),
                          const SizedBox(width: 14),
                        ],
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Reject Update"
                              : "Reject Order",
                          color: Colors.red.shade700,
                          icon: Icons.cancel_outlined,
                        ),
                        const SizedBox(width: 14),
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Accept Update"
                              : widget.status == "HOLD"
                              ? "Send Order"
                              : "Send Order",
                          color: Colors.yellow.shade600,
                          icon: Icons.send_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------ زر داخل الـ popup ------------------------
class _OrderButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _OrderButton({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => Navigator.pop(context),
      icon: Icon(icon, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

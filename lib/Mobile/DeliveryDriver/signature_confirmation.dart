import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../supabase_config.dart';

class SignatureConfirmation extends StatefulWidget {
  final String customerName;
  final int customerId;
  final int orderId;
  final List<Map<String, dynamic>>? products;
  final Map<int, int>? deliveredQuantities;

  const SignatureConfirmation({
    super.key,
    required this.customerName,
    required this.customerId,
    required this.orderId,
    this.products,
    this.deliveredQuantities,
  });

  @override
  State<SignatureConfirmation> createState() => _SignatureConfirmationState();
}

class _SignatureConfirmationState extends State<SignatureConfirmation> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFFB7A447),
    exportBackgroundColor: const Color(0xFF2D2D2D),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.draw,
                    color: Color(0xFFB7A447),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Signature Confirmation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Customer name
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFFB7A447),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Signature area
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFB7A447).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Signature canvas
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                          child: Signature(
                            controller: _controller,
                            height: 250,
                            backgroundColor: const Color(0xFF2D2D2D),
                          ),
                        ),
                        // "Please Sign Here" text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF202020),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Please Sign Here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clear button
                  TextButton.icon(
                    onPressed: () {
                      _controller.clear();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 20,
                    ),
                    label: const Text(
                      'Clear Signature',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Confirm & Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_controller.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please provide a signature'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Export signature as PNG image bytes
                          final Uint8List? signatureBytes = await _controller.toPngBytes();
                          
                          if (signatureBytes == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to capture signature'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          // Convert signature to base64 string for database storage
                          final signatureBase64 = base64Encode(signatureBytes);

                          // Save signature to database and update status to Delivered
                          debugPrint('⏳ Updating order status to Delivered for order ${widget.orderId}');
                          await supabase.from('customer_order').update({
                            'customer_signature': signatureBase64,
                            'order_status': 'Delivered',
                            'last_action_time': DateTime.now().toIso8601String(),
                          }).eq('customer_order_id', widget.orderId);

                          debugPrint('✅ Signature saved and order status updated to Delivered for order ${widget.orderId}');
                          try {
                              // Get delivery driver ID from order
                              final orderRes = await supabase
                                  .from('customer_order')
                                  .select('delivered_by_id')
                                  .eq('customer_order_id', widget.orderId)
                                  .limit(1);
                              
                              if (orderRes.isNotEmpty) {
                                final orderData = (orderRes as List<dynamic>).first as Map<String, dynamic>;
                                final driverId = orderData['delivered_by_id'] as int?;
                                
                                if (driverId != null) {
                                  await supabase
                                      .from('delivery_driver')
                                      .update({'current_order_id': null})
                                      .eq('delivery_driver_id', driverId);
                                  
                                  debugPrint('✅ Cleared current_order_id for driver $driverId');
                                }
                              }
                            } catch (e) {
                              debugPrint('❌ Error clearing current_order_id: $e');
                            }
                          // Update order descriptions using edited quantities if provided
                          try {
                            if (widget.deliveredQuantities != null && widget.deliveredQuantities!.isNotEmpty) {
                              for (final entry in widget.deliveredQuantities!.entries) {
                                final productId = entry.key;
                                final qty = entry.value;
                                await supabase
                                    .from('customer_order_description')
                                    .update({
                                      'delivered_quantity': qty,
                                      'delivered_date': DateTime.now().toIso8601String(),
                                    })
                                    .eq('customer_order_id', widget.orderId)
                                    .eq('product_id', productId);
                              }
                              debugPrint('Delivered quantities updated from edited values for order ${widget.orderId}');
                            } else if (widget.products != null && widget.products!.isNotEmpty) {
                              for (final p in widget.products!) {
                                final productId = p['product_id'] as int?;
                                final qty = p['quantity'] as int? ?? 0;
                                if (productId != null) {
                                  await supabase
                                      .from('customer_order_description')
                                      .update({
                                        'delivered_quantity': qty,
                                        'delivered_date': DateTime.now().toIso8601String(),
                                      })
                                      .eq('customer_order_id', widget.orderId)
                                      .eq('product_id', productId);
                                }
                              }
                              debugPrint('Delivered quantities updated from UI for order ${widget.orderId}');
                            } else {
                              final descRes = await supabase
                                  .from('customer_order_description')
                                  .select('product_id,quantity')
                                  .eq('customer_order_id', widget.orderId);

                              if ((descRes as List<dynamic>).isNotEmpty) {
                                for (final desc in descRes as List<dynamic>) {
                                  final descMap = desc as Map<String, dynamic>;
                                  final productId = descMap['product_id'] as int?;
                                  final qty = descMap['quantity'] as int? ?? 0;
                                  if (productId != null) {
                                    await supabase
                                        .from('customer_order_description')
                                        .update({
                                          'delivered_quantity': qty,
                                          'delivered_date': DateTime.now().toIso8601String(),
                                        })
                                        .eq('customer_order_id', widget.orderId)
                                        .eq('product_id', productId);
                                  }
                                }
                                debugPrint('Delivered quantities updated from DB for order ${widget.orderId}');
                              }
                            }
                          } catch (e) {
                            debugPrint('Error updating delivered quantities: $e');
                          }

                          // Return true and navigate back to home
                          if (mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          debugPrint('Error saving signature: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save signature: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7A447),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Confirm & Submit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
}

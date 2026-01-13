import 'package:flutter/material.dart';
import '../../supabase_config.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const grey = Color(0xFF999999);
  static const dark = Color(0xFF202020);
  static const black = Color(0xFF000000);
  static const textGrey = Color(0xFF999999);
  static const divider = Color(0xFF3A3A3A);
  static const hoverRow = Color(0xFF353535);
}

class MeetingDetailsDialog extends StatefulWidget {
  final int meetingId;

  const MeetingDetailsDialog({super.key, required this.meetingId});

  @override
  State<MeetingDetailsDialog> createState() => _MeetingDetailsDialogState();
}

class _MeetingDetailsDialogState extends State<MeetingDetailsDialog> {
  Map<String, dynamic>? meetingData;
  List<Map<String, dynamic>> damagedProducts = [];
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  double totalLoss = 0;

  @override
  void initState() {
    super.initState();
    _fetchMeetingDetails();
  }

  Future<void> _fetchMeetingDetails() async {
    setState(() => isLoading = true);

    try {
      // Fetch meeting details
      final meetingResponse = await supabase
          .from('damaged_products_meeting')
          .select()
          .eq('meeting_id', widget.meetingId)
          .single();

      // Fetch damaged products
      final productsResponse = await supabase
          .from('damaged_products')
          .select('''
            batch_id,
            product_id,
            quantity,
            reason
          ''')
          .eq('meeting_id', widget.meetingId);

      // Fetch batch details separately for each damaged product
      final List<Map<String, dynamic>> products = [];
      double loss = 0;

      for (var item in productsResponse) {
        final batchId = item['batch_id'];
        final productId = item['product_id'];

        // Fetch batch with product and inventory info
        final batchResponse = await supabase
            .from('batch')
            .select('''
              batch_id,
              product_id,
              storage_location_descrption,
              inventory_id,
              product:product_id (
                name,
                selling_price,
                product_image
              ),
              inventory:inventory_id (
                inventory_name
              )
            ''')
            .eq('batch_id', batchId)
            .eq('product_id', productId)
            .single();

        final product = batchResponse['product'];
        final inventory = batchResponse['inventory'];
        final quantity = item['quantity'] ?? 0;
        final price = product?['selling_price'] ?? 0;
        final productLoss = quantity * price;
        loss += productLoss;

        products.add({
          'batch_id': batchId,
          'product_name': product?['name'] ?? 'Unknown',
          'product_image': product?['product_image'],
          'inventory_name': inventory?['inventory_name'] ?? 'N/A',
          'storage_location':
              batchResponse['storage_location_descrption'] ?? 'N/A',
          'quantity': quantity,
          'price': price,
          'total_loss': productLoss,
          'reason': item['reason'] ?? 'No reason provided',
        });
      }

      // Fetch meeting members
      final membersResponse = await supabase
          .from('meeting_memeber')
          .select('''
            member_id,
            type,
            accounts:member_id (
              user_id,
              profile_image,
              accountant(name),
              storage_manager(name),
              storage_staff(name),
              delivery_driver(name),
              customer(name),
              supplier(name),
              sales_representative(name)
            )
          ''')
          .eq('meeting_id', widget.meetingId);

      // Process members
      final List<Map<String, dynamic>> membersList = [];
      for (var member in membersResponse) {
        final accounts = member['accounts'];
        String memberName = 'Unknown';

        // Check each possible type
        if (accounts?['accountant'] != null) {
          memberName = accounts['accountant']['name'] ?? 'Unknown';
        } else if (accounts?['storage_manager'] != null) {
          memberName = accounts['storage_manager']['name'] ?? 'Unknown';
        } else if (accounts?['storage_staff'] != null) {
          memberName = accounts['storage_staff']['name'] ?? 'Unknown';
        } else if (accounts?['delivery_driver'] != null) {
          memberName = accounts['delivery_driver']['name'] ?? 'Unknown';
        } else if (accounts?['customer'] != null) {
          memberName = accounts['customer']['name'] ?? 'Unknown';
        } else if (accounts?['supplier'] != null) {
          memberName = accounts['supplier']['name'] ?? 'Unknown';
        } else if (accounts?['sales_representative'] != null) {
          memberName = accounts['sales_representative']['name'] ?? 'Unknown';
        }

        membersList.add({
          'member_id': member['member_id'],
          'name': memberName,
          'type': member['type'] ?? 'N/A',
          'profile_image': accounts?['profile_image'],
        });
      }

      if (mounted) {
        setState(() {
          meetingData = meetingResponse;
          damagedProducts = products;
          members = membersList;
          totalLoss = loss;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching meeting details: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              )
            : Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.group,
                          color: AppColors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meeting #${widget.meetingId}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _formatDateTime(meetingData?['meeting_time']),
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting Info
                          _InfoSection(
                            title: 'Meeting Information',
                            children: [
                              _InfoRow(
                                label: 'Topics',
                                value: meetingData?['meeting_topics'] ?? 'N/A',
                              ),
                              _InfoRow(
                                label: 'Address',
                                value: meetingData?['meeting_address'] ?? 'N/A',
                              ),
                              _InfoRow(
                                label: 'Result',
                                value:
                                    meetingData?['result_of_meeting'] ?? 'N/A',
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Members
                          _InfoSection(
                            title: 'Meeting Members',
                            children: [
                              if (members.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No members recorded',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: members.map((member) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.dark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.blue
                                                .withOpacity(0.2),
                                            backgroundImage:
                                                member['profile_image'] !=
                                                        null &&
                                                    member['profile_image']
                                                        .toString()
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                    member['profile_image'],
                                                  )
                                                : null,
                                            child:
                                                member['profile_image'] ==
                                                        null ||
                                                    member['profile_image']
                                                        .toString()
                                                        .isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: AppColors.blue,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member['name'],
                                                style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                member['type'],
                                                style: const TextStyle(
                                                  color: AppColors.textGrey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Damaged Products
                          Row(
                            children: [
                              const Text(
                                'Damaged Products',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Total Loss: \$${totalLoss.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (damagedProducts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No damaged products recorded',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...damagedProducts.map((product) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.dark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.divider.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Name & Loss Amount Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['product_name'],
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'Loss: \$${product['total_loss'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Details Grid
                                    Row(
                                      children: [
                                        // Left Column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _DetailRow(
                                                icon: Icons.inventory_2,
                                                label: 'Inventory',
                                                value:
                                                    product['inventory_name'],
                                                valueColor: AppColors.blue,
                                              ),
                                              const SizedBox(height: 10),
                                              _DetailRow(
                                                icon: Icons.location_on,
                                                label: 'Location',
                                                value:
                                                    product['storage_location'],
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 24),

                                        // Right Column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _DetailRow(
                                                icon: Icons.shopping_cart,
                                                label: 'Quantity',
                                                value: product['quantity']
                                                    .toString(),
                                              ),
                                              const SizedBox(height: 10),
                                              _DetailRow(
                                                icon: Icons.attach_money,
                                                label: 'Unit Price',
                                                value:
                                                    '\$${product['price'].toString()}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Reason Section
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: AppColors.textGrey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Reason:',
                                                  style: TextStyle(
                                                    color: AppColors.textGrey,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  product['reason'],
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 13,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for detail rows
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textGrey, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

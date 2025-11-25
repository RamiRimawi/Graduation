import 'package:flutter/material.dart';

class ProductDetailsPopup extends StatelessWidget {
  final String productId;
  final String productName;
  final String brandName;
  final String category;
  final String wholesalePrice;
  final String sellingPrice;
  final String minProfit;
  final VoidCallback onClose;

  const ProductDetailsPopup({
    super.key,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.category,
    required this.wholesalePrice,
    required this.sellingPrice,
    required this.minProfit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // خلفية غامقة لإغلاق الـ popup عند الكبس خارجها
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black54),
          ),
        ),

        // محتوى الـ Popup
        Center(
          child: GestureDetector(
            onTap: () {}, // عشان ما يسكر لما تكبس داخل
            child: Container(
              width: 900,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 900,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 العنوان + زر Edit + X
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            productName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFE14D),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Edit product
                              },
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.black87,
                              ),
                              label: const Text(
                                'Edit Product',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE14D),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: onClose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🔹 المحتوى (صور + تفاصيل) قابل للسكرول
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ◀ القسم اليسار: الصور
                          Container(
                            width: 400,
                            height: 600,
                            margin: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                // الصورة الرئيسية
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset(
                                      'assets/icon/hand_shower.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 100,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                // صورة إضافية / زوم
                                Container(
                                  height: 200,
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/hand_shower.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ▶ القسم اليمين: التفاصيل (مثل الصورة الثانية)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // الصف الأول: id / brand / category
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Product id#',
                                        value: productId,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Brand Name',
                                        value: brandName,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Category',
                                        value: category,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // الصف الثاني: wholesale / selling / min profit
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Wholesale Price',
                                        value: wholesalePrice,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Selling  Price',
                                        value: sellingPrice,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Minimum Profit %',
                                        value: minProfit,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // 🔹 الكمية
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    color: Color(0xFFB7A447),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const _InlineDetailRow(
                                  label: 'Inventory #1',
                                  value: '5000 pcs',
                                ),
                                const SizedBox(height: 12),
                                const _InlineDetailRow(
                                  label: 'Inventory #2',
                                  value: '30000 pcs',
                                ),
                                const SizedBox(height: 30),

                                // 🔹 موقع التخزين
                                const Text(
                                  'Storage Location',
                                  style: TextStyle(
                                    color: Color(0xFFB7A447),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const _InlineDetailRow(
                                  label: 'Inventory #1',
                                  value: 'Floor 2, Aisle 5, Shelf 3',
                                ),
                                const SizedBox(height: 12),
                                const _InlineDetailRow(
                                  label: 'Inventory #2',
                                  value: 'Floor 2, Aisle 2, Shelf 5',
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 🔹 عنصر عرض حقل التفاصيل (لصفوف الثلاثية فوق)
class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB7A447),
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// 🔹 Row على شكل:  Inventory #1  [value]
class _InlineDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _InlineDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

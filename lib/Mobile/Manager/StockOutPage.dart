import 'package:flutter/material.dart';
import 'Bar.dart';
import 'PendingOrderDetailsPage.dart';
import 'PreparingOrderDetailsPage.dart';
import 'order_item.dart';
import 'PreparedOrderDetailsPage.dart';
import 'DriverOrdersPage.dart';

// ====================== MODELS ======================

class OrderInfo {
  final int id;
  final String customerName;
  final int inventoryNo;
  final String supplierName;

  OrderInfo({
    required this.id,
    required this.customerName,
    required this.inventoryNo,
    required this.supplierName,
  });
}

class DeliveryDriver {
  final String name;
  final int assignedOrders;
  final String image;

  DeliveryDriver({
    required this.name,
    required this.assignedOrders,
    required this.image,
  });
}

// ====================== PAGE ======================

class StockOutPage extends StatefulWidget {
  const StockOutPage({super.key});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  final PageController _pageController = PageController();
  int _currentTab = 0;

  final List<OrderInfo> _orders = [
    OrderInfo(
      id: 26,
      customerName: 'Ahmad Nizar',
      inventoryNo: 1,
      supplierName: 'Ahmad Nizar',
    ),
    OrderInfo(
      id: 27,
      customerName: 'Saed Rimawi',
      inventoryNo: 1,
      supplierName: 'Saed Rimawi',
    ),
    OrderInfo(
      id: 30,
      customerName: 'Akef Al Asmar',
      inventoryNo: 2,
      supplierName: 'Akef Al Asmar',
    ),
    OrderInfo(
      id: 28,
      customerName: 'Nizar Fares',
      inventoryNo: 2,
      supplierName: 'Nizar Fares',
    ),
    OrderInfo(
      id: 20,
      customerName: 'Eyas Barghouthi',
      inventoryNo: 1,
      supplierName: 'Eyas Barghouthi',
    ),
  ];

  final List<DeliveryDriver> _drivers = [
    DeliveryDriver(
      name: 'Rami Rimawi',
      assignedOrders: 8,
      image: "assets/images/rami.jpg",
    ),
    DeliveryDriver(
      name: 'Mohammad Assi',
      assignedOrders: 0,
      image: "assets/images/assi.jpg",
    ),
    DeliveryDriver(
      name: 'Ameer Yasin',
      assignedOrders: 2,
      image: "assets/images/ameer.jpg",
    ),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentTab = i),
                children: [
                  _PendingSection(orders: _orders),
                  _PreparingSection(orders: _orders),
                  _PreparedSection(orders: _orders),
                  _DeliverySection(drivers: _drivers),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _StockOutStatusBar(
                currentIndex: _currentTab,
                onChanged: _onTabSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== PENDING SECTION ======================

class _PendingSection extends StatelessWidget {
  final List<OrderInfo> orders;
  const _PendingSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Customer Name',
            right: '',
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = orders[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsPage(
                          customerName: o.customerName,
                          items: [
                            OrderItem('Hand Shower', 'GROHE', 'cm', 1),
                            OrderItem(
                              'Freestanding Bathtub',
                              'Royal',
                              'pcs',
                              1,
                            ),
                            OrderItem('Wall-Hung Toilet', 'GROHE', 'cm', 1),
                          ],
                        ),
                      ),
                    );
                  },
                  child: _OrderCard(left: '${o.id}', middle: o.customerName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PREPARING SECTION ======================

class _PreparingSection extends StatelessWidget {
  final List<OrderInfo> orders;
  const _PreparingSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preparing Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Customer Name',
            right: 'Inventory #',
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = orders[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreparingOrderDetailsPage(
                          customerName: o.customerName,
                          items: [
                            OrderItem("Hand Shower", "GROHE", "cm", 1),
                            OrderItem(
                              "Freestanding Bathtub",
                              "Royal",
                              "pcs",
                              1,
                            ),
                            OrderItem("Kitchen Sink", "Royal", "cm", 1),
                          ],
                          preparedByName: "Ayman Al Asmar",
                          preparedByImage: "assets/images/ayman.jpg",
                        ),
                      ),
                    );
                  },
                  child: _OrderCard(
                    left: '${o.id}',
                    middle: o.customerName,
                    right: '${o.inventoryNo}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PREPARED SECTION ======================

class _PreparedSection extends StatelessWidget {
  final List<OrderInfo> orders;
  const _PreparedSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prepared Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Supplier Name',
            right: 'Inventory #',
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = orders[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreparedOrderDetailsPage(
                          customerName: o.customerName,
                          preparedByName: "Ayman Al Asmar",
                          preparedByImage: "assets/images/ayman.jpg",
                          items: [
                            OrderItem("Hand Shower", "GROHE", "cm", 1),
                            OrderItem(
                              "Freestanding Bathtub",
                              "Royal",
                              "pcs",
                              1,
                            ),
                            OrderItem("Wall-Hung Toilet", "GROHE", "cm", 1),
                          ],
                        ),
                      ),
                    );
                  },
                  child: _OrderCard(
                    left: '${o.id}',
                    middle: o.supplierName,
                    right: '${o.inventoryNo}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== DELIVERY SECTION ======================

class _DeliverySection extends StatelessWidget {
  final List<DeliveryDriver> drivers;

  const _DeliverySection({required this.drivers});

  String _getDriverImage(String name) {
    if (name == 'Rami Rimawi') return "assets/images/rami.jpg";
    if (name == 'Mohammad Assi') return "assets/images/assi.jpg";
    if (name == 'Ameer Yasin') return "assets/images/ameer.jpg";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Delivery',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final d = drivers[i];
                final img = _getDriverImage(d.name);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverOrdersPage(
                          driverName: d.name,
                          assignedOrders: [
                            {
                              "id": 8,
                              "customer": "Rami Rimawi",
                              "items": [
                                OrderItem("Hand Shower", "GROHE", "cm", 1),
                                OrderItem("Kitchen Sink", "Royal", "pcs", 2),
                              ],
                            },
                            {
                              "id": 22,
                              "customer": "Nizar Ahamd",
                              "items": [
                                OrderItem("Wall-Hung Toilet", "GROHE", "cm", 1),
                                OrderItem(
                                  "Freestanding Bathtub",
                                  "Royal",
                                  "pcs",
                                  1,
                                ),
                              ],
                            },
                          ],
                        ),
                      ),
                    );
                  },
                  child: _DeliveryCard(driver: d, imgPath: img),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== SMALL WIDGETS ======================

class _HeaderRow extends StatelessWidget {
  final String left, middle, right;
  const _HeaderRow({
    required this.left,
    required this.middle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  middle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: right.isEmpty
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        right,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: Colors.white24),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String left, middle;
  final String? right;

  const _OrderCard({required this.left, required this.middle, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Center(
              child: Text(
                left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              middle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (right != null)
            SizedBox(
              width: 50,
              child: Text(
                right!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryDriver driver;
  final String imgPath;

  const _DeliveryCard({required this.driver, required this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundImage: AssetImage(driver.image)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              driver.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Container(
            width: 70,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgDark.withOpacity(.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${driver.assignedOrders}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Assign',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockOutStatusBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onChanged;

  const _StockOutStatusBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _StatusData(Icons.photo_camera_back_outlined, 'Pending'),
      _StatusData(Icons.chair_alt_rounded, 'Preparing'),
      _StatusData(Icons.check_box_rounded, 'Prepared'),
      _StatusData(Icons.local_shipping_rounded, 'Delivery'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          final data = items[i];

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      data.icon,
                      size: 20,
                      color: active ? AppColors.gold : Colors.white,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      style: TextStyle(
                        color: active ? AppColors.gold : Colors.white,
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatusData {
  final IconData icon;
  final String label;
  const _StatusData(this.icon, this.label);
}

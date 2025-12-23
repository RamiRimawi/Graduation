class OrderItem {
  final int productId; // Database ID
  final String name;
  final String brand;
  final String unit; // cm, pcs, meter ...
  int qty;

  OrderItem(this.productId, this.name, this.brand, this.unit, this.qty);
}

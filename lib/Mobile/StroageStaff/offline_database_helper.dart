import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class OfflineDatabaseHelper {
  static final OfflineDatabaseHelper instance = OfflineDatabaseHelper._init();
  static Database? _database;

  OfflineDatabaseHelper._init() {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('staff_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Cached orders
    await db.execute('''
      CREATE TABLE cached_orders (
        customer_order_id INTEGER PRIMARY KEY,
        customer_name TEXT NOT NULL,
        order_status TEXT,
        product_count INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached products for an order
    await db.execute('''
      CREATE TABLE cached_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        brand_name TEXT,
        unit_name TEXT,
        quantity INTEGER NOT NULL,
        inventory_id INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached batches/allocations
    await db.execute('''
      CREATE TABLE cached_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        batch_id INTEGER,
        inventory_id INTEGER,
        storage_location TEXT,
        available_qty INTEGER,
        prepared_qty INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached available batches (for batch picker)
    await db.execute('''
      CREATE TABLE cached_batches (
        batch_id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        inventory_id INTEGER,
        quantity INTEGER NOT NULL,
        storage_location TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Pending actions queue
    await db.execute('''
      CREATE TABLE pending_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        customer_order_id INTEGER NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  // ========== CACHED ORDERS ==========
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final order in orders) {
      batch.insert('cached_orders', {
        'customer_order_id': order['id'],
        'customer_name': order['name'],
        'order_status': 'Preparing',
        'product_count': order['products'],
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final db = await database;
    final results = await db.query(
      'cached_orders',
      orderBy: 'customer_order_id ASC',
    );

    return results
        .map(
          (row) => {
            'id': row['customer_order_id'],
            'name': row['customer_name'],
            'products': row['product_count'],
          },
        )
        .toList();
  }

  Future<void> clearCachedOrder(int orderId) async {
    final db = await database;
    await db.delete(
      'cached_orders',
      where: 'customer_order_id = ?',
      whereArgs: [orderId],
    );
    await db.delete(
      'cached_products',
      where: 'customer_order_id = ?',
      whereArgs: [orderId],
    );
    await db.delete(
      'cached_allocations',
      where: 'customer_order_id = ?',
      whereArgs: [orderId],
    );
  }

  // ========== CACHED PRODUCTS ==========
  Future<void> cacheProducts(
    int orderId,
    List<Map<String, dynamic>> products,
  ) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Clear old products for this order
    batch.delete(
      'cached_products',
      where: 'customer_order_id = ?',
      whereArgs: [orderId],
    );

    for (final product in products) {
      batch.insert('cached_products', {
        'customer_order_id': orderId,
        'product_id': product['product_id'],
        'product_name': product['name'],
        'brand_name': product['brand'],
        'unit_name': product['unit'],
        'quantity': product['quantity'],
        'inventory_id': product['inventory_id'],
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedProducts(int orderId) async {
    final db = await database;
    final results = await db.query(
      'cached_products',
      where: 'customer_order_id = ?',
      whereArgs: [orderId],
    );

    return results
        .map(
          (row) => {
            'product_id': row['product_id'],
            'name': row['product_name'],
            'brand': row['brand_name'],
            'unit': row['unit_name'],
            'quantity': row['quantity'],
            'inventory_id': row['inventory_id'],
            'allocations': <Map<String, dynamic>>[],
          },
        )
        .toList();
  }

  // ========== CACHED ALLOCATIONS ==========
  Future<void> cacheAllocations(
    int orderId,
    int productId,
    List<Map<String, dynamic>> allocations,
  ) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Clear old allocations
    batch.delete(
      'cached_allocations',
      where: 'customer_order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );

    for (final alloc in allocations) {
      batch.insert('cached_allocations', {
        'customer_order_id': orderId,
        'product_id': productId,
        'batch_id': alloc['batch_id'],
        'inventory_id': alloc['inventory_id'],
        'storage_location': alloc['storage_location'],
        'available_qty': alloc['available_qty'],
        'prepared_qty': alloc['prepared_qty'],
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedAllocations(
    int orderId,
    int productId,
  ) async {
    final db = await database;
    final results = await db.query(
      'cached_allocations',
      where: 'customer_order_id = ? AND product_id = ?',
      whereArgs: [orderId, productId],
    );

    return results
        .map(
          (row) => {
            'batch_id': row['batch_id'],
            'inventory_id': row['inventory_id'],
            'storage_location': row['storage_location'],
            'available_qty': row['available_qty'],
            'prepared_qty': row['prepared_qty'],
          },
        )
        .toList();
  }

  // ========== CACHED BATCHES ==========
  Future<void> cacheBatches(
    int productId,
    List<Map<String, dynamic>> batches,
  ) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final b in batches) {
      batch.insert('cached_batches', {
        'batch_id': b['batch_id'],
        'product_id': productId,
        'inventory_id': b['inventory_id'],
        'quantity': b['quantity'],
        'storage_location': b['storage_location_descrption'],
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedBatches(
    int productId, {
    int? inventoryId,
  }) async {
    final db = await database;

    String where = 'product_id = ?';
    List<dynamic> whereArgs = [productId];

    if (inventoryId != null) {
      where += ' AND inventory_id = ?';
      whereArgs.add(inventoryId);
    }

    final results = await db.query(
      'cached_batches',
      where: where,
      whereArgs: whereArgs,
    );

    return results
        .map(
          (row) => {
            'batch_id': row['batch_id'],
            'quantity': row['quantity'],
            'storage_location_descrption': row['storage_location'],
            'inventory_id': row['inventory_id'],
          },
        )
        .toList();
  }

  // ========== PENDING ACTIONS QUEUE ==========
  Future<int> addPendingAction({
    required String actionType,
    required int customerId,
    required String payload,
  }) async {
    final db = await database;
    return await db.insert('pending_actions', {
      'action_type': actionType,
      'customer_order_id': customerId,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return await db.query('pending_actions', orderBy: 'created_at ASC');
  }

  Future<void> deletePendingAction(int id) async {
    final db = await database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_actions SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // ========== UTILITIES ==========
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_orders');
    await db.delete('cached_products');
    await db.delete('cached_allocations');
    await db.delete('cached_batches');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

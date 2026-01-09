import random
from datetime import datetime, timedelta

# Configuration
NUM_ORDERS = 500
NUM_NORMAL_NO_UPDATE = 300  # Orders 1-300
NUM_NORMAL_WITH_UPDATE = 100  # Orders 301-400
NUM_SPLIT = 100  # Orders 401-500

# Staff IDs
SALES_REPS = [511111111, 522222222, 533333333, 544444444, 555555555]
DELIVERY_DRIVERS = [411111111, 422222222, 433333333, 444444444]
STORAGE_STAFF = [
    ('Nabil Yousef', 311111111, 1),
    ('Saleh Ahmad', 322222222, 1),
    ('Fadi Hassan', 333333333, 1),
    ('Tariq Said', 344444444, 2),
    ('Rami Nasser', 355555555, 2),
    ('Adel Mahmoud', 366666666, 2),
    ('Walid Habib', 377777777, 3),
    ('Karim Farah', 388888888, 3),
    ('Samir Aziz', 399999999, 3)
]
MANAGER_ID = 211111111
ACCOUNTANT_ID = 111111111

# Product IDs (70 products available: 1-10 toilets, 11-20 sinks, 21-30 faucets, etc.)
PRODUCT_IDS = list(range(1, 71))

# Product prices (simplified mapping)
def get_product_price(product_id):
    """Get product price based on ID"""
    prices = {
        range(1, 11): [200, 220, 190, 230, 250, 210, 195, 240, 225, 260],  # Toilets
        range(11, 21): [160, 170, 150, 165, 180, 180, 155, 180, 170, 170],  # Sinks
        range(21, 31): [110, 170, 100, 140, 200, 125, 130, 150, 115, 140],  # Faucets
        range(31, 41): [110, 130, 115, 125, 95, 150, 130, 95, 105, 190],  # Faucets (more)
        range(41, 51): [95, 420, 210, 230, 420, 430, 430, 210, 440, 410],  # Showers
        range(51, 61): [400, 380, 380, 410, 390, 390, 410, 380, 420, 395],  # Bathtubs
        range(61, 71): [30, 35, 35, 45, 45, 30, 50, 45, 30, 50]  # Accessories
    }
    
    for price_range, price_list in prices.items():
        if product_id in price_range:
            return price_list[product_id - min(price_range)]
    return 100  # Default

# Generate random order date
start_date = datetime(2025, 11, 1)
end_date = datetime(2026, 1, 5)

def random_date(start, end):
    """Generate a random datetime between start and end"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    random_seconds = random.randint(0, 86400)
    return start + timedelta(days=random_days, seconds=random_seconds)

def format_timestamp(dt):
    """Format datetime for SQL"""
    return dt.strftime('%Y-%m-%d %H:%M:%S')

# Generate customer orders
def generate_customer_order_sql():
    orders = []
    order_details = []  # Store for later use
    
    for order_num in range(1, NUM_ORDERS + 1):
        customer_id = 100000000 + order_num
        
        # Determine order type
        is_updated = 301 <= order_num <= 400
        is_split = order_num > 400
        
        # Generate 3 random products for this order
        products = random.sample(PRODUCT_IDS, 3)
        quantities = [random.randint(1, 3) for _ in range(3)]
        
        # Calculate costs
        total_cost = sum(get_product_price(p) * q for p, q in zip(products, quantities))
        tax_percent = 16
        total_balance = total_cost * 1.16
        
        # Generate dates
        order_date = random_date(start_date, end_date)
        delivery_date = order_date + timedelta(days=random.randint(1, 3), hours=random.randint(0, 12))
        
        # Assign staff
        sales_rep = SALES_REPS[order_num % len(SALES_REPS)]
        delivery_driver = DELIVERY_DRIVERS[order_num % len(DELIVERY_DRIVERS)]
        
        if is_split:
            last_action_by = 'Multiple Staff'
        else:
            staff_name, staff_id, inv_id = STORAGE_STAFF[order_num % len(STORAGE_STAFF)]
            last_action_by = staff_name
        
        # Update info
        update_action = 'NULL'
        update_description = 'NULL'
        if is_updated:
            update_action = "'Quantity Update'"
            descriptions = [
                "'Customer requested quantity changes after order placement'",
                "'Manager approved quantity modifications'",
                "'Adjusted quantities per customer request'",
                "'Order quantities updated by storage manager'",
                "'Reduced quantities due to stock availability'",
                "'Customer increased order quantities'",
                "'Manager approved order modifications'",
                "'Order updated after customer confirmation'",
                "'Quantities adjusted per inventory availability'",
                "'Customer requested additional items'"
            ]
            update_description = descriptions[(order_num - 301) % len(descriptions)]
        
        # Build SQL
        order_sql = f"({customer_id}, {total_cost:.2f}, {tax_percent}, {total_balance:.2f}, " \
                   f"'{format_timestamp(order_date)}', 'Delivered', NULL, " \
                   f"{sales_rep}, {delivery_driver}, NULL, {MANAGER_ID}, {ACCOUNTANT_ID}, " \
                   f"'{last_action_by}', '{format_timestamp(delivery_date)}', 0, {update_action}, {update_description})"
        
        orders.append(order_sql)
        
        # Store order details for description table
        order_details.append({
            'order_num': order_num,
            'customer_id': customer_id,
            'products': products,
            'quantities': quantities,
            'total_cost': total_cost,
            'delivery_date': delivery_date,
            'last_action_by': last_action_by,
            'is_updated': is_updated,
            'is_split': is_split
        })
    
    return orders, order_details

# Generate customer_order_description SQL
def generate_order_description_sql(order_details):
    descriptions = []
    
    for detail in order_details:
        order_num = detail['order_num']
        products = detail['products']
        quantities = detail['quantities']
        delivery_date = detail['delivery_date']
        last_action_by = detail['last_action_by']
        is_updated = detail['is_updated']
        
        for i, (product_id, quantity) in enumerate(zip(products, quantities)):
            # For updated orders, delivered quantity differs from original
            if is_updated:
                original_qty = quantity
                # Randomly increase or decrease
                if random.random() > 0.5:
                    delivered_qty = quantity + random.randint(1, 2)
                else:
                    delivered_qty = max(1, quantity - random.randint(0, 1))
                updated_qty = delivered_qty
            else:
                original_qty = quantity
                delivered_qty = quantity
                updated_qty = 'NULL'
            
            price = get_product_price(product_id)
            total_price = price * delivered_qty
            
            desc_sql = f"({order_num}, {product_id}, {original_qty}, {delivered_qty}, " \
                      f"{total_price:.2f}, '{format_timestamp(delivery_date)}', " \
                      f"'{last_action_by}', '{format_timestamp(delivery_date)}', {updated_qty})"
            
            descriptions.append(desc_sql)
    
    return descriptions

# Generate customer_order_inventory SQL
def generate_order_inventory_sql(order_details):
    inventories = []
    batch_id = 1
    
    for detail in order_details:
        order_num = detail['order_num']
        products = detail['products']
        is_split = detail['is_split']
        delivery_date = detail['delivery_date']
        
        if is_split:
            # Split order: distribute products across 2-3 inventories
            num_inventories = random.randint(2, 3)
            
            for i, product_id in enumerate(products):
                # Determine which inventory for this product
                if num_inventories == 2:
                    inv_assignments = [1, 2] if i < 2 else [1, 2]
                else:
                    inv_assignments = [1, 2, 3]
                
                selected_inv = inv_assignments[i % len(inv_assignments)]
                
                # Get staff from that inventory
                inv_staff = [s for s in STORAGE_STAFF if s[2] == selected_inv]
                staff_name, staff_id, _ = random.choice(inv_staff)
                
                # Get quantity from order details
                # Find matching description
                quantity = None
                for desc in generate_order_description_sql([detail]):
                    if f"({order_num}, {product_id}," in desc:
                        # Extract delivered quantity
                        parts = desc.split(',')
                        quantity = int(parts[3].strip())
                        break
                
                if quantity is None:
                    quantity = random.randint(2, 5)
                
                inv_sql = f"({order_num}, {product_id}, {selected_inv}, {batch_id}, " \
                         f"{quantity}, {staff_id}, {quantity}, " \
                         f"'{staff_name}', '{format_timestamp(delivery_date)}')"
                
                inventories.append(inv_sql)
                batch_id = (batch_id % 150) + 1
        else:
            # Normal order: all products from one inventory
            staff_name, staff_id, inv_id = STORAGE_STAFF[order_num % len(STORAGE_STAFF)]
            
            for product_id in products:
                # Match quantity from description
                quantity = random.randint(1, 3)
                
                inv_sql = f"({order_num}, {product_id}, {inv_id}, {batch_id}, " \
                         f"{quantity}, {staff_id}, {quantity}, " \
                         f"'{staff_name}', '{format_timestamp(delivery_date)}')"
                
                inventories.append(inv_sql)
                batch_id = (batch_id % 150) + 1
    
    return inventories

# Main generation
def main():
    print("Generating 500 customer orders...")
    
    # Generate orders
    orders, order_details = generate_customer_order_sql()
    descriptions = generate_order_description_sql(order_details)
    inventories = generate_order_inventory_sql(order_details)
    
    # Write to file
    with open('customerorderdata.sql', 'w', encoding='utf-8') as f:
        f.write("-- Customer Order Demo Data - 500 Orders\n")
        f.write("-- Orders 1-300: Normal orders (no updates)\n")
        f.write("-- Orders 301-400: Normal orders (WITH updates)\n")
        f.write("-- Orders 401-500: Split orders (distributed across inventories)\n\n")
        
        f.write("-- ============================================\n")
        f.write("-- CUSTOMER ORDERS (500 total)\n")
        f.write("-- ============================================\n")
        f.write("INSERT INTO customer_order (customer_id, total_cost, tax_percent, total_balance, ")
        f.write("order_date, order_status, customer_signature, sales_rep_id, delivered_by_id, ")
        f.write("prepared_by_id, managed_by_id, accountant_id, last_action_by, last_action_time, ")
        f.write("discount_value, update_action, update_description) VALUES\n")
        
        for i, order in enumerate(orders):
            if i < len(orders) - 1:
                f.write(order + ",\n")
            else:
                f.write(order + ";\n\n")
        
        f.write("-- ============================================\n")
        f.write("-- CUSTOMER ORDER DESCRIPTIONS (1500 total - 3 products per order)\n")
        f.write("-- ============================================\n")
        f.write("INSERT INTO customer_order_description (customer_order_id, product_id, quantity, ")
        f.write("delivered_quantity, total_price, delivered_date, last_action_by, last_action_time, ")
        f.write("updated_quantity) VALUES\n")
        
        for i, desc in enumerate(descriptions):
            if i < len(descriptions) - 1:
                f.write(desc + ",\n")
            else:
                f.write(desc + ";\n\n")
        
        f.write("-- ============================================\n")
        f.write("-- CUSTOMER ORDER INVENTORY (1500+ total)\n")
        f.write("-- ============================================\n")
        f.write("INSERT INTO customer_order_inventory (customer_order_id, product_id, inventory_id, ")
        f.write("batch_id, quantity, prepared_by, prepared_quantity, last_action_by, last_action_time) VALUES\n")
        
        for i, inv in enumerate(inventories):
            if i < len(inventories) - 1:
                f.write(inv + ",\n")
            else:
                f.write(inv + ";\n")
    
    print(f"Generated {len(orders)} orders")
    print(f"Generated {len(descriptions)} order descriptions")
    print(f"Generated {len(inventories)} inventory records")
    print("File saved as: customerorderdata.sql")

if __name__ == "__main__":
    main()

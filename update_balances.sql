-- ========================================
-- Update Supplier Creditor Balance
-- ========================================
-- Creditor Balance = Total amount we owe to supplier (only for received orders)
-- Formula: Sum of received supplier orders - Sum of all payments to supplier

UPDATE supplier s
SET creditor_balance = (
    -- Calculate total received orders from this supplier
    COALESCE((
        SELECT SUM(total_balance)
        FROM supplier_order so
        WHERE so.supplier_id = s.supplier_id
        AND so.order_status = 'Delivered'
    ), 0)
    -
    -- Subtract total payments made to this supplier
    COALESCE((
        SELECT SUM(amount)
        FROM outgoing_payment op
        WHERE op.supplier_id = s.supplier_id
    ), 0)
);


-- ========================================
-- Update Customer Debt Balance
-- ========================================
-- Debt Balance = Total amount customer owes to us (only for delivered orders)
-- Formula: Sum of delivered customer orders - Sum of all payments from customer

UPDATE customer c
SET balance_debit = (
    -- Calculate total delivered orders for this customer
    COALESCE((
        SELECT SUM(total_balance)
        FROM customer_order co
        WHERE co.customer_id = c.customer_id
        AND co.order_status = 'Delivered'
    ), 0)
    -
    -- Subtract total payments received from this customer
    COALESCE((
        SELECT SUM(amount)
        FROM incoming_payment ip
        WHERE ip.customer_id = c.customer_id
    ), 0)
);


-- ========================================
-- Verification Queries
-- ========================================
-- Run these to verify the updates

-- Check supplier balances (only received orders)
SELECT 
    s.supplier_id,
    s.name,
    s.creditor_balance,
    COALESCE(SUM(so.total_balance), 0) as total_received_orders,
    COALESCE((SELECT SUM(amount) FROM outgoing_payment op WHERE op.supplier_id = s.supplier_id), 0) as total_payments,
    (COALESCE(SUM(so.total_balance), 0) - COALESCE((SELECT SUM(amount) FROM outgoing_payment op WHERE op.supplier_id = s.supplier_id), 0)) as calculated_balance
FROM supplier s
LEFT JOIN supplier_order so ON s.supplier_id = so.supplier_id 
    AND so.order_status = 'Delivered'
GROUP BY s.supplier_id, s.name, s.creditor_balance
ORDER BY s.supplier_id;

-- Check customer balances (only delivered orders)
SELECT 
    c.customer_id,
    c.name,
    c.balance_debit,
    COALESCE(SUM(co.total_balance), 0) as total_delivered_orders,
    COALESCE((SELECT SUM(amount) FROM incoming_payment ip WHERE ip.customer_id = c.customer_id), 0) as total_payments,
    (COALESCE(SUM(co.total_balance), 0) - COALESCE((SELECT SUM(amount) FROM incoming_payment ip WHERE ip.customer_id = c.customer_id), 0)) as calculated_balance
FROM customer c
LEFT JOIN customer_order co ON c.customer_id = co.customer_id 
    AND co.order_status = 'Delivered'
GROUP BY c.customer_id, c.name, c.balance_debit
ORDER BY c.customer_id;


-- =====================================================
-- BANKS AND BRANCHES
-- =====================================================

INSERT INTO "banks" (bank_name) VALUES
('Bank of Palestine'),
('Quds Bank'),
('Arab Bank'),
('Cairo Amman Bank');

INSERT INTO "branches" (bank_id, address) VALUES
((SELECT bank_id FROM "banks" WHERE bank_name = 'Bank of Palestine' LIMIT 1), 'Ramallah Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Bank of Palestine' LIMIT 1), 'Al-Bireh Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Quds Bank' LIMIT 1), 'Nablus Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Quds Bank' LIMIT 1), 'Hebron Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Arab Bank' LIMIT 1), 'Ramallah Main Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Arab Bank' LIMIT 1), 'Bethlehem Branch'),
((SELECT bank_id FROM "banks" WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), 'Nablus Central');

-- =====================================================
-- ACCOUNTANT (1 Manager Accountant)
-- =====================================================

INSERT INTO accountant 
(accountant_id, name, mobile_number, telephone_number, address, last_action_by, last_action_time)
VALUES
(407392118, 'Ahmad Al-Masri', '0599001111', '022345600', 'Ramallah - City Center', 'system', NOW());

-- =====================================================
-- STORAGE MANAGER (1 Manager)
-- =====================================================

INSERT INTO storage_manager
(storage_manager_id, name, mobile_number, telephone_number, address, last_action_by, last_action_time)
VALUES
(406772901, 'Ameer Khalil', '0599441122', '022345606', 'Ramallah - Warehouse District', 'system', NOW());

-- =====================================================
-- STORAGE STAFF (Multiple staff members)
-- =====================================================

INSERT INTO storage_staff
(storage_staff_id, name, mobile_number, telephone_number, address, last_action_by, last_action_time)
VALUES
(409552887, 'Fadi Salman', '0599005566', '022345607', 'Ramallah - Al-Irsal', 'system', NOW()),
(408661299, 'Yousef Mansour', '0599337788', '022345608', 'Nablus - Al-Madina', 'system', NOW()),
(407881234, 'Majed Awad', '0599448899', '022345609', 'Hebron - Industrial Zone', 'system', NOW());

-- =====================================================
-- DELIVERY DRIVER (Multiple drivers)
-- =====================================================

INSERT INTO delivery_driver
(delivery_driver_id, name, mobile_number, telephone_number, address, last_action_by, last_action_time)
VALUES
(408113200, 'Kareem Jaber', '0599556677', '022345604', 'Hebron - Haret Al-Sheikh', 'system', NOW()),
(409001122, 'Omar Zaher', '0599445588', '022345605', 'Bethlehem - Beit Jala', 'system', NOW()),
(407223344, 'Malik Daoud', '0599667788', '022345612', 'Ramallah - Northern District', 'system', NOW());

-- =====================================================
-- SALES REP CITY
-- =====================================================

INSERT INTO sales_rep_city (name, last_action_by, last_action_time) VALUES
('Ramallah', 'system', NOW()),
('Nablus', 'system', NOW()),
('Hebron', 'system', NOW()),
('Bethlehem', 'system', NOW()),
('Jenin', 'system', NOW());

-- =====================================================
-- SALES REPRESENTATIVE (Multiple sales reps)
-- =====================================================

INSERT INTO sales_representative
(sales_rep_id, sales_rep_city, name, mobile_number, telephone_number, email, last_action_by, last_action_time)
VALUES
(409882311, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Ramallah' LIMIT 1), 'Rami Khalil', '0599233344', '022345602', 'rami@sales.ps', 'system', NOW()),
(408771234, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Nablus' LIMIT 1), 'Ayman Shobaki', '0599882211', '022345603', 'ayman@sales.ps', 'system', NOW()),
(407556789, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Hebron' LIMIT 1), 'Hani Mustafa', '0599990011', '042345614', 'hani@sales.ps', 'system', NOW());

-- =====================================================
-- USER ACCOUNTS FOR ACTORS (PASSWORD = '1234')
-- =====================================================

-- Accountant account (Manager)
INSERT INTO user_account_accountant (accountant_id, password, added_by, added_time, is_active) VALUES
(407392118, '1234', 'system', NOW(), 'yes');

-- Storage Manager account
INSERT INTO user_account_storage_manager (storage_manager_id, password, is_active, added_by, added_time) VALUES
(406772901, '1234', 'yes', 'system', NOW());

-- Storage Staff accounts
INSERT INTO user_account_storage_staff (storage_staff_id, password, is_active, added_by, added_time) VALUES
(409552887, '1234', 'yes', 'system', NOW()),
(408661299, '1234', 'yes', 'system', NOW()),
(407881234, '1234', 'yes', 'system', NOW());

-- Delivery Driver accounts
INSERT INTO user_account_delivery_driver (delivery_driver_id, password, is_active, added_by, added_time) VALUES
(408113200, '1234', 'yes', 'system', NOW()),
(409001122, '1234', 'yes', 'system', NOW()),
(407223344, '1234', 'yes', 'system', NOW());

-- Sales Representative accounts
INSERT INTO user_account_sales_rep (sales_rep_id, password, is_active, added_by, added_time) VALUES
(409882311, '1234', 'yes', 'system', NOW()),
(408771234, '1234', 'yes', 'system', NOW()),
(407556789, '1234', 'yes', 'system', NOW());

-- =====================================================
-- SUPPLIER CITY
-- =====================================================

INSERT INTO supplier_city (name, last_action_by, last_action_time) VALUES
('Ramallah', 'system', NOW()),
('Nablus', 'system', NOW()),
('Hebron', 'system', NOW()),
('Bethlehem', 'system', NOW()),
('Jenin', 'system', NOW()),
('Tulkarm', 'system', NOW()),
('Qalqilya', 'system', NOW()),
('Jericho', 'system', NOW());

-- =====================================================
-- SUPPLIER CATEGORY
-- =====================================================

INSERT INTO supplier_category (name, last_action_by, last_action_time) VALUES
('Pipes & Fittings', 'system', NOW()),
('Valves & Mixers', 'system', NOW()),
('Sanitary Ware', 'system', NOW()),
('Bathroom Accessories', 'system', NOW()),
('Heating Systems', 'system', NOW()),
('Water Pumps', 'system', NOW());

-- =====================================================
-- SUPPLIER (10 Suppliers)
-- =====================================================

INSERT INTO supplier 
(supplier_id, name, mobile_number, telephone_number, supplier_city, address, email, creditor_balance, supplier_category_id, last_action_by, last_action_time)
VALUES
(407392001, 'GROHE International', '0599001122', '022345678', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Masyoun', 'grohe@sanitary.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system', NOW()),
(407392002, 'Firat Plastic Co.', '0599553322', '092334455', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Industrial Area', 'firat@pipes.ps', 1200, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system', NOW()),
(407392003, 'Hansgrohe Middle East', '0599887766', '042221199', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Hebron' LIMIT 1), 'Hebron - City Center', 'hans@ware.ps', 300, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system', NOW()),
(407392004, 'Kalde Pipes Ltd.', '0599332211', '022556677', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Bireh', 'kalde@fittings.ps', 1800, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system', NOW()),
(407392005, 'Valtec Trading', '0599123456', '092445566', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Jenin' LIMIT 1), 'Jenin - Main Street', 'valtec@trade.ps', 2500, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Valves & Mixers' LIMIT 1), 'system', NOW()),
(407392006, 'Delta Pumps & Heaters', '0599234567', '092556677', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Tulkarm' LIMIT 1), 'Tulkarm - Industrial Park', 'delta@pumps.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Water Pumps' LIMIT 1), 'system', NOW()),
(407392007, 'Ideal Standard Co.', '0599345678', '022667788', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Bethlehem' LIMIT 1), 'Bethlehem - Star Street', 'ideal@standard.ps', 950, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system', NOW()),
(407392008, 'Roca Sanitary', '0599456789', '042778899', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Qalqilya' LIMIT 1), 'Qalqilya - Market Area', 'roca@sanitary.ps', 500, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system', NOW()),
(407392009, 'Wavin Pipes Systems', '0599567890', '022889900', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Jericho' LIMIT 1), 'Jericho - Highway Road', 'wavin@pipes.ps', 3200, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system', NOW()),
(407392010, 'Brass Master Fittings', '0599678901', '092990011', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Eastern Quarter', 'brass@fittings.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system', NOW());

-- Supplier user accounts
INSERT INTO user_account_supplier (supplier_id, password, is_active, added_by, added_time) VALUES
(407392001, '1234', 'yes', 'system', NOW()),
(407392002, '1234', 'yes', 'system', NOW()),
(407392003, '1234', 'yes', 'system', NOW()),
(407392004, '1234', 'yes', 'system', NOW()),
(407392005, '1234', 'yes', 'system', NOW()),
(407392006, '1234', 'yes', 'system', NOW()),
(407392007, '1234', 'yes', 'system', NOW()),
(407392008, '1234', 'yes', 'system', NOW()),
(407392009, '1234', 'yes', 'system', NOW()),
(407392010, '1234', 'yes', 'system', NOW());

-- =====================================================
-- CUSTOMER CITY
-- =====================================================

INSERT INTO customer_city (name, last_action_by, last_action_time) VALUES
('Ramallah', 'system', NOW()),
('Nablus', 'system', NOW()),
('Hebron', 'system', NOW()),
('Bethlehem', 'system', NOW()),
('Jenin', 'system', NOW()),
('Tulkarm', 'system', NOW());

-- =====================================================
-- CUSTOMER QUARTERS
-- =====================================================

INSERT INTO customer_quarters (name, customer_city, last_action_by, last_action_time) VALUES
('Al-Masyoun', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system', NOW()),
('City Center', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system', NOW()),
('Industrial Zone', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system', NOW()),
('Old City', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system', NOW()),
('Al-Salam Area', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'system', NOW()),
('Al-Bireh', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system', NOW()),
('Eastern Quarter', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system', NOW()),
('Star Street', (SELECT customer_city_id FROM customer_city WHERE name = 'Bethlehem' LIMIT 1), 'system', NOW()),
('Al-Amal District', (SELECT customer_city_id FROM customer_city WHERE name = 'Jenin' LIMIT 1), 'system', NOW()),
('Western Area', (SELECT customer_city_id FROM customer_city WHERE name = 'Tulkarm' LIMIT 1), 'system', NOW());

-- =====================================================
-- CUSTOMER (15 Customers)
-- =====================================================

INSERT INTO customer
(customer_id, name, mobile_number, telephone_number, customer_city, address, latitude_location, longitude_location, email, balance_debit, sales_rep_id, last_action_by, last_action_time)
VALUES
(409223118, 'Golden Pipes Workshop', '0599345678', '022345678', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Masyoun', 31.8981, 35.2042, 'goldpipes@work.ps', 0, 409882311, 'system', NOW()),
(408554321, 'Al-Barq Contracting', '0599543211', '092345600', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Industrial Zone', 32.2215, 35.2544, 'barq@contract.ps', 850, 408771234, 'system', NOW()),
(407667655, 'Modern Sanitary Co.', '0599776655', '042334455', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'Hebron - Al-Salam', 31.5321, 35.1054, 'modern@sanitary.ps', 0, 407556789, 'system', NOW()),
(406900221, 'Universal Plumbing', '0599002211', '022556677', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - City Center', 31.9044, 35.2131, 'uniplumb@services.ps', 1200, 409882311, 'system', NOW()),
(408123456, 'Prime Building Materials', '0599131415', '042345617', (SELECT customer_city_id FROM customer_city WHERE name = 'Bethlehem' LIMIT 1), 'Bethlehem - Star Street', 31.7054, 35.2024, 'prime@building.ps', 500, 409882311, 'system', NOW()),
(407789012, 'Excellence Hardware', '0599151617', '092345618', (SELECT customer_city_id FROM customer_city WHERE name = 'Jenin' LIMIT 1), 'Jenin - Al-Amal', 32.4607, 35.2906, 'excellence@hardware.ps', 0, 408771234, 'system', NOW()),
(409445566, 'Al-Noor Sanitary Ware', '0599181920', '022345619', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Bireh', 31.9100, 35.2047, 'alnoor@sanitary.ps', 2100, 409882311, 'system', NOW()),
(408667788, 'Star Plumbing Co.', '0599212223', '092345620', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Eastern Quarter', 32.2210, 35.2640, 'star@plumbing.ps', 750, 408771234, 'system', NOW()),
(407334455, 'Master Construction', '0599242526', '042345621', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'Hebron - Downtown', 31.5326, 35.0998, 'master@construct.ps', 0, 407556789, 'system', NOW()),
(409556677, 'Al-Salam Trading', '0599272829', '022345622', (SELECT customer_city_id FROM customer_city WHERE name = 'Tulkarm' LIMIT 1), 'Tulkarm - Western Area', 32.3108, 35.0278, 'salam@trading.ps', 1500, 408771234, 'system', NOW()),
(408990011, 'Premium Sanitary House', '0599303132', '022345623', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Downtown', 31.9025, 35.2070, 'premium@sanitary.ps', 300, 409882311, 'system', NOW()),
(407112233, 'Elite Bathroom Solutions', '0599333435', '092345624', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Old City', 32.2203, 35.2588, 'elite@bathroom.ps', 0, 408771234, 'system', NOW()),
(409887766, 'Royal Fittings Store', '0599363738', '042345625', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'Hebron - Main Street', 31.5287, 35.0950, 'royal@fittings.ps', 950, 407556789, 'system', NOW()),
(408225544, 'Professional Plumbing', '0599394041', '022345626', (SELECT customer_city_id FROM customer_city WHERE name = 'Bethlehem' LIMIT 1), 'Bethlehem - City Center', 31.7065, 35.2007, 'pro@plumbing.ps', 0, 409882311, 'system', NOW()),
(407443322, 'Quality Hardware Ltd.', '0599424344', '092345627', (SELECT customer_city_id FROM customer_city WHERE name = 'Jenin' LIMIT 1), 'Jenin - North Area', 32.4621, 35.2890, 'quality@hardware.ps', 600, 408771234, 'system', NOW());

-- Customer user accounts
INSERT INTO user_account_customer (customer_id, password, is_active, added_by, added_time) VALUES
(409223118, '1234', 'yes', 'system', NOW()),
(408554321, '1234', 'yes', 'system', NOW()),
(407667655, '1234', 'yes', 'system', NOW()),
(406900221, '1234', 'yes', 'system', NOW()),
(408123456, '1234', 'yes', 'system', NOW()),
(407789012, '1234', 'yes', 'system', NOW()),
(409445566, '1234', 'yes', 'system', NOW()),
(408667788, '1234', 'yes', 'system', NOW()),
(407334455, '1234', 'yes', 'system', NOW()),
(409556677, '1234', 'yes', 'system', NOW()),
(408990011, '1234', 'yes', 'system', NOW()),
(407112233, '1234', 'yes', 'system', NOW()),
(409887766, '1234', 'yes', 'system', NOW()),
(408225544, '1234', 'yes', 'system', NOW()),
(407443322, '1234', 'yes', 'system', NOW());

-- =====================================================
-- PAYMENTS (incoming from customers, outgoing to suppliers)
-- =====================================================

-- Incoming payments (customers paying invoices/orders)
INSERT INTO incoming_payment (customer_id, amount, date_time, description, last_action_by, last_action_time) VALUES
(409223118, 1200, NOW(), 'Advance on new project', 'system', NOW()),
(408554321, 850, NOW() - INTERVAL '1 day', 'Clearing outstanding balance', 'system', NOW()),
(407667655, 450, NOW() - INTERVAL '3 days', 'Partial payment for sanitary shipment', 'system', NOW()),
(406900221, 600, NOW() - INTERVAL '10 days', 'Progress payment', 'system', NOW()),
(408123456, 300, NOW() - INTERVAL '30 days', 'Past due settlement', 'system', NOW()),
(407789012, 950, NOW() - INTERVAL '60 days', 'Final payment for completed job', 'system', NOW());

-- Outgoing payments (paying suppliers)
INSERT INTO outgoing_payment (supplier_id, amount, date_time, description, last_action_by, last_action_time) VALUES
(407392001, 1800, NOW(), 'Payment for accessories batch', 'system', NOW()),
(407392002, 2200, NOW() - INTERVAL '2 days', 'Partial settlement for pipe shipment', 'system', NOW()),
(407392003, 1350, NOW() - INTERVAL '7 days', 'Mixer delivery payment', 'system', NOW()),
(407392004, 2600, NOW() - INTERVAL '14 days', 'Fittings consignment', 'system', NOW()),
(407392005, 900, NOW() - INTERVAL '21 days', 'Valves restock payment', 'system', NOW()),
(407392006, 1500, NOW() - INTERVAL '45 days', 'Pumps and heaters invoice', 'system', NOW());

-- Customer checks
INSERT INTO customer_checks
(customer_id, bank_id, bank_branch, exchange_rate, exchange_date, status, description, last_action_by, last_action_time)
VALUES
(409223118, (SELECT bank_id FROM banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Ramallah Branch' LIMIT 1), 900, NOW(), 'Cashed', 'Customer paid for mixers', 'system', NOW()),
(408554321, (SELECT bank_id FROM banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Nablus Branch' LIMIT 1), 1200, NOW() - INTERVAL '2 days', 'Returned', 'Bounced check follow-up needed', 'system', NOW()),
(407667655, (SELECT bank_id FROM banks WHERE bank_name = 'Arab Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Ramallah Main Branch' LIMIT 1), 1500, NOW() + INTERVAL '15 days', 'Company Box', 'Post-dated kept in box', 'system', NOW()),
(406900221, (SELECT bank_id FROM banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Al-Bireh Branch' LIMIT 1), 800, NOW() - INTERVAL '5 days', 'Cashed', 'Payment cleared', 'system', NOW()),
(408123456, (SELECT bank_id FROM banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Nablus Central' LIMIT 1), 600, NOW() + INTERVAL '30 days', 'Endorsed', 'Endorsed to supplier', 'system', NOW());

-- Supplier checks
INSERT INTO supplier_checks
(supplier_id, bank_id, bank_branch, exchange_rate, exchange_date, status, description, last_action_by, last_action_time)
VALUES
(407392004, (SELECT bank_id FROM banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Ramallah Branch' LIMIT 1), 1400, NOW(), 'Cashed', 'Payment for GROHE shipment', 'system', NOW()),
(407392002, (SELECT bank_id FROM banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Nablus Branch' LIMIT 1), 800, NOW(), 'Pending', 'Payment for PPR pipes', 'system', NOW()),
(407392003, (SELECT bank_id FROM banks WHERE bank_name = 'Arab Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Bethlehem Branch' LIMIT 1), 950, NOW() + INTERVAL '10 days', 'Pending', 'Post-dated for accessories', 'system', NOW()),
(407392005, (SELECT bank_id FROM banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Nablus Central' LIMIT 1), 1200, NOW() - INTERVAL '3 days', 'Cashed', 'Valve payment cleared', 'system', NOW()),
(407392007, (SELECT bank_id FROM banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM branches WHERE address = 'Ramallah Branch' LIMIT 1), 700, NOW(), 'Cashed', 'Sanitary ware payment', 'system', NOW());

-- =====================================================
-- PRODUCT CATEGORY
-- =====================================================

INSERT INTO product_category (name, last_action_by, last_action_time) VALUES
('Shower Heads & Sets', 'system', NOW()),
('Mixers & Faucets', 'system', NOW()),
('Brass Pipes & Fittings', 'system', NOW()),
('PPR Pipes & Fittings', 'system', NOW()),
('Bathroom Accessories', 'system', NOW()),
('Toilets & Basins', 'system', NOW()),
('Valves & Controls', 'system', NOW()),
('Water Heaters', 'system', NOW());

-- =====================================================
-- BRAND
-- =====================================================

INSERT INTO brand (name, last_action_by, last_action_time) VALUES
('GROHE', 'system', NOW()),
('Hansgrohe', 'system', NOW()),
('Firat', 'system', NOW()),
('Kalde', 'system', NOW()),
('Valtec', 'system', NOW()),
('Roca', 'system', NOW()),
('Ideal Standard', 'system', NOW()),
('Wavin', 'system', NOW()),
('Brass Master', 'system', NOW()),
('Delta', 'system', NOW());

-- =====================================================
-- UNIT
-- =====================================================

INSERT INTO unit (unit_name) VALUES 
('cm'),
('box'),
('pcs');

-- =====================================================
-- PRODUCT (30 Products for Sanitary Ware Company)
-- =====================================================

INSERT INTO product
(category_id, name, brand_id, wholesale_price, selling_price, minimum_profit_percent, unit_id, is_active, last_action_by, last_action_time, total_quantity)
VALUES
-- Shower Heads & Sets
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads & Sets' LIMIT 1), 'GROHE Hand Shower 3-Flow Chrome', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 35, 49, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads & Sets' LIMIT 1), 'Hansgrohe Rain Shower Head 250mm', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 60, 85, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads & Sets' LIMIT 1), 'Roca Shower Set Complete', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 75, 110, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads & Sets' LIMIT 1), 'GROHE Shower Panel System', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 280, 420, 25, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Mixers & Faucets
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'GROHE Basin Mixer Chrome', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 55, 80, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'Hansgrohe Kitchen Mixer Pull-Out', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 90, 130, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'Ideal Standard Bathtub Mixer', (SELECT brand_id FROM brand WHERE name = 'Ideal Standard' LIMIT 1), 65, 95, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'Roca Wall Mounted Basin Mixer', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 70, 105, 25, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Brass Pipes & Fittings
((SELECT product_category_id FROM product_category WHERE name = 'Brass Pipes & Fittings' LIMIT 1), 'Brass Elbow 1/2 inch', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 2.5, 4, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Brass Pipes & Fittings' LIMIT 1), 'Brass Nipple 3/4 inch', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 3, 5, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Brass Pipes & Fittings' LIMIT 1), 'Brass T-Joint 1/2 inch', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 3.5, 5.5, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Brass Pipes & Fittings' LIMIT 1), 'Brass Reducer 3/4 to 1/2', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 2, 3.5, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Brass Pipes & Fittings' LIMIT 1), 'Brass Union 1 inch', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 8, 12, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- PPR Pipes & Fittings
((SELECT product_category_id FROM product_category WHERE name = 'PPR Pipes & Fittings' LIMIT 1), 'Firat PPR Pipe 20mm', (SELECT brand_id FROM brand WHERE name = 'Firat' LIMIT 1), 2.5, 4, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'PPR Pipes & Fittings' LIMIT 1), 'Kalde PPR Pipe 25mm', (SELECT brand_id FROM brand WHERE name = 'Kalde' LIMIT 1), 3, 4.5, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'PPR Pipes & Fittings' LIMIT 1), 'Wavin PPR Pipe 32mm', (SELECT brand_id FROM brand WHERE name = 'Wavin' LIMIT 1), 4.5, 7, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'PPR Pipes & Fittings' LIMIT 1), 'Firat PPR Pipe 40mm', (SELECT brand_id FROM brand WHERE name = 'Firat' LIMIT 1), 6, 9.5, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'PPR Pipes & Fittings' LIMIT 1), 'Kalde PPR Elbow 25mm', (SELECT brand_id FROM brand WHERE name = 'Kalde' LIMIT 1), 1.5, 2.5, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Valves & Controls
((SELECT product_category_id FROM product_category WHERE name = 'Valves & Controls' LIMIT 1), 'Valtec Ball Valve 1/2 inch', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 6, 10, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Valves & Controls' LIMIT 1), 'Valtec Ball Valve 1 inch', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 8, 13, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Valves & Controls' LIMIT 1), 'Valtec Pressure Reducer Valve', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 25, 40, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Valves & Controls' LIMIT 1), 'Brass Gate Valve 3/4 inch', (SELECT brand_id FROM brand WHERE name = 'Brass Master' LIMIT 1), 12, 18, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Bathroom Accessories
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'GROHE Towel Holder Chrome', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 12, 18, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'Hansgrohe Soap Dispenser', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 18, 28, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'GROHE Toilet Paper Holder', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 10, 16, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'Roca Towel Ring Chrome', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 8, 14, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Toilets & Basins
((SELECT product_category_id FROM product_category WHERE name = 'Toilets & Basins' LIMIT 1), 'Roca Wall Hung Toilet', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 180, 270, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Toilets & Basins' LIMIT 1), 'Ideal Standard Pedestal Basin', (SELECT brand_id FROM brand WHERE name = 'Ideal Standard' LIMIT 1), 85, 130, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),
((SELECT product_category_id FROM product_category WHERE name = 'Toilets & Basins' LIMIT 1), 'Roca Countertop Basin', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 95, 145, 25, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0),

-- Water Heaters
((SELECT product_category_id FROM product_category WHERE name = 'Water Heaters' LIMIT 1), 'Delta Electric Water Heater 50L', (SELECT brand_id FROM brand WHERE name = 'Delta' LIMIT 1), 120, 180, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system', NOW(), 0);

-- =====================================================
-- INVENTORY (3 Inventories)
-- =====================================================

INSERT INTO inventory (inventory_location, last_action_by, last_action_time) VALUES
('Main Warehouse - Ramallah', 'system', NOW()),
('Secondary Storage - Nablus', 'system', NOW()),
('Distribution Center - Hebron', 'system', NOW());

-- =====================================================
-- BATCH (Multiple batches for products with different production dates)
-- Note: Each batch contains only one product
-- Total quantity in product table = sum of batch quantities for that product
-- =====================================================

INSERT INTO batch
(product_id, supplier_id, quantity, inventory_id, storage_location_descrption, last_action_by, last_action_time, expiry_date, production_date)
VALUES
-- GROHE Hand Shower 3-Flow Chrome (Product 1) - Total: 150
((SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 407392001, 80, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A1-Shelf 1', 'system', NOW(), NULL, '2024-06-15'),
((SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 407392001, 70, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A1-Shelf 2', 'system', NOW(), NULL, '2024-09-20'),

-- Hansgrohe Rain Shower Head 250mm (Product 2) - Total: 60
((SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), 407392003, 60, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A2-Shelf 1', 'system', NOW(), NULL, '2024-07-10'),

-- Roca Shower Set Complete (Product 3) - Total: 95
((SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 407392008, 45, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B1-Shelf 1', 'system', NOW(), NULL, '2024-05-22'),
((SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 407392008, 50, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B1-Shelf 2', 'system', NOW(), NULL, '2024-10-05'),

-- GROHE Shower Panel System (Product 4) - Total: 25
((SELECT product_id FROM product WHERE name = 'GROHE Shower Panel System' LIMIT 1), 407392001, 25, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A3-Shelf 1', 'system', NOW(), NULL, '2024-08-18'),

-- GROHE Basin Mixer Chrome (Product 5) - Total: 120
((SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 407392001, 70, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A4-Shelf 1', 'system', NOW(), NULL, '2024-04-12'),
((SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 407392001, 50, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A4-Shelf 2', 'system', NOW(), NULL, '2024-11-08'),

-- Hansgrohe Kitchen Mixer Pull-Out (Product 6) - Total: 85
((SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), 407392003, 85, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A5-Shelf 1', 'system', NOW(), NULL, '2024-06-30'),

-- Ideal Standard Bathtub Mixer (Product 7) - Total: 55
((SELECT product_id FROM product WHERE name = 'Ideal Standard Bathtub Mixer' LIMIT 1), 407392007, 30, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B2-Shelf 1', 'system', NOW(), NULL, '2024-03-25'),
((SELECT product_id FROM product WHERE name = 'Ideal Standard Bathtub Mixer' LIMIT 1), 407392007, 25, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B2-Shelf 2', 'system', NOW(), NULL, '2024-09-14'),

-- Roca Wall Mounted Basin Mixer (Product 8) - Total: 40
((SELECT product_id FROM product WHERE name = 'Roca Wall Mounted Basin Mixer' LIMIT 1), 407392008, 40, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B3-Shelf 1', 'system', NOW(), NULL, '2024-07-28'),

-- Brass Elbow 1/2 inch (Product 9) - Total: 500
((SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), 407392010, 300, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C1-Shelf 1', 'system', NOW(), NULL, '2024-02-10'),
((SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), 407392010, 200, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C1-Shelf 2', 'system', NOW(), NULL, '2024-08-22'),

-- Brass Nipple 3/4 inch (Product 10) - Total: 450
((SELECT product_id FROM product WHERE name = 'Brass Nipple 3/4 inch' LIMIT 1), 407392010, 450, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C2-Shelf 1', 'system', NOW(), NULL, '2024-05-17'),

-- Brass T-Joint 1/2 inch (Product 11) - Total: 380
((SELECT product_id FROM product WHERE name = 'Brass T-Joint 1/2 inch' LIMIT 1), 407392010, 200, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C3-Shelf 1', 'system', NOW(), NULL, '2024-04-08'),
((SELECT product_id FROM product WHERE name = 'Brass T-Joint 1/2 inch' LIMIT 1), 407392010, 180, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C3-Shelf 2', 'system', NOW(), NULL, '2024-10-19'),

-- Brass Reducer 3/4 to 1/2 (Product 12) - Total: 320
((SELECT product_id FROM product WHERE name = 'Brass Reducer 3/4 to 1/2' LIMIT 1), 407392010, 320, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C4-Shelf 1', 'system', NOW(), NULL, '2024-06-05'),

-- Brass Union 1 inch (Product 13) - Total: 150
((SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), 407392010, 80, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C5-Shelf 1', 'system', NOW(), NULL, '2024-03-14'),
((SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), 407392010, 70, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C5-Shelf 2', 'system', NOW(), NULL, '2024-09-27'),

-- Firat PPR Pipe 20mm (Product 14) - Total: 800
((SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 407392002, 500, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B4-Shelf 1', 'system', NOW(), NULL, '2024-01-20'),
((SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 407392002, 300, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B4-Shelf 2', 'system', NOW(), NULL, '2024-07-15'),

-- Kalde PPR Pipe 25mm (Product 15) - Total: 650
((SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 407392004, 350, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B5-Shelf 1', 'system', NOW(), NULL, '2024-02-28'),
((SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 407392004, 300, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B5-Shelf 2', 'system', NOW(), NULL, '2024-10-11'),

-- Wavin PPR Pipe 32mm (Product 16) - Total: 550
((SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 407392009, 550, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C6-Shelf 1', 'system', NOW(), NULL, '2024-05-09'),

-- Firat PPR Pipe 40mm (Product 17) - Total: 420
((SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 40mm' LIMIT 1), 407392002, 220, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B6-Shelf 1', 'system', NOW(), NULL, '2024-03-18'),
((SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 40mm' LIMIT 1), 407392002, 200, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B6-Shelf 2', 'system', NOW(), NULL, '2024-11-02'),

-- Kalde PPR Elbow 25mm (Product 18) - Total: 600
((SELECT product_id FROM product WHERE name = 'Kalde PPR Elbow 25mm' LIMIT 1), 407392004, 600, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B7-Shelf 1', 'system', NOW(), NULL, '2024-04-22'),

-- Valtec Ball Valve 1/2 inch (Product 19) - Total: 200
((SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 407392005, 120, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A6-Shelf 1', 'system', NOW(), NULL, '2024-06-08'),
((SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 407392005, 80, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A6-Shelf 2', 'system', NOW(), NULL, '2024-10-25'),

-- Valtec Ball Valve 1 inch (Product 20) - Total: 160
((SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), 407392005, 160, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A7-Shelf 1', 'system', NOW(), NULL, '2024-07-03'),

-- Valtec Pressure Reducer Valve (Product 21) - Total: 75
((SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), 407392005, 40, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A8-Shelf 1', 'system', NOW(), NULL, '2024-05-14'),
((SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), 407392005, 35, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A8-Shelf 2', 'system', NOW(), NULL, '2024-09-30'),

-- Brass Gate Valve 3/4 inch (Product 22) - Total: 130
((SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), 407392010, 130, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C7-Shelf 1', 'system', NOW(), NULL, '2024-08-07'),

-- GROHE Towel Holder Chrome (Product 23) - Total: 180
((SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 407392001, 100, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A9-Shelf 1', 'system', NOW(), NULL, '2024-02-16'),
((SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 407392001, 80, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A9-Shelf 2', 'system', NOW(), NULL, '2024-08-29'),

-- Hansgrohe Soap Dispenser (Product 24) - Total: 140
((SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 407392003, 140, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A10-Shelf 1', 'system', NOW(), NULL, '2024-06-20'),

-- GROHE Toilet Paper Holder (Product 25) - Total: 220
((SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), 407392001, 120, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A11-Shelf 1', 'system', NOW(), NULL, '2024-04-05'),
((SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), 407392001, 100, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A11-Shelf 2', 'system', NOW(), NULL, '2024-10-17'),

-- Roca Towel Ring Chrome (Product 26) - Total: 190
((SELECT product_id FROM product WHERE name = 'Roca Towel Ring Chrome' LIMIT 1), 407392008, 190, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B8-Shelf 1', 'system', NOW(), NULL, '2024-07-12'),

-- Roca Wall Hung Toilet (Product 27) - Total: 35
((SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 407392008, 20, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C8-Shelf 1', 'system', NOW(), NULL, '2024-03-08'),
((SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 407392008, 15, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C8-Shelf 2', 'system', NOW(), NULL, '2024-09-05'),

-- Ideal Standard Pedestal Basin (Product 28) - Total: 45
((SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), 407392007, 45, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C9-Shelf 1', 'system', NOW(), NULL, '2024-05-26'),

-- Roca Countertop Basin (Product 29) - Total: 30
((SELECT product_id FROM product WHERE name = 'Roca Countertop Basin' LIMIT 1), 407392008, 18, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C10-Shelf 1', 'system', NOW(), NULL, '2024-02-22'),
((SELECT product_id FROM product WHERE name = 'Roca Countertop Basin' LIMIT 1), 407392008, 12, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C10-Shelf 2', 'system', NOW(), NULL, '2024-08-15'),

-- Delta Electric Water Heater 50L (Product 30) - Total: 28
((SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), 407392006, 16, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C11-Shelf 1', 'system', NOW(), NULL, '2024-04-19'),
((SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), 407392006, 12, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 'Rack C11-Shelf 2', 'system', NOW(), NULL, '2024-10-08');

-- =====================================================
-- UPDATE PRODUCT TOTAL QUANTITY (Sum of batch quantities)
-- =====================================================

UPDATE product SET total_quantity = 150 WHERE name = 'GROHE Hand Shower 3-Flow Chrome';
UPDATE product SET total_quantity = 60 WHERE name = 'Hansgrohe Rain Shower Head 250mm';
UPDATE product SET total_quantity = 95 WHERE name = 'Roca Shower Set Complete';
UPDATE product SET total_quantity = 25 WHERE name = 'GROHE Shower Panel System';
UPDATE product SET total_quantity = 120 WHERE name = 'GROHE Basin Mixer Chrome';
UPDATE product SET total_quantity = 85 WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out';
UPDATE product SET total_quantity = 55 WHERE name = 'Ideal Standard Bathtub Mixer';
UPDATE product SET total_quantity = 40 WHERE name = 'Roca Wall Mounted Basin Mixer';
UPDATE product SET total_quantity = 500 WHERE name = 'Brass Elbow 1/2 inch';
UPDATE product SET total_quantity = 450 WHERE name = 'Brass Nipple 3/4 inch';
UPDATE product SET total_quantity = 380 WHERE name = 'Brass T-Joint 1/2 inch';
UPDATE product SET total_quantity = 320 WHERE name = 'Brass Reducer 3/4 to 1/2';
UPDATE product SET total_quantity = 150 WHERE name = 'Brass Union 1 inch';
UPDATE product SET total_quantity = 800 WHERE name = 'Firat PPR Pipe 20mm';
UPDATE product SET total_quantity = 650 WHERE name = 'Kalde PPR Pipe 25mm';
UPDATE product SET total_quantity = 550 WHERE name = 'Wavin PPR Pipe 32mm';
UPDATE product SET total_quantity = 420 WHERE name = 'Firat PPR Pipe 40mm';
UPDATE product SET total_quantity = 600 WHERE name = 'Kalde PPR Elbow 25mm';
UPDATE product SET total_quantity = 200 WHERE name = 'Valtec Ball Valve 1/2 inch';
UPDATE product SET total_quantity = 160 WHERE name = 'Valtec Ball Valve 1 inch';
UPDATE product SET total_quantity = 75 WHERE name = 'Valtec Pressure Reducer Valve';
UPDATE product SET total_quantity = 130 WHERE name = 'Brass Gate Valve 3/4 inch';
UPDATE product SET total_quantity = 180 WHERE name = 'GROHE Towel Holder Chrome';
UPDATE product SET total_quantity = 140 WHERE name = 'Hansgrohe Soap Dispenser';
UPDATE product SET total_quantity = 220 WHERE name = 'GROHE Toilet Paper Holder';
UPDATE product SET total_quantity = 190 WHERE name = 'Roca Towel Ring Chrome';
UPDATE product SET total_quantity = 35 WHERE name = 'Roca Wall Hung Toilet';
UPDATE product SET total_quantity = 45 WHERE name = 'Ideal Standard Pedestal Basin';
UPDATE product SET total_quantity = 30 WHERE name = 'Roca Countertop Basin';
UPDATE product SET total_quantity = 28 WHERE name = 'Delta Electric Water Heater 50L';

-- =====================================================
-- SUPPLIER ORDER (Status coverage: Sent, Accepted, Rejected, Delivered, Updated, Hold)
-- =====================================================

-- Insert supplier orders and capture their IDs
WITH inserted_supplier_orders AS (
	INSERT INTO supplier_order
	(supplier_id, total_cost, order_date, tax_percent, total_balance, order_status, created_by_id, receives_by_id, accountant_id, last_tracing_by)
	VALUES
	-- Current window: Sent/Accepted/Rejected/Updated/Hold
	(407392001, 2500, NOW(), 16, 2900, 'Sent', 407392118, NULL, 407392118, 'system'),
	(407392002, 1800, NOW() - INTERVAL '1 day', 16, 2088, 'Accepted', 407392118, 406772901, 407392118, 'system'),
	(407392003, 1200, NOW() - INTERVAL '2 days', 16, 1392, 'Rejected', 407392118, NULL, 407392118, 'system'),
	(407392006, 1900, NOW() - INTERVAL '4 days', 16, 2204, 'Updated', 407392118, 406772901, 407392118, 'system'),
	(407392007, 2100, NOW(), 16, 2436, 'Hold', 407392118, NULL, 407392118, 'system'),
	(407392008, 1600, NOW() - INTERVAL '5 days', 16, 1856, 'Sent', 407392118, NULL, 407392118, 'system'),
	(407392009, 1400, NOW() - INTERVAL '6 days', 16, 1624, 'Accepted', 407392118, 406772901, 407392118, 'system'),
	(407392010, 1800, NOW() - INTERVAL '8 days', 16, 2088, 'Rejected', 407392118, NULL, 407392118, 'system'),
	(407392002, 2200, NOW() - INTERVAL '9 days', 16, 2552, 'Hold', 407392118, NULL, 407392118, 'system'),

	-- Delivered history for depth
	(407392004, 3200, NOW() - INTERVAL '3 days', 16, 3712, 'Delivered', 407392118, 406772901, 407392118, 'system'),
	(407392005, 2700, NOW() - INTERVAL '730 days', 16, 3132, 'Delivered', 407392118, 406772901, 407392118, 'system'),
	(407392003, 2600, NOW() - INTERVAL '10 days', 16, 3016, 'Delivered', 407392118, 406772901, 407392118, 'system')
	RETURNING order_id
),
ordered_supplier_ids AS (
	SELECT order_id, ROW_NUMBER() OVER (ORDER BY order_id) AS rn
	FROM inserted_supplier_orders
),
supplier_description_insert AS (
	INSERT INTO supplier_order_description
	(order_id, product_id, receipt_quantity, quantity, price_per_product, last_tracing_by, last_tracing_time)
	SELECT osi.order_id, v.product_id, v.receipt_quantity, v.quantity, v.price_per_product, v.last_tracing_by, NOW()
	FROM (
		VALUES
		-- 1 Sent
		(1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 0, 50, 35, 'system'),
		(1, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 0, 30, 55, 'system'),

		-- 2 Accepted
		(2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 0, 80, 2.5, 'system'),
		(2, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), 0, 120, 1.2, 'system'),

		-- 3 Rejected
		(3, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 0, 20, 75, 'system'),
		(3, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), 0, 10, 60, 'system'),

		-- 4 Updated (partial receipt)
		(4, (SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), 20, 40, 110, 'system'),
		(4, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 40, 60, 18, 'system'),

		-- 5 Hold
		(5, (SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), 0, 30, 90, 'system'),

		-- 6 Sent
		(6, (SELECT product_id FROM product WHERE name = 'Brass Reducer 3/4 to 1/2' LIMIT 1), 0, 120, 1.1, 'system'),

		-- 7 Accepted
		(7, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 0, 200, 10, 'system'),

		-- 8 Rejected
		(8, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), 0, 40, 45, 'system'),

		-- 9 Hold
		(9, (SELECT product_id FROM product WHERE name = 'Kalde PPR Elbow 25mm' LIMIT 1), 0, 300, 1.8, 'system'),

		-- 10 Delivered (recent)
		(10, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 150, 150, 5, 'system'),
		(10, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 100, 100, 3.5, 'system'),

		-- 11 Delivered (historical)
		(11, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 200, 200, 1.5, 'system'),
		(11, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), 80, 80, 4, 'system'),

		-- 12 Delivered
		(12, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 90, 90, 55, 'system'),
		(12, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 110, 110, 35, 'system')

	) AS v(order_num, product_id, receipt_quantity, quantity, price_per_product, last_tracing_by)
	JOIN ordered_supplier_ids osi ON osi.rn = v.order_num
)
INSERT INTO supplier_order_inventory (supplier_order_id, product_id, inventory_id, batch_id, quantity)
SELECT osi.order_id,
	   v.product_id,
	   v.inventory_id,
	   (SELECT batch_id FROM batch WHERE product_id = v.product_id ORDER BY batch_id LIMIT 1) AS batch_id,
	   v.quantity
FROM (
	VALUES
	-- 1 Sent
	(1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 50),
	(1, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 30),

	-- 2 Accepted
	(2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 80),
	(2, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 120),

	-- 3 Rejected
	(3, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 20),
	(3, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 10),

	-- 4 Updated (partial receipt)
	(4, (SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 40),
	(4, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 60),

	-- 5 Hold
	(5, (SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 30),

	-- 6 Sent
	(6, (SELECT product_id FROM product WHERE name = 'Brass Reducer 3/4 to 1/2' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 120),

	-- 7 Accepted
	(7, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 200),

	-- 8 Rejected
	(8, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 40),

	-- 9 Hold
	(9, (SELECT product_id FROM product WHERE name = 'Kalde PPR Elbow 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 300),

	-- 10 Delivered (recent)
	(10, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 150),
	(10, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 100),

	-- 11 Delivered (historical)
	(11, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 200),
	(11, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 80),

	-- 12 Delivered
	(12, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 90),
	(12, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 110)

) AS v(order_num, product_id, inventory_id, quantity)
JOIN ordered_supplier_ids osi ON osi.rn = v.order_num;

-- =====================================================
-- CUSTOMER ORDER (History with all statuses used in system)
-- Status coverage: Received, Pinned, Preparing, Prepared, Delivery, Delivered, Updated, Hold
-- =====================================================

-- Insert customer orders and capture their IDs
WITH inserted_customer_orders AS (
	INSERT INTO customer_order
	(customer_id, total_cost, tax_percent, total_balance, order_date, order_status, sales_rep_id, delivered_by_id, prepared_by_id, managed_by_id, accountant_id, last_action_by, delivered_date)
	VALUES
	-- Delivered (historical ~2 years ago)
	(409223118, 420, 16, 487.2, NOW() - INTERVAL '730 days', 'Delivered', 409882311, 408113200, 409552887, 406772901, 407392118, 'system', NOW() - INTERVAL '729 days'),
	(408554321, 780, 16, 904.8, NOW() - INTERVAL '725 days', 'Delivered', 408771234, 409001122, 408661299, 406772901, 407392118, 'system', NOW() - INTERVAL '724 days'),
	(407667655, 1120, 16, 1299.2, NOW() - INTERVAL '720 days', 'Delivered', 407556789, 408113200, 409552887, 406772901, 407392118, 'system', NOW() - INTERVAL '719 days'),
	(406900221, 960, 16, 1113.6, NOW() - INTERVAL '715 days', 'Delivered', 409882311, 408113200, 407881234, 406772901, 407392118, 'system', NOW() - INTERVAL '714 days'),
	(408123456, 520, 16, 603.2, NOW() - INTERVAL '710 days', 'Delivered', 409882311, 407223344, 407881234, 406772901, 407392118, 'system', NOW() - INTERVAL '709 days'),
	(407789012, 860, 16, 997.6, NOW() - INTERVAL '705 days', 'Delivered', 408771234, 408113200, 409552887, 406772901, 407392118, 'system', NOW() - INTERVAL '704 days'),

	-- Delivery (out for delivery, partially delivered, current)
	(409445566, 1350, 16, 1566, NOW(), 'Delivery', 409882311, 408113200, 409552887, 406772901, 407392118, 'system', NULL),
	(408667788, 640, 16, 742.4, NOW() - INTERVAL '1 day', 'Delivery', 408771234, 409001122, 408661299, 406772901, 407392118, 'system', NULL),
	(407334455, 780, 16, 904.8, NOW() - INTERVAL '2 days', 'Delivery', 407556789, 408113200, 409552887, 406772901, 407392118, 'system', NULL),
	(409556677, 520, 16, 603.2, NOW() - INTERVAL '3 days', 'Delivery', 408771234, 407223344, 407881234, 406772901, 407392118, 'system', NULL),

	-- Prepared (packed, not sent, current)
	(408990011, 450, 16, 522, NOW(), 'Prepared', 409882311, NULL, 409552887, 406772901, 407392118, 'system', NULL),
	(407112233, 690, 16, 800.4, NOW() - INTERVAL '1 day', 'Prepared', 408771234, NULL, 408661299, 406772901, 407392118, 'system', NULL),
	(409887766, 830, 16, 962.8, NOW() - INTERVAL '2 days', 'Prepared', 407556789, NULL, 407881234, 406772901, 407392118, 'system', NULL),
	(408225544, 360, 16, 417.6, NOW() - INTERVAL '3 days', 'Prepared', 409882311, NULL, 409552887, 406772901, 407392118, 'system', NULL),

	-- Received (intake)
	(407443322, 540, 16, 626.4, NOW(), 'Received', 408771234, NULL, NULL, NULL, 407392118, 'system', NULL),
	(409223118, 680, 16, 788.8, NOW() - INTERVAL '1 day', 'Received', 409882311, NULL, NULL, NULL, 407392118, 'system', NULL),
	(408554321, 410, 16, 475.6, NOW() - INTERVAL '2 days', 'Received', 408771234, NULL, NULL, NULL, 407392118, 'system', NULL),

	-- Pinned (accountant forwards to storage manager)
	(407667655, 920, 16, 1067.2, NOW() - INTERVAL '1 day', 'Pinned', 407556789, NULL, NULL, 406772901, 407392118, 'system', NULL),
	(406900221, 300, 16, 348, NOW() - INTERVAL '2 days', 'Pinned', 409882311, NULL, NULL, 406772901, 407392118, 'system', NULL),

	-- Preparing (staff working on it)
	(408123456, 260, 16, 301.6, NOW() - INTERVAL '1 day', 'Preparing', 409882311, NULL, 408661299, 406772901, 407392118, 'system', NULL),
	(407789012, 180, 16, 208.8, NOW() - INTERVAL '2 days', 'Preparing', 408771234, NULL, 409552887, 406772901, 407392118, 'system', NULL),

	-- Updated (recently modified order)
	(409445566, 220, 16, 255.2, NOW() - INTERVAL '2 days', 'Updated', 409882311, NULL, 409552887, 406772901, 407392118, 'system', NULL),

	-- Hold (on hold)
	(408667788, 340, 16, 394.4, NOW() - INTERVAL '3 days', 'Hold', 408771234, NULL, NULL, NULL, 407392118, 'system', NULL),
	(407334455, 260, 16, 301.6, NOW() - INTERVAL '4 days', 'Hold', 407556789, NULL, NULL, NULL, 407392118, 'system', NULL)
	RETURNING customer_order_id
),
ordered_ids AS (
	SELECT customer_order_id, ROW_NUMBER() OVER (ORDER BY customer_order_id) AS rn
	FROM inserted_customer_orders
),
insert_descriptions AS (
	INSERT INTO customer_order_description
(customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_by, last_action_time)
SELECT oi.customer_order_id, v.product_id, v.delivered_quantity, v.quantity, v.total_price, v.delivered_date, v.last_action_by, NOW()
FROM (
	VALUES
	-- 1 Delivered
	(1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 4, 4, 196, NOW() - INTERVAL '729 days', 'system'),
	(1, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 6, 6, 60, NOW() - INTERVAL '729 days', 'system'),

	-- 2 Delivered
	(2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 40, 40, 160, NOW() - INTERVAL '724 days', 'system'),
	(2, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), 30, 30, 120, NOW() - INTERVAL '724 days', 'system'),

	-- 3 Delivered
	(3, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), 6, 6, 780, NOW() - INTERVAL '719 days', 'system'),
	(3, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 8, 8, 144, NOW() - INTERVAL '719 days', 'system'),

	-- 4 Delivered
	(4, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), 8, 8, 104, NOW() - INTERVAL '714 days', 'system'),
	(4, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), 6, 6, 108, NOW() - INTERVAL '714 days', 'system'),

	-- 5 Delivered
	(5, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 6, 6, 168, NOW() - INTERVAL '709 days', 'system'),
	(5, (SELECT product_id FROM product WHERE name = 'Roca Towel Ring Chrome' LIMIT 1), 8, 8, 112, NOW() - INTERVAL '709 days', 'system'),

	-- 6 Delivered
	(6, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 50, 50, 225, NOW() - INTERVAL '704 days', 'system'),
	(6, (SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), 10, 10, 160, NOW() - INTERVAL '704 days', 'system'),

	-- 7 Delivery (partial delivered_quantity)
	(7, (SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 5, 8, 540, NULL, 'system'),
	(7, (SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), 20, 25, 240, NULL, 'system'),

	-- 8 Delivery
	(8, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 4, 6, 480, NULL, 'system'),
	(8, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), 2, 3, 120, NULL, 'system'),

	-- 9 Delivery
	(9, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), 2, 4, 340, NULL, 'system'),
	(9, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 3, 5, 245, NULL, 'system'),

	-- 10 Delivery
	(10, (SELECT product_id FROM product WHERE name = 'Kalde PPR Elbow 25mm' LIMIT 1), 20, 30, 75, NULL, 'system'),
	(10, (SELECT product_id FROM product WHERE name = 'Brass Nipple 3/4 inch' LIMIT 1), 15, 20, 75, NULL, 'system'),

	-- 11 Prepared (delivered_quantity = 0)
	(11, (SELECT product_id FROM product WHERE name = 'Roca Countertop Basin' LIMIT 1), 0, 4, 380, NULL, 'system'),
	(11, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 0, 8, 144, NULL, 'system'),

	-- 12 Prepared
	(12, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 40mm' LIMIT 1), 0, 30, 285, NULL, 'system'),
	(12, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 0, 10, 100, NULL, 'system'),

	-- 13 Prepared
	(13, (SELECT product_id FROM product WHERE name = 'GROHE Shower Panel System' LIMIT 1), 0, 2, 840, NULL, 'system'),
	(13, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), 0, 4, 520, NULL, 'system'),

	-- 14 Prepared
	(14, (SELECT product_id FROM product WHERE name = 'Brass T-Joint 1/2 inch' LIMIT 1), 0, 40, 220, NULL, 'system'),
	(14, (SELECT product_id FROM product WHERE name = 'Brass Reducer 3/4 to 1/2' LIMIT 1), 0, 25, 87.5, NULL, 'system'),

	-- 15 Received (intake)
	(15, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 0, 60, 420, NULL, 'system'),
	(15, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 0, 5, 140, NULL, 'system'),

	-- 16 Received
	(16, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 0, 6, 480, NULL, 'system'),
	(16, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), 0, 40, 160, NULL, 'system'),

	-- 17 Received
	(17, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), 0, 6, 78, NULL, 'system'),
	(17, (SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), 0, 12, 192, NULL, 'system'),

	-- 18 Pinned
	(18, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 0, 70, 315, NULL, 'system'),
	(18, (SELECT product_id FROM product WHERE name = 'Roca Towel Ring Chrome' LIMIT 1), 0, 10, 140, NULL, 'system'),

	-- 19 Pinned
	(19, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), 0, 2, 170, NULL, 'system'),
	(19, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), 0, 4, 72, NULL, 'system'),

	-- 20 Preparing
	(20, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), 0, 3, 120, NULL, 'system'),
	(20, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), 0, 3, 147, NULL, 'system'),

	-- 21 Preparing
	(21, (SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), 0, 1, 130, NULL, 'system'),
	(21, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), 0, 6, 60, NULL, 'system'),

	-- 22 Updated (partial delivery reflected)
	(22, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 3, 3, 240, NOW() - INTERVAL '2 days', 'system'),
	(22, (SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), 10, 10, 120, NOW() - INTERVAL '2 days', 'system'),

	-- 23 Hold
	(23, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), 0, 2, 260, NULL, 'system'),
	(23, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 0, 25, 112.5, NULL, 'system'),

	-- 24 Hold
	(24, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 0, 2, 220, NULL, 'system'),
	(24, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), 0, 5, 65, NULL, 'system')
  
 ) AS v(order_num, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_by)
JOIN ordered_ids oi ON oi.rn = v.order_num
)
INSERT INTO customer_order_inventory (customer_order_id, product_id, inventory_id, batch_id, quantity)
SELECT oi.customer_order_id,
			 v.product_id,
			 v.inventory_id,
			 (SELECT batch_id FROM batch WHERE product_id = v.product_id ORDER BY batch_id LIMIT 1) AS batch_id,
			 v.quantity
FROM (
	VALUES
	-- match order_num with inventory locations used above
	(1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 4),
	(1, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),

	(2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 40),
	(2, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 30),

	(3, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),
	(3, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 8),

	(4, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 8),
	(4, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 6),

	(5, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),
	(5, (SELECT product_id FROM product WHERE name = 'Roca Towel Ring Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 8),

	(6, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 50),
	(6, (SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 10),

	(7, (SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 8),
	(7, (SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 25),

	(8, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),
	(8, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 3),

	(9, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 4),
	(9, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 5),

	(10, (SELECT product_id FROM product WHERE name = 'Kalde PPR Elbow 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 30),
	(10, (SELECT product_id FROM product WHERE name = 'Brass Nipple 3/4 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 20),

	(11, (SELECT product_id FROM product WHERE name = 'Roca Countertop Basin' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 4),
	(11, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 8),

	(12, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 40mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 30),
	(12, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 10),

	(13, (SELECT product_id FROM product WHERE name = 'GROHE Shower Panel System' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 2),
	(13, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 4),

	(14, (SELECT product_id FROM product WHERE name = 'Brass T-Joint 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 40),
	(14, (SELECT product_id FROM product WHERE name = 'Brass Reducer 3/4 to 1/2' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 25),

	(15, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 60),
	(15, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 5),

	(16, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),
	(16, (SELECT product_id FROM product WHERE name = 'Brass Elbow 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 40),

	(17, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),
	(17, (SELECT product_id FROM product WHERE name = 'GROHE Toilet Paper Holder' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 12),

	(18, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 70),
	(18, (SELECT product_id FROM product WHERE name = 'Roca Towel Ring Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 10),

	(19, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head 250mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 2),
	(19, (SELECT product_id FROM product WHERE name = 'Brass Gate Valve 3/4 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 4),

	(20, (SELECT product_id FROM product WHERE name = 'Valtec Pressure Reducer Valve' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 3),
	(20, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 3),

	(21, (SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 1),
	(21, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1/2 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 6),

	(22, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 3),
	(22, (SELECT product_id FROM product WHERE name = 'Brass Union 1 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Distribution Center - Hebron' LIMIT 1), 10),

	(23, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer Pull-Out' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 2),
	(23, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 25),

	(24, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 2),
	(24, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 5)

 ) AS v(order_num, product_id, inventory_id, quantity)
JOIN ordered_ids oi ON oi.rn = v.order_num;










-- ****************************************************************************





BEGIN;

-- Order #1 — Customer: Ahmad Nizar, Item: Hand Shower (qty 5), Prepared by: Ayman Al Asmar
WITH o AS (
  INSERT INTO customer_order (customer_id, order_status, order_date, total_cost, tax_percent, total_balance, last_action_time)
  VALUES (
    (SELECT customer_id FROM customer WHERE name='Ahmad Nizar'),
    'Prepared',
    NOW(), 0, 0, 0, NOW()
  )
  RETURNING customer_order_id
)
-- Description line(s)
INSERT INTO customer_order_description (customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_time)
SELECT
  o.customer_order_id,
  p.product_id,
  0,
  5,
  COALESCE(p.selling_price, 0) * 5,
  NULL,
  NOW()
FROM o
JOIN product p ON p.name = 'Hand Shower';

-- Inventory line(s)
INSERT INTO customer_order_inventory (customer_order_id, product_id, inventory_id, batch_id, quantity, prepared_by)
SELECT
  o.customer_order_id,
  p.product_id,
  b.inventory_id,
  b.batch_id,
  5,
  ss.storage_staff_id
FROM o
JOIN product p ON p.name = 'Hand Shower'
JOIN batch   b ON b.product_id = p.product_id
JOIN storage_staff ss ON ss.name = 'Ayman Al Asmar'
ORDER BY b.batch_id
LIMIT 1;

-- Update order totals from description lines (optional but useful)
UPDATE customer_order co
SET total_cost = sub.sum_total,
    total_balance = sub.sum_total,
    last_action_time = NOW()
FROM (
  SELECT customer_order_id, SUM(total_price) AS sum_total
  FROM customer_order_description
  WHERE customer_order_id = (SELECT customer_order_id FROM customer_order WHERE customer_id = (SELECT customer_id FROM customer WHERE name='Ahmad Nizar') ORDER BY customer_order_id DESC LIMIT 1)
  GROUP BY customer_order_id
) sub
WHERE co.customer_order_id = sub.customer_order_id;

---------------------------------------------------------------------

-- Order #2 — Customer: Saed Rimawi, Item: Freestanding Bathtub (qty 1), Prepared by: Rami Rimawi
WITH o AS (
  INSERT INTO customer_order (customer_id, order_status, order_date, total_cost, tax_percent, total_balance, last_action_time)
  VALUES (
    (SELECT customer_id FROM customer WHERE name='Saed Rimawi'),
    'Prepared',
    NOW(), 0, 0, 0, NOW()
  )
  RETURNING customer_order_id
)
INSERT INTO customer_order_description (customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_time)
SELECT
  o.customer_order_id,
  p.product_id,
  0,
  1,
  COALESCE(p.selling_price, 0) * 1,
  NULL,
  NOW()
FROM o
JOIN product p ON p.name = 'Freestanding Bathtub';

INSERT INTO customer_order_inventory (customer_order_id, product_id, inventory_id, batch_id, quantity, prepared_by)
SELECT
  o.customer_order_id,
  p.product_id,
  b.inventory_id,
  b.batch_id,
  1,
  ss.storage_staff_id
FROM o
JOIN product p ON p.name = 'Freestanding Bathtub'
JOIN batch   b ON b.product_id = p.product_id
JOIN storage_staff ss ON ss.name = 'Rami Rimawi'
ORDER BY b.batch_id
LIMIT 1;

UPDATE customer_order co
SET total_cost = sub.sum_total,
    total_balance = sub.sum_total,
    last_action_time = NOW()
FROM (
  SELECT customer_order_id, SUM(total_price) AS sum_total
  FROM customer_order_description
  WHERE customer_order_id = (SELECT customer_order_id FROM customer_order WHERE customer_id = (SELECT customer_id FROM customer WHERE name='Saed Rimawi') ORDER BY customer_order_id DESC LIMIT 1)
  GROUP BY customer_order_id
) sub
WHERE co.customer_order_id = sub.customer_order_id;

---------------------------------------------------------------------

-- Order #3 — Customer: Akef Al Asmar, Item: Wall-Hung Toilet (qty 10), Prepared by: Ayman Al Asmar
WITH o AS (
  INSERT INTO customer_order (customer_id, order_status, order_date, total_cost, tax_percent, total_balance, last_action_time)
  VALUES (
    (SELECT customer_id FROM customer WHERE name='Akef Al Asmar'),
    'Prepared',
    NOW(), 0, 0, 0, NOW()
  )
  RETURNING customer_order_id
)
INSERT INTO customer_order_description (customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_time)
SELECT
  o.customer_order_id,
  p.product_id,
  0,
  10,
  COALESCE(p.selling_price, 0) * 10,
  NULL,
  NOW()
FROM o
JOIN product p ON p.name = 'Wall-Hung Toilet';

INSERT INTO customer_order_inventory (customer_order_id, product_id, inventory_id, batch_id, quantity, prepared_by)
SELECT
  o.customer_order_id,
  p.product_id,
  b.inventory_id,
  b.batch_id,
  10,
  ss.storage_staff_id
FROM o
JOIN product p ON p.name = 'Wall-Hung Toilet'
JOIN batch   b ON b.product_id = p.product_id
JOIN storage_staff ss ON ss.name = 'Ayman Al Asmar'
ORDER BY b.batch_id
LIMIT 1;

UPDATE customer_order co
SET total_cost = sub.sum_total,
    total_balance = sub.sum_total,
    last_action_time = NOW()
FROM (
  SELECT customer_order_id, SUM(total_price) AS sum_total
  FROM customer_order_description
  WHERE customer_order_id = (SELECT customer_order_id FROM customer_order WHERE customer_id = (SELECT customer_id FROM customer WHERE name='Akef Al Asmar') ORDER BY customer_order_id DESC LIMIT 1)
  GROUP BY customer_order_id
) sub
WHERE co.customer_order_id = sub.customer_order_id;

COMMIT;

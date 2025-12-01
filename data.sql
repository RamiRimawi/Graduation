-- =====================================================
--  SUPPLIER CITY
-- =====================================================

INSERT INTO supplier_city (name, last_action_by) VALUES
('Ramallah', 'system'),
('Nablus', 'system'),
('Hebron', 'system'),
('Bethlehem', 'system'),
('Jenin', 'system'),
('Tulkarm', 'system'),
('Qalqilya', 'system'),
('Jericho', 'system');

-- =====================================================
--  SUPPLIER CATEGORY
-- =====================================================

INSERT INTO supplier_category (name, last_action_by) VALUES
('Pipes & Fittings', 'system'),
('Valves', 'system'),
('Sanitary Ware', 'system'),
('Bathroom Accessories', 'system'),
('Heating Systems', 'system'),
('Water Pumps', 'system'),
('Electrical Supplies', 'system'),
('Tools & Equipment', 'system');

-- =====================================================
--  SUPPLIER
-- =====================================================

INSERT INTO supplier 
(supplier_id,name, mobile_number, telephone_number, supplier_city, address, email, creditor_balance, supplier_category_id, last_action_by)
VALUES
(407392001,'GROHE International', '0599001122', '022345678', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Masyoun', 'grohe@sanitary.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system'),
(407392002,'Firat Plastic', '0599553322', '092334455', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Industrial Area', 'firat@pipes.ps', 1200, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system'),
(407392003,'Hansgrohe Middle East', '0599887766', '042221199', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Hebron' LIMIT 1), 'Hebron - City Center', 'hans@ware.ps', 300, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system'),
(407392004,'Kalde Pipes Co.', '0599332211', '022556677', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah - Al-Bireh', 'kalde@fittings.ps', 1800, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system'),
(407392005,'Valtec Trading', '0599123456', '092445566', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Jenin' LIMIT 1), 'Jenin - Main Street', 'valtec@trade.ps', 2500, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Valves' LIMIT 1), 'system'),
(407392006,'Delta Pumps', '0599234567', '092556677', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Tulkarm' LIMIT 1), 'Tulkarm - Industrial Park', 'delta@pumps.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Water Pumps' LIMIT 1), 'system'),
(407392007,'Ideal Standard Co.', '0599345678', '022667788', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Bethlehem' LIMIT 1), 'Bethlehem - Star Street', 'ideal@standard.ps', 950, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system'),
(407392008,'Roca Sanitary', '0599456789', '042778899', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Qalqilya' LIMIT 1), 'Qalqilya - Market Area', 'roca@sanitary.ps', 500, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Sanitary Ware' LIMIT 1), 'system'),
(407392009,'Wavin Pipes Systems', '0599567890', '022889900', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Jericho' LIMIT 1), 'Jericho - Highway Road', 'wavin@pipes.ps', 3200, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system'),
(407392010,'Akman Fittings', '0599678901', '092990011', (SELECT supplier_city_id FROM supplier_city WHERE name = 'Nablus' LIMIT 1), 'Nablus - Eastern Quarter', 'akman@fittings.ps', 0, (SELECT supplier_category_id FROM supplier_category WHERE name = 'Pipes & Fittings' LIMIT 1), 'system');

-- =====================================================
-- ACCOUNTANT (NATIONAL ID)
-- =====================================================

INSERT INTO accountant 
(accountant_id, name, mobile_number, telephone_number, address, last_action_by)
VALUES
(407392118, 'Adnan Sweiti', '0599001111', '022345600', 'Ramallah - City Center', 'system'),
(409882120, 'Mahmoud Odeh', '0599552211', '022345601', 'Al-Bireh Main Street', 'system'),
(408993456, 'Sara Haddad', '0599223344', '022345602', 'Ramallah - Downtown', 'system');

-- =====================================================
-- STORAGE STAFF (NATIONAL ID)
-- =====================================================

INSERT INTO storage_staff
(storage_staff_id, name, mobile_number, telephone_number, address, last_action_by)
VALUES
(409552887, 'Fadi Salman', '0599005566', '022345607', 'Ramallah - Al-Irsal', 'system'),
(408661299, 'Yousef Mansour', '0599337788', '022345608', 'Nablus - Al-Madina', 'system'),
(407881234, 'Majed Awad', '0599448899', '022345609', 'Hebron - Industrial Zone', 'system'),
(409112345, 'Tariq Hamdan', '0599559900', '092345610', 'Nablus - West Area', 'system');

-- =====================================================
-- STORAGE MANAGER (NATIONAL ID)
-- =====================================================

INSERT INTO storage_manager
(storage_manager_id, name, mobile_number, telephone_number, address, last_action_by)
VALUES
(406772901, 'Ameer Khalil', '0599441122', '022345606', 'Ramallah - Warehouse District', 'system'),
(408334567, 'Basel Masri', '0599334455', '092345611', 'Nablus - Storage Complex', 'system');

-- =====================================================
-- DELIVERY DRIVER (NATIONAL ID)
-- =====================================================

INSERT INTO delivery_driver
(delivery_driver_id, name, mobile_number, telephone_number, address, last_action_by)
VALUES
(408113200, 'Kareem Jaber', '0599556677', '022345604', 'Hebron - Haret Al-Sheikh', 'system'),
(409001122, 'Omar Zaher', '0599445588', '022345605', 'Bethlehem - Beit Jala', 'system'),
(407223344, 'Malik Daoud', '0599667788', '022345612', 'Ramallah - Northern District', 'system'),
(408445566, 'Firas Nasser', '0599778899', '092345613', 'Jenin - City Center', 'system');

-- =====================================================
-- SALES REP CITY
-- =====================================================

INSERT INTO sales_rep_city (name, last_action_by) VALUES
('Ramallah', 'system'),
('Nablus', 'system'),
('Hebron', 'system'),
('Bethlehem', 'system'),
('Jenin', 'system');

-- =====================================================
-- SALES REPRESENTATIVE (NATIONAL ID)
-- =====================================================

INSERT INTO sales_representative
(sales_rep_id, sales_rep_city, name, mobile_number, telephone_number, email, last_action_by)
VALUES
(409882311, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Ramallah' LIMIT 1), 'Rami Khalil', '0599233344', '022345602', 'rami@sales.ps', 'system'),
(408771234, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Nablus' LIMIT 1), 'Ayman Shobaki', '0599882211', '022345603', 'ayman@sales.ps', 'system'),
(407556789, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Hebron' LIMIT 1), 'Hani Mustafa', '0599990011', '042345614', 'hani@sales.ps', 'system'),
(409334455, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Bethlehem' LIMIT 1), 'Nidal Suleiman', '0599101112', '022345615', 'nidal@sales.ps', 'system'),
(408998877, (SELECT sales_rep_city_id FROM sales_rep_city WHERE name = 'Jenin' LIMIT 1), 'Ahmad Barghouti', '0599121314', '092345616', 'ahmad@sales.ps', 'system');

-- =====================================================
-- CUSTOMER CITY
-- =====================================================

INSERT INTO customer_city (name, last_action_by) VALUES
('Ramallah', 'system'),
('Nablus', 'system'),
('Hebron', 'system'),
('Bethlehem', 'system'),
('Jenin', 'system'),
('Tulkarm', 'system');

-- =====================================================
-- CUSTOMER QUARTERS
-- =====================================================

INSERT INTO customer_quarters (name, customer_city, last_action_by) VALUES
('Al-Masyoun', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system'),
('City Center', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system'),
('Industrial Zone', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system'),
('Old City', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system'),
('Al-Salam Area', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'system'),
('Al-Bireh', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'system'),
('Eastern Quarter', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'system'),
('Star Street', (SELECT customer_city_id FROM customer_city WHERE name = 'Bethlehem' LIMIT 1), 'system'),
('Al-Amal District', (SELECT customer_city_id FROM customer_city WHERE name = 'Jenin' LIMIT 1), 'system'),
('Western Area', (SELECT customer_city_id FROM customer_city WHERE name = 'Tulkarm' LIMIT 1), 'system');

-- =====================================================
-- CUSTOMER (NATIONAL ID)
-- =====================================================

INSERT INTO customer
(customer_id, name, mobile_number, telephone_number, customer_city, address, latitude_location, longitude_location, email, balance_debit, sales_rep_id, last_action_by)
VALUES
(409223118, 'Golden Pipes Workshop', '0599345678', '022345678', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah – Al-Masyoun', 31.8981, 35.2042, 'goldpipes@work.ps', 0, 409882311, 'system'),
(408554321, 'Al-Barq Contracting', '0599543211', '092345600', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'Nablus – Industrial Zone', 32.2215, 35.2544, 'barq@contract.ps', 850, 408771234, 'system'),
(407667655, 'Modern Sanitary Co.', '0599776655', '042334455', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'Hebron – Al-Salam', 31.5321, 35.1054, 'modern@sanitary.ps', 0, 409882311, 'system'),
(406900221, 'Universal Plumbing Services', '0599002211', '022556677', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah – City Center', 31.9044, 35.2131, 'uniplumb@services.ps', 1200, 408771234, 'system'),
(408123456, 'Prime Building Materials', '0599131415', '042345617', (SELECT customer_city_id FROM customer_city WHERE name = 'Bethlehem' LIMIT 1), 'Bethlehem – Star Street', 31.7054, 35.2024, 'prime@building.ps', 500, 409334455, 'system'),
(407789012, 'Excellence Hardware', '0599151617', '092345618', (SELECT customer_city_id FROM customer_city WHERE name = 'Jenin' LIMIT 1), 'Jenin – Al-Amal', 32.4607, 35.2906, 'excellence@hardware.ps', 0, 408998877, 'system'),
(409445566, 'Al-Noor Sanitary Ware', '0599181920', '022345619', (SELECT customer_city_id FROM customer_city WHERE name = 'Ramallah' LIMIT 1), 'Ramallah – Al-Bireh', 31.9100, 35.2047, 'alnoor@sanitary.ps', 2100, 409882311, 'system'),
(408667788, 'Star Plumbing Co.', '0599212223', '092345620', (SELECT customer_city_id FROM customer_city WHERE name = 'Nablus' LIMIT 1), 'Nablus – Eastern Quarter', 32.2210, 35.2640, 'star@plumbing.ps', 750, 408771234, 'system'),
(407334455, 'Master Construction', '0599242526', '042345621', (SELECT customer_city_id FROM customer_city WHERE name = 'Hebron' LIMIT 1), 'Hebron – Downtown', 31.5326, 35.0998, 'master@construct.ps', 0, 407556789, 'system'),
(409556677, 'Al-Salam Trading', '0599272829', '022345622', (SELECT customer_city_id FROM customer_city WHERE name = 'Tulkarm' LIMIT 1), 'Tulkarm – Western Area', 32.3108, 35.0278, 'salam@trading.ps', 1500, 408771234, 'system');

-- =====================================================
-- CUSTOMER BANKS
-- =====================================================

INSERT INTO customer_banks (bank_name) VALUES
('Bank of Palestine'),
('Quds Bank'),
('Arab Bank'),
('Cairo Amman Bank'),
('Palestine Islamic Bank');

-- =====================================================
-- CUSTOMER BRANCHES
-- =====================================================

INSERT INTO customer_branches (bank_id, address) VALUES
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), 'Ramallah Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), 'Al-Bireh Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Quds Bank' LIMIT 1), 'Nablus Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Quds Bank' LIMIT 1), 'Hebron Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Arab Bank' LIMIT 1), 'Ramallah Main Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Arab Bank' LIMIT 1), 'Bethlehem Branch'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), 'Nablus Central'),
((SELECT bank_id FROM customer_banks WHERE bank_name = 'Palestine Islamic Bank' LIMIT 1), 'Jenin Branch');

-- =====================================================
-- SUPPLIER BANKS
-- =====================================================

INSERT INTO supplier_banks (bank_name) VALUES
('Bank of Palestine'),
('Quds Bank'),
('Arab Bank'),
('Cairo Amman Bank');

-- =====================================================
-- SUPPLIER BRANCHES
-- =====================================================

INSERT INTO supplier_branches (bank_id, address) VALUES
((SELECT bank_id FROM supplier_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), 'Ramallah Branch'),
((SELECT bank_id FROM supplier_banks WHERE bank_name = 'Quds Bank' LIMIT 1), 'Nablus Branch'),
((SELECT bank_id FROM supplier_banks WHERE bank_name = 'Quds Bank' LIMIT 1), 'Hebron Branch'),
((SELECT bank_id FROM supplier_banks WHERE bank_name = 'Arab Bank' LIMIT 1), 'Bethlehem Branch'),
((SELECT bank_id FROM supplier_banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), 'Jenin Branch');

-- =====================================================
-- PRODUCT CATEGORY
-- =====================================================

INSERT INTO product_category (name, last_action_by) VALUES
('Shower Heads', 'system'),
('Mixers & Faucets', 'system'),
('Pipes', 'system'),
('Fittings', 'system'),
('Bathroom Accessories', 'system'),
('Toilets & Basins', 'system'),
('Water Heaters', 'system'),
('Valves & Controls', 'system');

-- =====================================================
-- BRAND
-- =====================================================

INSERT INTO brand (name, last_action_by) VALUES
('GROHE', 'system'),
('Hansgrohe', 'system'),
('Firat', 'system'),
('Kalde', 'system'),
('Valtec', 'system'),
('Roca', 'system'),
('Ideal Standard', 'system'),
('Wavin', 'system'),
('Akman', 'system'),
('Delta', 'system');
INSERT INTO unit (unit_name) VALUES 
('cm'),
('box'),
('pcs');

-- =====================================================
-- PRODUCT
-- =====================================================

INSERT INTO product
(category_id, name, brand_id, wholesale_price, selling_price, minimum_profit_percent, unit_id, is_active, last_action_by)
VALUES
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads' LIMIT 1), 'GROHE Hand Shower 3-Flow', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 35, 49, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads' LIMIT 1), 'Hansgrohe Rain Shower Head', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 60, 85, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'GROHE Basin Mixer Chrome', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 55, 80, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'Hansgrohe Kitchen Mixer', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 90, 130, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Pipes' LIMIT 1), 'Firat PPR Pipe 20mm', (SELECT brand_id FROM brand WHERE name = 'Firat' LIMIT 1), 2.5, 4, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Pipes' LIMIT 1), 'Kalde PPR Pipe 25mm', (SELECT brand_id FROM brand WHERE name = 'Kalde' LIMIT 1), 3, 4.5, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Fittings' LIMIT 1), 'Valtec Elbow 1/2 inch', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 1.2, 2, 10, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'GROHE Towel Holder Chrome', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 12, 18, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Shower Heads' LIMIT 1), 'Roca Shower Set Complete', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 75, 110, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Mixers & Faucets' LIMIT 1), 'Ideal Standard Bathtub Mixer', (SELECT brand_id FROM brand WHERE name = 'Ideal Standard' LIMIT 1), 65, 95, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Pipes' LIMIT 1), 'Wavin PPR Pipe 32mm', (SELECT brand_id FROM brand WHERE name = 'Wavin' LIMIT 1), 4.5, 7, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Pipes' LIMIT 1), 'Firat PPR Pipe 40mm', (SELECT brand_id FROM brand WHERE name = 'Firat' LIMIT 1), 6, 9.5, 10, (SELECT unit_id FROM unit WHERE unit_name = 'cm' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Fittings' LIMIT 1), 'Akman T-Joint 3/4 inch', (SELECT brand_id FROM brand WHERE name = 'Akman' LIMIT 1), 1.5, 2.5, 10, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Fittings' LIMIT 1), 'Valtec Ball Valve 1 inch', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 8, 13, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'Hansgrohe Soap Dispenser', (SELECT brand_id FROM brand WHERE name = 'Hansgrohe' LIMIT 1), 18, 28, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Bathroom Accessories' LIMIT 1), 'GROHE Toilet Paper Holder', (SELECT brand_id FROM brand WHERE name = 'GROHE' LIMIT 1), 10, 16, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Toilets & Basins' LIMIT 1), 'Roca Wall Hung Toilet', (SELECT brand_id FROM brand WHERE name = 'Roca' LIMIT 1), 180, 270, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Toilets & Basins' LIMIT 1), 'Ideal Standard Pedestal Basin', (SELECT brand_id FROM brand WHERE name = 'Ideal Standard' LIMIT 1), 85, 130, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Water Heaters' LIMIT 1), 'Delta Electric Water Heater 50L', (SELECT brand_id FROM brand WHERE name = 'Delta' LIMIT 1), 120, 180, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Water Heaters' LIMIT 1), 'Delta Solar Water Heater 100L', (SELECT brand_id FROM brand WHERE name = 'Delta' LIMIT 1), 350, 520, 20, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system'),
((SELECT product_category_id FROM product_category WHERE name = 'Valves & Controls' LIMIT 1), 'Valtec Pressure Reducer Valve', (SELECT brand_id FROM brand WHERE name = 'Valtec' LIMIT 1), 25, 40, 15, (SELECT unit_id FROM unit WHERE unit_name = 'pcs' LIMIT 1), TRUE, 'system');

-- =====================================================
-- INVENTORY
-- =====================================================

INSERT INTO inventory (inventory_location, last_action_by) VALUES
('Main Warehouse - Ramallah', 'system'),
('Secondary Storage - Nablus', 'system'),
('Hebron Distribution Center', 'system'),
('Bethlehem Storage Facility', 'system');

-- =====================================================
-- BATCH
-- =====================================================

INSERT INTO batch
(product_id, supplier_id, quantity, inventory_id, storage_location_descrption, last_action_by)
VALUES
((SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow' LIMIT 1), 407392001, 50, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A1', 'system'),
((SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head' LIMIT 1), 407392002, 40, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A2', 'system'),
((SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 407392003, 200, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B1', 'system'),
((SELECT product_id FROM product WHERE name = 'Valtec Elbow 1/2 inch' LIMIT 1), 407392002, 300, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B3', 'system'),
((SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 407392001, 80, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A3', 'system'),
((SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer' LIMIT 1), 407392002, 120, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Main Warehouse - Ramallah' LIMIT 1), 'Rack A4', 'system'),
((SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 407392008, 35, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B4', 'system'),
((SELECT product_id FROM product WHERE name = 'Ideal Standard Bathtub Mixer' LIMIT 1), 407392007, 25, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Secondary Storage - Nablus' LIMIT 1), 'Rack B5', 'system'),
((SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 407392009, 150, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Hebron Distribution Center' LIMIT 1), 'Rack C1', 'system'),
((SELECT product_id FROM product WHERE name = 'Akman T-Joint 3/4 inch' LIMIT 1), 407392010, 200, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Hebron Distribution Center' LIMIT 1), 'Rack C2', 'system'),
((SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 407392008, 15, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Bethlehem Storage Facility' LIMIT 1), 'Rack D1', 'system'),
((SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), 407392006, 8, (SELECT inventory_id FROM inventory WHERE inventory_location = 'Bethlehem Storage Facility' LIMIT 1), 'Rack D2', 'system');

-- =====================================================
-- INCOMING PAYMENT
-- =====================================================

INSERT INTO incoming_payment
(customer_id, amount, date_time, description, last_action_by)
VALUES
(409223118, 900, NOW(), 'Payment for mixers', 'system'),
(408554321, 1200, NOW(), 'Pipe supplies payment', 'system'),
(407667655, 1500, NOW() - INTERVAL '2 days', 'Advance payment', 'system'),
(406900221, 800, NOW() - INTERVAL '1 day', 'Partial payment for order', 'system'),
(408123456, 600, NOW() - INTERVAL '5 days', 'Check payment', 'system'),
(409445566, 2000, NOW(), 'Full order payment', 'system'),
(408667788, 450, NOW() - INTERVAL '3 days', 'Cash payment', 'system');

-- =====================================================
-- OUTGOING PAYMENT
-- =====================================================

INSERT INTO outgoing_payment
(supplier_id, amount, date_time, description, last_action_by)
VALUES
(407392001, 1400, NOW(), 'Payment for shower heads', 'system'),
(407392002, 800, NOW(), 'Payment for pipes', 'system'),
(407392003, 950, NOW() - INTERVAL '1 day', 'Payment for bathroom accessories', 'system'),
(407392005, 1200, NOW() - INTERVAL '2 days', 'Valve shipment payment', 'system'),
(407392007, 700, NOW() - INTERVAL '4 days', 'Sanitary ware payment', 'system'),
(407392009, 2500, NOW(), 'Large pipe order payment', 'system'),
(407392006, 1800, NOW() - INTERVAL '3 days', 'Pump systems payment', 'system');

-- =====================================================
-- CUSTOMER CHECKS
-- =====================================================

INSERT INTO customer_checks
(customer_id, bank_id, bank_branch, exchange_rate, exchange_date, status, description, last_action_by)
VALUES
(409223118, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Ramallah Branch' LIMIT 1), 900, NOW(), 'Cashed', 'Customer paid for mixers', 'system'),
(408554321, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Nablus Branch' LIMIT 1), 1200, NOW(), 'Returned', 'Customer bounced check', 'system'),
(407667655, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Arab Bank' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Ramallah Main Branch' LIMIT 1), 1500, NOW() + INTERVAL '15 days', 'Company Box', 'Check in company box', 'system'),
(406900221, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Al-Bireh Branch' LIMIT 1), 800, NOW() - INTERVAL '5 days', 'Cashed', 'Payment cleared', 'system'),
(408123456, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Nablus Central' LIMIT 1), 600, NOW() + INTERVAL '30 days', 'Endorsed', 'Endorsed check', 'system'),
(409445566, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Hebron Branch' LIMIT 1), 2000, NOW(), 'Cashed', 'Large order payment', 'system'),
(408667788, (SELECT bank_id FROM customer_banks WHERE bank_name = 'Palestine Islamic Bank' LIMIT 1), (SELECT branch_id FROM customer_branches WHERE address = 'Jenin Branch' LIMIT 1), 450, NOW() - INTERVAL '2 days', 'Cashed', 'Quick payment', 'system');

-- =====================================================
-- SUPPLIER CHECKS
-- =====================================================

INSERT INTO supplier_checks
(supplier_id, bank_id, bank_branch, exchange_rate, exchange_date, status, description, last_action_by)
VALUES
(407392004, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Ramallah Branch' LIMIT 1), 1400, NOW(), 'Cashed', 'Payment for GROHE shipment', 'system'),
(407392002, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Nablus Branch' LIMIT 1), 800, NOW(), 'pending', 'Payment for PPR pipes', 'system'),
(407392003, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Arab Bank' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Bethlehem Branch' LIMIT 1), 950, NOW() + INTERVAL '10 days', 'pending', 'Post-dated for accessories', 'system'),
(407392005, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Cairo Amman Bank' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Jenin Branch' LIMIT 1), 1200, NOW() - INTERVAL '3 days', 'Cashed', 'Valve payment cleared', 'system'),
(407392007, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Bank of Palestine' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Ramallah Branch' LIMIT 1), 700, NOW(), 'Cashed', 'Sanitary ware payment', 'system'),
(407392009, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Quds Bank' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Hebron Branch' LIMIT 1), 2500, NOW() + INTERVAL '20 days', 'pending', 'Large order post-dated', 'system'),
(407392006, (SELECT bank_id FROM supplier_banks WHERE bank_name = 'Arab Bank' LIMIT 1), (SELECT branch_id FROM supplier_branches WHERE address = 'Bethlehem Branch' LIMIT 1), 1800, NOW() - INTERVAL '1 day', 'Cashed', 'Pump payment processed', 'system');

-- =====================================================
-- SUPPLIER ORDER (Various statuses for testing)
-- =====================================================

-- Insert supplier orders and capture their IDs
WITH inserted_orders AS (
  INSERT INTO supplier_order
  (supplier_id, total_cost, order_date, tax_percent, total_balance, order_status, receives_by_id, accountant_id, last_tracing_by)
  VALUES
  -- Today's orders with different statuses
  (407392001, 2500, NOW(), 16, 2900, 'Sent', 406772901, 407392118, 'system'),
  (407392002, 1800, NOW(), 16, 2088, 'Accepted', 406772901, 409882120, 'system'),
  (407392003, 3200, NOW(), 16, 3712, 'Rejected', 406772901, 407392118, 'system'),
  (407392005, 1500, NOW(), 16, 1740, 'Updated', 408334567, 409882120, 'system'),
  (407392007, 2100, NOW(), 16, 2436, 'Sent', 406772901, 408993456, 'system'),
  -- Yesterday's orders
  (407392004, 4500, NOW() - INTERVAL '1 day', 16, 5220, 'Accepted', 408334567, 407392118, 'system'),
  (407392006, 2800, NOW() - INTERVAL '1 day', 16, 3248, 'Hold', 406772901, 409882120, 'system'),
  (407392008, 1900, NOW() - INTERVAL '1 day', 16, 2204, 'Delivered', 408334567, 408993456, 'system'),
  -- Week old orders
  (407392009, 5600, NOW() - INTERVAL '5 days', 16, 6496, 'Delivered', 406772901, 407392118, 'system'),
  (407392010, 3400, NOW() - INTERVAL '6 days', 16, 3944, 'Delivered', 408334567, 409882120, 'system'),
  (407392001, 2200, NOW() - INTERVAL '7 days', 16, 2552, 'Delivered', 406772901, 408993456, 'system'),
  -- Month old orders
  (407392002, 1600, NOW() - INTERVAL '15 days', 16, 1856, 'Delivered', 408334567, 407392118, 'system'),
  (407392003, 2900, NOW() - INTERVAL '20 days', 16, 3364, 'Delivered', 406772901, 409882120, 'system'),
  (407392005, 3700, NOW() - INTERVAL '25 days', 16, 4292, 'Delivered', 408334567, 408993456, 'system')
  RETURNING order_id, supplier_id, order_date
),
ordered_ids AS (
  SELECT order_id, ROW_NUMBER() OVER (ORDER BY order_id) as rn
  FROM inserted_orders
)
-- Insert supplier order descriptions using the generated order IDs
INSERT INTO supplier_order_description
(order_id, product_id, receipt_quantity, quantity, price_per_product, last_tracing_by)
SELECT oi.order_id, product_id, receipt_quantity, quantity, price_per_product, last_tracing_by
FROM (
  VALUES
  -- Order 1 details
  (1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow' LIMIT 1), 0, 50, 35, 'system'),
  (1, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 0, 30, 55, 'system'),
  -- Order 2 details
  (2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 80, 80, 2.5, 'system'),
  (2, (SELECT product_id FROM product WHERE name = 'Valtec Elbow 1/2 inch' LIMIT 1), 150, 150, 1.2, 'system'),
  -- Order 3 details
  (3, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 0, 40, 75, 'system'),
  (3, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head' LIMIT 1), 0, 20, 60, 'system'),
  -- Order 4 details
  (4, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 0, 100, 4.5, 'system'),
  (4, (SELECT product_id FROM product WHERE name = 'Akman T-Joint 3/4 inch' LIMIT 1), 0, 80, 1.5, 'system'),
  -- Order 5 details
  (5, (SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 0, 12, 180, 'system'),
  -- Order 6 details
  (6, (SELECT product_id FROM product WHERE name = 'Delta Electric Water Heater 50L' LIMIT 1), 60, 60, 120, 'system'),
  (6, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 40, 40, 18, 'system'),
  -- Order 7 details
  (7, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 100, 100, 3, 'system'),
  (7, (SELECT product_id FROM product WHERE name = 'Valtec Ball Valve 1 inch' LIMIT 1), 75, 75, 8, 'system'),
  -- Order 8 details
  (8, (SELECT product_id FROM product WHERE name = 'Ideal Standard Bathtub Mixer' LIMIT 1), 30, 30, 65, 'system'),
  -- Order 9 details
  (9, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 40mm' LIMIT 1), 200, 200, 6, 'system'),
  (9, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer' LIMIT 1), 150, 150, 90, 'system'),
  -- Order 10 details
  (10, (SELECT product_id FROM product WHERE name = 'Ideal Standard Pedestal Basin' LIMIT 1), 20, 20, 85, 'system'),
  (10, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 80, 80, 12, 'system'),
  -- Order 11 details
  (11, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 0, 150, 4.5, 'system'),
  (11, (SELECT product_id FROM product WHERE name = 'Akman T-Joint 3/4 inch' LIMIT 1), 0, 200, 1.5, 'system'),
  -- Order 12 details
  (12, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow' LIMIT 1), 0, 100, 35, 'system'),
  (12, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 0, 80, 55, 'system'),
  -- Order 13 details
  (13, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 0, 200, 2.5, 'system'),
  (13, (SELECT product_id FROM product WHERE name = 'Valtec Elbow 1/2 inch' LIMIT 1), 0, 300, 1.2, 'system'),
  -- Order 14 details
  (14, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 0, 35, 75, 'system'),
  (14, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head' LIMIT 1), 0, 40, 60, 'system')
) AS v(order_num, product_id, receipt_quantity, quantity, price_per_product, last_tracing_by)
JOIN ordered_ids oi ON oi.rn = v.order_num;

-- =====================================================
-- CUSTOMER ORDER
-- =====================================================

-- Insert customer orders and capture their IDs
WITH inserted_customer_orders AS (
  INSERT INTO customer_order
  (customer_id, total_cost, tax_percent, total_balance, order_date, order_status, sales_rep_id, delivered_by_id, prepared_by_id, managed_by_id, accountant_id, last_action_by)
  VALUES
  (409223118, 300, 16, 348, NOW(), 'Delivered', 409882311, 408113200, 409552887, 406772901, 407392118, 'system'),
  (408554321, 500, 16, 580, NOW(), 'Prepared', 408771234, 409001122, 408661299, 406772901, 409882120, 'system'),
  (407667655, 850, 16, 986, NOW() - INTERVAL '1 day', 'Delivered', 409882311, 408113200, 409552887, 406772901, 408993456, 'system'),
  (406900221, 1200, 16, 1392, NOW() - INTERVAL '2 days', 'Delivery', 408771234, 409001122, 408661299, 408334567, 407392118, 'system'),
  (408123456, 650, 16, 754, NOW(), 'Prepared', 409334455, 407223344, 407881234, 406772901, 409882120, 'system'),
  (407789012, 400, 16, 464, NOW() - INTERVAL '3 days', 'Delivered', 408998877, 408445566, 409112345, 408334567, 408993456, 'system'),
  (409445566, 2100, 16, 2436, NOW(), 'Received', 409882311, NULL, 409552887, 406772901, 407392118, 'system'),
  (408667788, 750, 16, 870, NOW() - INTERVAL '5 days', 'Delivered', 408771234, 408113200, 408661299, 406772901, 409882120, 'system')
  RETURNING customer_order_id
),
customer_ordered_ids AS (
  SELECT customer_order_id, ROW_NUMBER() OVER (ORDER BY customer_order_id) as rn
  FROM inserted_customer_orders
)
-- Insert customer order descriptions using the generated order IDs
INSERT INTO customer_order_description
(customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_action_by)
SELECT coi.customer_order_id, product_id, delivered_quantity, quantity, total_price, delivered_date, last_tracing_by
FROM (
  VALUES
  -- Order 1
  (1, (SELECT product_id FROM product WHERE name = 'GROHE Hand Shower 3-Flow' LIMIT 1), 2, 2, 98, NOW(), 'system'),
  (1, (SELECT product_id FROM product WHERE name = 'GROHE Basin Mixer Chrome' LIMIT 1), 1, 1, 80, NOW(), 'system'),
  -- Order 2
  (2, (SELECT product_id FROM product WHERE name = 'Firat PPR Pipe 20mm' LIMIT 1), 30, 30, 120, NOW(), 'system'),
  (2, (SELECT product_id FROM product WHERE name = 'Valtec Elbow 1/2 inch' LIMIT 1), 10, 10, 20, NOW(), 'system'),
  -- Order 3
  (3, (SELECT product_id FROM product WHERE name = 'Roca Shower Set Complete' LIMIT 1), 8, 8, 880, NOW() - INTERVAL '1 day', 'system'),
  -- Order 4
  (4, (SELECT product_id FROM product WHERE name = 'Wavin PPR Pipe 32mm' LIMIT 1), 50, 50, 350, NOW() - INTERVAL '2 days', 'system'),
  (4, (SELECT product_id FROM product WHERE name = 'Akman T-Joint 3/4 inch' LIMIT 1), 20, 20, 50, NOW() - INTERVAL '2 days', 'system'),
  -- Order 5
  (5, (SELECT product_id FROM product WHERE name = 'Hansgrohe Soap Dispenser' LIMIT 1), 15, 15, 420, NOW(), 'system'),
  (5, (SELECT product_id FROM product WHERE name = 'Hansgrohe Rain Shower Head' LIMIT 1), 3, 3, 255, NOW(), 'system'),
  -- Order 6
  (6, (SELECT product_id FROM product WHERE name = 'Kalde PPR Pipe 25mm' LIMIT 1), 25, 25, 112.5, NOW() - INTERVAL '3 days', 'system'),
  (6, (SELECT product_id FROM product WHERE name = 'GROHE Towel Holder Chrome' LIMIT 1), 12, 12, 216, NOW() - INTERVAL '3 days', 'system'),
  -- Order 7
  (7, (SELECT product_id FROM product WHERE name = 'Roca Wall Hung Toilet' LIMIT 1), 8, 8, 2160, NOW(), 'system'),
  -- Order 8
  (8, (SELECT product_id FROM product WHERE name = 'Hansgrohe Kitchen Mixer' LIMIT 1), 5, 5, 650, NOW() - INTERVAL '5 days', 'system'),
  (8, (SELECT product_id FROM product WHERE name = 'Ideal Standard Bathtub Mixer' LIMIT 1), 2, 2, 190, NOW() - INTERVAL '5 days', 'system')
) AS v(order_num, product_id, delivered_quantity, quantity, total_price, delivered_date, last_tracing_by)
JOIN customer_ordered_ids coi ON coi.rn = v.order_num;

-- =====================================================
-- USER ACCOUNT TABLES (PASSWORD = '1234')
-- =====================================================

INSERT INTO user_account_accountant VALUES
(407392118, '1234', 'system', NOW()),
(409882120, '1234', 'system', NOW()),
(408993456, '1234', 'system', NOW());

INSERT INTO user_account_delivery_driver VALUES
(408113200, '1234', 'yes', 'system', NOW()),
(409001122, '1234', 'yes', 'system', NOW()),
(407223344, '1234', 'yes', 'system', NOW()),
(408445566, '1234', 'yes', 'system', NOW());

INSERT INTO user_account_storage_manager VALUES
(406772901, '1234', 'yes', 'system', NOW()),
(408334567, '1234', 'yes', 'system', NOW());

INSERT INTO user_account_storage_staff VALUES
(409552887, '1234', 'yes', 'system', NOW()),
(408661299, '1234', 'yes', 'system', NOW()),
(407881234, '1234', 'yes', 'system', NOW()),
(409112345, '1234', 'yes', 'system', NOW());

INSERT INTO user_account_supplier VALUES
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

INSERT INTO user_account_sales_rep VALUES
(409882311, '1234', 'yes', 'system', NOW()),
(408771234, '1234', 'yes', 'system', NOW()),
(407556789, '1234', 'yes', 'system', NOW()),
(409334455, '1234', 'yes', 'system', NOW()),
(408998877, '1234', 'yes', 'system', NOW());

INSERT INTO user_account_customer VALUES
(409223118, '1234', 'yes', 'system', NOW()),
(408554321, '1234', 'yes', 'system', NOW()),
(407667655, '1234', 'yes', 'system', NOW()),
(406900221, '1234', 'yes', 'system', NOW()),
(408123456, '1234', 'yes', 'system', NOW()),
(407789012, '1234', 'yes', 'system', NOW()),
(409445566, '1234', 'yes', 'system', NOW()),
(408667788, '1234', 'yes', 'system', NOW()),
(407334455, '1234', 'yes', 'system', NOW()),
(409556677, '1234', 'yes', 'system', NOW());
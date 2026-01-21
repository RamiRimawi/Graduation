-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.accountant (
  accountant_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT accountant_pkey PRIMARY KEY (accountant_id),
  CONSTRAINT accountant_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.accounts (
  user_id bigint NOT NULL,
  password text NOT NULL,
  type USER-DEFINED,
  is_active boolean,
  profile_image text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT accounts_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.banks (
  bank_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_name character varying NOT NULL,
  CONSTRAINT banks_pkey PRIMARY KEY (bank_id)
);
CREATE TABLE public.batch (
  batch_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  product_id integer NOT NULL,
  supplier_id integer,
  quantity integer,
  inventory_id integer,
  storage_location_descrption character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  expiry_date date,
  production_date date,
  CONSTRAINT batch_pkey PRIMARY KEY (batch_id, product_id),
  CONSTRAINT batch_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id),
  CONSTRAINT batch_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT batch_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id)
);
CREATE TABLE public.branches (
  branch_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_id integer NOT NULL,
  address character varying,
  CONSTRAINT branches_pkey PRIMARY KEY (branch_id),
  CONSTRAINT Branchs_Bank_ID_fkey FOREIGN KEY (bank_id) REFERENCES public.banks(bank_id)
);
CREATE TABLE public.brand (
  brand_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT brand_pkey PRIMARY KEY (brand_id)
);
CREATE TABLE public.customer (
  customer_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  customer_city integer,
  address text,
  latitude_location double precision,
  longitude_location double precision,
  email character varying,
  balance_debit numeric,
  sales_rep_id integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_pkey PRIMARY KEY (customer_id),
  CONSTRAINT customer_customer_city_fkey FOREIGN KEY (customer_city) REFERENCES public.customer_city(customer_city_id),
  CONSTRAINT customer_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.sales_representative(sales_rep_id),
  CONSTRAINT customer_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.customer_checks (
  check_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id integer,
  bank_id integer,
  bank_branch integer,
  check_image text DEFAULT ''::text,
  exchange_rate numeric,
  exchange_date date,
  status USER-DEFINED,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  endorsed_to integer,
  endorsed_description text,
  CONSTRAINT customer_checks_pkey PRIMARY KEY (check_id),
  CONSTRAINT customer_checks_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id),
  CONSTRAINT customer_checks_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.banks(bank_id),
  CONSTRAINT customer_checks_bank_branch_fkey FOREIGN KEY (bank_branch) REFERENCES public.branches(branch_id),
  CONSTRAINT customer_checks_endorsed _to_fkey FOREIGN KEY (endorsed_to) REFERENCES public.supplier(supplier_id),
  CONSTRAINT customer_checks_endorsed_to_fkey FOREIGN KEY (endorsed_to) REFERENCES public.supplier(supplier_id)
);
CREATE TABLE public.customer_city (
  customer_city_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_city_pkey PRIMARY KEY (customer_city_id)
);
CREATE TABLE public.customer_order (
  customer_order_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id integer,
  total_cost numeric,
  tax_percent integer,
  total_balance numeric,
  order_date timestamp without time zone,
  order_status USER-DEFINED,
  customer_signature bytea,
  sales_rep_id integer,
  delivered_by_id integer,
  prepared_by_id integer,
  managed_by_id integer,
  accountant_id integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  discount_value real DEFAULT 0,
  update_action text,
  update_description text,
  CONSTRAINT customer_order_pkey PRIMARY KEY (customer_order_id),
  CONSTRAINT customer_order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id),
  CONSTRAINT customer_order_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.sales_representative(sales_rep_id),
  CONSTRAINT customer_order_delivered_by_id_fkey FOREIGN KEY (delivered_by_id) REFERENCES public.delivery_driver(delivery_driver_id),
  CONSTRAINT customer_order_prepared_by_id_fkey FOREIGN KEY (prepared_by_id) REFERENCES public.storage_staff(storage_staff_id),
  CONSTRAINT customer_order_managed_by_id_fkey FOREIGN KEY (managed_by_id) REFERENCES public.storage_manager(storage_manager_id),
  CONSTRAINT customer_order_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accountant(accountant_id)
);
CREATE TABLE public.customer_order_description (
  customer_order_id integer NOT NULL,
  product_id integer NOT NULL,
  delivered_quantity integer,
  quantity integer,
  total_price numeric,
  delivered_date timestamp without time zone,
  last_action_by text,
  last_action_time timestamp without time zone,
  updated_quantity integer,
  CONSTRAINT customer_order_description_pkey PRIMARY KEY (customer_order_id, product_id),
  CONSTRAINT customer_order_description_customer_order_id_fkey FOREIGN KEY (customer_order_id) REFERENCES public.customer_order(customer_order_id),
  CONSTRAINT customer_order_description_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id)
);
CREATE TABLE public.customer_order_inventory (
  customer_order_id integer NOT NULL,
  product_id integer NOT NULL,
  inventory_id integer NOT NULL,
  batch_id integer,
  quantity integer,
  prepared_by integer,
  prepared_quantity integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_order_inventory_pkey PRIMARY KEY (customer_order_id, product_id, inventory_id),
  CONSTRAINT customer_order_inventory_customer_order_id_fkey FOREIGN KEY (customer_order_id) REFERENCES public.customer_order(customer_order_id),
  CONSTRAINT customer_order_inventory_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id),
  CONSTRAINT customer_order_inventory_product_id_batch_id_fkey FOREIGN KEY (product_id) REFERENCES public.batch(batch_id),
  CONSTRAINT customer_order_inventory_product_id_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(batch_id),
  CONSTRAINT customer_order_inventory_product_id_batch_id_fkey FOREIGN KEY (product_id) REFERENCES public.batch(product_id),
  CONSTRAINT customer_order_inventory_product_id_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(product_id),
  CONSTRAINT customer_order_inventory_prepared_by_fkey FOREIGN KEY (prepared_by) REFERENCES public.storage_staff(storage_staff_id)
);
CREATE TABLE public.customer_quarters (
  quarter_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  customer_city integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_quarters_pkey PRIMARY KEY (quarter_id),
  CONSTRAINT customer_quarters_customer_city_fkey FOREIGN KEY (customer_city) REFERENCES public.customer_city(customer_city_id)
);
CREATE TABLE public.damaged_products (
  meeting_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  batch_id integer,
  quantity integer,
  reason text,
  product_id integer,
  CONSTRAINT damaged_products_batch_id_product_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(batch_id),
  CONSTRAINT damaged_products_batch_id_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.batch(batch_id),
  CONSTRAINT damaged_products_batch_id_product_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(product_id),
  CONSTRAINT damaged_products_batch_id_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.batch(product_id)
);
CREATE TABLE public.damaged_products_meeting (
  meeting_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  meeting_address text,
  meeting_time timestamp without time zone,
  meeting_topics text,
  result_of_meeting text,
  CONSTRAINT damaged_products_meeting_pkey PRIMARY KEY (meeting_id)
);
CREATE TABLE public.delivery_driver (
  delivery_driver_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  longitude_location double precision,
  latitude_location double precision,
  current_order_id integer,
  CONSTRAINT delivery_driver_pkey PRIMARY KEY (delivery_driver_id),
  CONSTRAINT delivery_driver_current_order_id_fkey FOREIGN KEY (current_order_id) REFERENCES public.customer_order(customer_order_id),
  CONSTRAINT delivery_driver_delivery_driver_id_fkey FOREIGN KEY (delivery_driver_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.delivery_vehicle (
  plate_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  delivery_driver_id integer NOT NULL,
  from_date date NOT NULL,
  to_date date NOT NULL,
  CONSTRAINT delivery_vehicle_pkey PRIMARY KEY (plate_id, delivery_driver_id, from_date, to_date),
  CONSTRAINT delivery_vehicle_delivery_driver_id_fkey FOREIGN KEY (delivery_driver_id) REFERENCES public.delivery_driver(delivery_driver_id),
  CONSTRAINT delivery_vehicle_plate_id_fkey FOREIGN KEY (plate_id) REFERENCES public.vehicle(plate_id)
);
CREATE TABLE public.incoming_payment (
  payment_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id integer,
  amount numeric,
  date_time timestamp without time zone,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  payment_method USER-DEFINED DEFAULT 'cash'::payment_method_enum,
  check_id integer,
  CONSTRAINT incoming_payment_pkey PRIMARY KEY (payment_id),
  CONSTRAINT incoming_payment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id),
  CONSTRAINT incoming_payment_check_id_fkey FOREIGN KEY (check_id) REFERENCES public.customer_checks(check_id)
);
CREATE TABLE public.inventory (
  inventory_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  inventory_name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id)
);
CREATE TABLE public.meeting_memeber (
  meeting_id bigint NOT NULL,
  member_id bigint NOT NULL,
  type USER-DEFINED,
  CONSTRAINT meeting_memeber_pkey PRIMARY KEY (meeting_id, member_id),
  CONSTRAINT meeting_memeber_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.accounts(user_id),
  CONSTRAINT meeting_memeber_meeting_id_fkey FOREIGN KEY (meeting_id) REFERENCES public.damaged_products_meeting(meeting_id)
);
CREATE TABLE public.outgoing_payment (
  payment_voucher_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  supplier_id integer,
  amount numeric,
  date_time timestamp without time zone,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  payment_method USER-DEFINED DEFAULT 'cash'::payment_method_enum,
  check_id integer,
  CONSTRAINT outgoing_payment_pkey PRIMARY KEY (payment_voucher_id),
  CONSTRAINT outgoing_payment_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT outgoing_payment_check_id_fkey FOREIGN KEY (check_id) REFERENCES public.supplier_checks(check_id)
);
CREATE TABLE public.product (
  product_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id integer,
  name character varying,
  brand_id integer,
  wholesale_price numeric,
  selling_price numeric,
  minimum_profit_percent numeric,
  unit_id integer,
  is_active boolean,
  last_action_by text,
  last_action_time timestamp without time zone,
  total_quantity integer,
  product_image text,
  minimum_stock integer,
  CONSTRAINT product_pkey PRIMARY KEY (product_id),
  CONSTRAINT product_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.product_category(product_category_id),
  CONSTRAINT product_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brand(brand_id),
  CONSTRAINT product_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.unit(unit_id)
);
CREATE TABLE public.product_category (
  product_category_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT product_category_pkey PRIMARY KEY (product_category_id)
);
CREATE TABLE public.sales_rep_city (
  sales_rep_city_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT sales_rep_city_pkey PRIMARY KEY (sales_rep_city_id)
);
CREATE TABLE public.sales_representative (
  sales_rep_id integer NOT NULL,
  sales_rep_city integer,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  email character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT sales_representative_pkey PRIMARY KEY (sales_rep_id),
  CONSTRAINT sales_representative_sales_rep_city_fkey FOREIGN KEY (sales_rep_city) REFERENCES public.sales_rep_city(sales_rep_city_id),
  CONSTRAINT sales_representative_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.storage_manager (
  storage_manager_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT storage_manager_pkey PRIMARY KEY (storage_manager_id),
  CONSTRAINT storage_manager_storage_manager_id_fkey FOREIGN KEY (storage_manager_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.storage_staff (
  storage_staff_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  inventory_id integer NOT NULL,
  CONSTRAINT storage_staff_pkey PRIMARY KEY (storage_staff_id),
  CONSTRAINT storage_staff_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id),
  CONSTRAINT storage_staff_storage_staff_id_fkey FOREIGN KEY (storage_staff_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.supplier (
  supplier_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  supplier_city integer,
  address text,
  email character varying,
  creditor_balance numeric,
  supplier_category_id integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT supplier_pkey PRIMARY KEY (supplier_id),
  CONSTRAINT supplier_supplier_city_fkey FOREIGN KEY (supplier_city) REFERENCES public.supplier_city(supplier_city_id),
  CONSTRAINT supplier_supplier_category_id_fkey FOREIGN KEY (supplier_category_id) REFERENCES public.supplier_category(supplier_category_id),
  CONSTRAINT supplier_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.accounts(user_id)
);
CREATE TABLE public.supplier_category (
  supplier_category_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT supplier_category_pkey PRIMARY KEY (supplier_category_id)
);
CREATE TABLE public.supplier_checks (
  check_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  supplier_id integer,
  bank_id integer,
  bank_branch bigint,
  check_image text,
  exchange_rate numeric,
  exchange_date date,
  status USER-DEFINED,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT supplier_checks_pkey PRIMARY KEY (check_id),
  CONSTRAINT supplier_checks_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT supplier_checks_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.banks(bank_id),
  CONSTRAINT supplier_checks_bank_branch_fkey FOREIGN KEY (bank_branch) REFERENCES public.branches(branch_id)
);
CREATE TABLE public.supplier_city (
  supplier_city_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT supplier_city_pkey PRIMARY KEY (supplier_city_id)
);
CREATE TABLE public.supplier_order (
  order_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  supplier_id integer,
  total_cost numeric,
  order_date timestamp without time zone,
  tax_percent integer,
  total_balance numeric,
  order_status USER-DEFINED,
  created_by_id integer,
  receives_by_id integer,
  accountant_id integer,
  last_tracing_by text,
  last_tracing_time timestamp without time zone,
  updated_description text,
  CONSTRAINT supplier_order_pkey PRIMARY KEY (order_id),
  CONSTRAINT supplier_order_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT supplier_order_receives_by_id_fkey FOREIGN KEY (receives_by_id) REFERENCES public.storage_manager(storage_manager_id),
  CONSTRAINT supplier_order_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accountant(accountant_id)
);
CREATE TABLE public.supplier_order_description (
  order_id integer NOT NULL,
  product_id integer NOT NULL,
  receipt_quantity integer,
  quantity integer,
  price_per_product numeric,
  last_tracing_by text,
  last_tracing_time timestamp without time zone,
  updated_quantity integer,
  CONSTRAINT supplier_order_description_pkey PRIMARY KEY (order_id, product_id),
  CONSTRAINT supplier_order_description_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.supplier_order(order_id),
  CONSTRAINT supplier_order_description_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id)
);
CREATE TABLE public.supplier_order_inventory (
  supplier_order_id integer NOT NULL,
  product_id integer NOT NULL,
  inventory_id integer NOT NULL,
  batch_id integer,
  quantity integer,
  CONSTRAINT supplier_order_inventory_pkey PRIMARY KEY (supplier_order_id, product_id, inventory_id),
  CONSTRAINT supplier_order_inventory_supplier_order_id_fkey FOREIGN KEY (supplier_order_id) REFERENCES public.supplier_order(order_id),
  CONSTRAINT supplier_order_inventory_product_id_Batch_ID_fkey FOREIGN KEY (product_id) REFERENCES public.batch(batch_id),
  CONSTRAINT supplier_order_inventory_product_id_Batch_ID_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(batch_id),
  CONSTRAINT supplier_order_inventory_product_id_Batch_ID_fkey FOREIGN KEY (product_id) REFERENCES public.batch(product_id),
  CONSTRAINT supplier_order_inventory_product_id_Batch_ID_fkey FOREIGN KEY (batch_id) REFERENCES public.batch(product_id),
  CONSTRAINT supplier_order_inventory_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id)
);
CREATE TABLE public.unit (
  unit_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  unit_name USER-DEFINED,
  CONSTRAINT unit_pkey PRIMARY KEY (unit_id)
);
CREATE TABLE public.vehicle (
  plate_id bigint NOT NULL,
  model text,
  brand text,
  is_active boolean,
  vehicle_image text,
  CONSTRAINT vehicle_pkey PRIMARY KEY (plate_id)
);
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
  CONSTRAINT accountant_pkey PRIMARY KEY (accountant_id)
);
CREATE TABLE public.batch (
  batch_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  product_id integer,
  supplier_id integer,
  quantity integer,
  inventory_id integer,
  storage_location_descrption character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT batch_pkey PRIMARY KEY (batch_id),
  CONSTRAINT batch_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id),
  CONSTRAINT batch_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT batch_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id)
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
  latitude_location numeric,
  longitude_location numeric,
  email character varying,
  balance_debit numeric,
  sales_rep_id integer,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_pkey PRIMARY KEY (customer_id),
  CONSTRAINT customer_customer_city_fkey FOREIGN KEY (customer_city) REFERENCES public.customer_city(customer_city_id),
  CONSTRAINT customer_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.sales_representative(sales_rep_id)
);
CREATE TABLE public.customer_banks (
  bank_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_name character varying,
  CONSTRAINT customer_banks_pkey PRIMARY KEY (bank_id)
);
CREATE TABLE public.customer_branches (
  branch_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_id integer,
  address character varying,
  CONSTRAINT customer_branches_pkey PRIMARY KEY (branch_id),
  CONSTRAINT customer_branches_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.customer_banks(bank_id)
);
CREATE TABLE public.customer_checks (
  check_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id integer,
  bank_id integer,
  bank_branch integer,
  check_image bytea,
  exchange_rate numeric,
  exchange_date date,
  status USER-DEFINED,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_checks_pkey PRIMARY KEY (check_id),
  CONSTRAINT customer_checks_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id),
  CONSTRAINT customer_checks_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.customer_banks(bank_id),
  CONSTRAINT customer_checks_bank_branch_fkey FOREIGN KEY (bank_branch) REFERENCES public.customer_branches(branch_id)
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
  CONSTRAINT customer_order_pkey PRIMARY KEY (customer_order_id),
  CONSTRAINT customer_order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id),
  CONSTRAINT customer_order_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.sales_representative(sales_rep_id),
  CONSTRAINT customer_order_delivered_by_id_fkey FOREIGN KEY (delivered_by_id) REFERENCES public.delivery_driver(delivery_driver_id),
  CONSTRAINT customer_order_prepared_by_id_fkey FOREIGN KEY (prepared_by_id) REFERENCES public.storage_staff(storage_staff_id),
  CONSTRAINT customer_order_managed_by_id_fkey FOREIGN KEY (managed_by_id) REFERENCES public.storage_manager(storage_manager_id),
  CONSTRAINT customer_order_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accountant(accountant_id)
);
CREATE TABLE public.customer_order_description (
  customer_order_description_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_order_id integer,
  product_id integer,
  delivered_quantity integer,
  quantity integer,
  total_price numeric,
  delivered_date timestamp without time zone,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT customer_order_description_pkey PRIMARY KEY (customer_order_description_id),
  CONSTRAINT customer_order_description_customer_order_id_fkey FOREIGN KEY (customer_order_id) REFERENCES public.customer_order(customer_order_id),
  CONSTRAINT customer_order_description_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id)
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
CREATE TABLE public.delivery_driver (
  delivery_driver_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT delivery_driver_pkey PRIMARY KEY (delivery_driver_id)
);
CREATE TABLE public.incoming_payment (
  payment_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id integer,
  amount numeric,
  date_time timestamp without time zone,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT incoming_payment_pkey PRIMARY KEY (payment_id),
  CONSTRAINT incoming_payment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id)
);
CREATE TABLE public.inventory (
  inventory_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  inventory_location character varying,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id)
);
CREATE TABLE public.outgoing_payment (
  payment_voucher_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  supplier_id integer,
  amount numeric,
  date_time timestamp without time zone,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT outgoing_payment_pkey PRIMARY KEY (payment_voucher_id),
  CONSTRAINT outgoing_payment_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id)
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
  CONSTRAINT sales_representative_sales_rep_city_fkey FOREIGN KEY (sales_rep_city) REFERENCES public.sales_rep_city(sales_rep_city_id)
);
CREATE TABLE public.storage_manager (
  storage_manager_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT storage_manager_pkey PRIMARY KEY (storage_manager_id)
);
CREATE TABLE public.storage_staff (
  storage_staff_id integer NOT NULL,
  name character varying,
  mobile_number character varying,
  telephone_number character varying,
  address text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT storage_staff_pkey PRIMARY KEY (storage_staff_id)
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
  CONSTRAINT supplier_supplier_category_id_fkey FOREIGN KEY (supplier_category_id) REFERENCES public.supplier_category(supplier_category_id)
);
CREATE TABLE public.supplier_banks (
  bank_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_name character varying,
  CONSTRAINT supplier_banks_pkey PRIMARY KEY (bank_id)
);
CREATE TABLE public.supplier_branches (
  branch_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  bank_id integer,
  address character varying,
  CONSTRAINT supplier_branches_pkey PRIMARY KEY (branch_id),
  CONSTRAINT supplier_branches_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.supplier_banks(bank_id)
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
  bank_branch integer,
  check_image bytea,
  exchange_rate numeric,
  exchange_date date,
  status USER-DEFINED,
  description text,
  last_action_by text,
  last_action_time timestamp without time zone,
  CONSTRAINT supplier_checks_pkey PRIMARY KEY (check_id),
  CONSTRAINT supplier_checks_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT supplier_checks_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES public.supplier_banks(bank_id),
  CONSTRAINT supplier_checks_bank_branch_fkey FOREIGN KEY (bank_branch) REFERENCES public.supplier_branches(branch_id)
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
  CONSTRAINT supplier_order_pkey PRIMARY KEY (order_id),
  CONSTRAINT supplier_order_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id),
  CONSTRAINT supplier_order_receives_by_id_fkey FOREIGN KEY (receives_by_id) REFERENCES public.storage_manager(storage_manager_id),
  CONSTRAINT supplier_order_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accountant(accountant_id)
);
CREATE TABLE public.supplier_order_description (
  order_in_products_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  order_id integer,
  product_id integer,
  receipt_quantity integer,
  quantity integer,
  price_per_product numeric,
  last_tracing_by text,
  last_tracing_time timestamp without time zone,
  CONSTRAINT supplier_order_description_pkey PRIMARY KEY (order_in_products_id),
  CONSTRAINT supplier_order_description_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.supplier_order(order_id),
  CONSTRAINT supplier_order_description_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id)
);
CREATE TABLE public.unit (
  unit_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  unit_name USER-DEFINED,
  CONSTRAINT unit_pkey PRIMARY KEY (unit_id)
);
CREATE TABLE public.user_account_accountant (
  accountant_id integer NOT NULL,
  password character varying,
  added_by text,
  added_time timestamp without time zone,
  is_active USER-DEFINED NOT NULL DEFAULT 'yes'::yes_no_enum,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_accountant_pkey PRIMARY KEY (accountant_id),
  CONSTRAINT user_account_accountant_accountant_id_fkey FOREIGN KEY (accountant_id) REFERENCES public.accountant(accountant_id)
);
CREATE TABLE public.user_account_customer (
  customer_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_customer_pkey PRIMARY KEY (customer_id),
  CONSTRAINT user_account_customer_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id)
);
CREATE TABLE public.user_account_delivery_driver (
  delivery_driver_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_delivery_driver_pkey PRIMARY KEY (delivery_driver_id),
  CONSTRAINT user_account_delivery_driver_delivery_driver_id_fkey FOREIGN KEY (delivery_driver_id) REFERENCES public.delivery_driver(delivery_driver_id)
);
CREATE TABLE public.user_account_sales_rep (
  sales_rep_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_sales_rep_pkey PRIMARY KEY (sales_rep_id),
  CONSTRAINT user_account_sales_rep_sales_rep_id_fkey FOREIGN KEY (sales_rep_id) REFERENCES public.sales_representative(sales_rep_id)
);
CREATE TABLE public.user_account_storage_manager (
  storage_manager_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_storage_manager_pkey PRIMARY KEY (storage_manager_id),
  CONSTRAINT user_account_storage_manager_storage_manager_id_fkey FOREIGN KEY (storage_manager_id) REFERENCES public.storage_manager(storage_manager_id)
);
CREATE TABLE public.user_account_storage_staff (
  storage_staff_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_storage_staff_pkey PRIMARY KEY (storage_staff_id),
  CONSTRAINT user_account_storage_staff_storage_staff_id_fkey FOREIGN KEY (storage_staff_id) REFERENCES public.storage_staff(storage_staff_id)
);
CREATE TABLE public.user_account_supplier (
  supplier_id integer NOT NULL,
  password character varying,
  is_active USER-DEFINED,
  added_by text,
  added_time timestamp without time zone,
  profile_image text DEFAULT ' https://xwfvdalvmxcrhevaymkm.supabase.co/storage/v1/object/public/images/logo.png'::text,
  CONSTRAINT user_account_supplier_pkey PRIMARY KEY (supplier_id),
  CONSTRAINT user_account_supplier_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id)
);
-- Migration: Add last_action tracking to customer_order_inventory table
-- Purpose: Track who and when made changes to order inventory allocations
-- Date: 2025-12-25

-- Add last_action_by column to customer_order_inventory
ALTER TABLE public.customer_order_inventory 
ADD COLUMN IF NOT EXISTS last_action_by text;

-- Add last_action_time column to customer_order_inventory
ALTER TABLE public.customer_order_inventory 
ADD COLUMN IF NOT EXISTS last_action_time timestamp without time zone;

-- Update existing records with default values (optional)
-- You may want to set these to the manager who created them if that information is available
UPDATE public.customer_order_inventory 
SET last_action_by = 'System Migration',
    last_action_time = NOW()
WHERE last_action_by IS NULL;

-- Add comment to document the columns
COMMENT ON COLUMN public.customer_order_inventory.last_action_by IS 'Name of the user who last modified this inventory allocation';
COMMENT ON COLUMN public.customer_order_inventory.last_action_time IS 'Timestamp when this inventory allocation was last modified';

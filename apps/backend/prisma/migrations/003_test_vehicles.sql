-- FROGIO Database Migration 003: Test Vehicles
-- Add 2 test vehicles for admin testing
-- Date: 2026-01-26
--
-- Run this script from the local network:
-- cd /Users/drozast/frogio/apps/backend/prisma
-- PGPASSWORD='N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=' psql -h 192.168.31.115 -p 5432 -U frogio -d frogio -f migrations/003_test_vehicles.sql

-- Get admin user ID and insert test vehicles
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get the admin user ID
    SELECT id INTO admin_user_id
    FROM santa_juana.users
    WHERE role = 'admin' AND is_active = true
    LIMIT 1;

    -- If no admin found, try to get any active user
    IF admin_user_id IS NULL THEN
        SELECT id INTO admin_user_id
        FROM santa_juana.users
        WHERE is_active = true
        LIMIT 1;
    END IF;

    -- Only proceed if we have a user
    IF admin_user_id IS NOT NULL THEN
        -- Insert test vehicle 1: Camioneta Municipal
        INSERT INTO santa_juana.vehicles
            (owner_id, plate, brand, model, year, color, vehicle_type, vin, is_active)
        VALUES
            (admin_user_id, 'KXYZ-12', 'Toyota', 'Hilux', 2022, 'Blanco', 'camioneta', 'VIN2022HILUX001', true)
        ON CONFLICT (plate) DO NOTHING;

        -- Insert test vehicle 2: Automóvil Municipal
        INSERT INTO santa_juana.vehicles
            (owner_id, plate, brand, model, year, color, vehicle_type, vin, is_active)
        VALUES
            (admin_user_id, 'ABCD-34', 'Chevrolet', 'Sail', 2021, 'Gris', 'auto', 'VIN2021SAIL002', true)
        ON CONFLICT (plate) DO NOTHING;

        RAISE NOTICE 'Test vehicles inserted successfully for owner_id: %', admin_user_id;
    ELSE
        RAISE NOTICE 'No active user found to assign vehicles';
    END IF;
END $$;

-- Verify inserted vehicles
SELECT v.id, v.plate, v.brand, v.model, v.year, v.color, v.vehicle_type, v.is_active,
       u.first_name || ' ' || u.last_name AS owner_name
FROM santa_juana.vehicles v
LEFT JOIN santa_juana.users u ON v.owner_id = u.id
ORDER BY v.created_at DESC;

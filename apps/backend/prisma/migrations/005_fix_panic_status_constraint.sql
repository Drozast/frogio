-- FROGIO Database Migration 005: Fix Panic Alerts Status Constraint
-- Fixes the CHECK constraint on panic_alerts.status that may not include 'dismissed'
-- This happens when table was created before migration 004 added 'dismissed' status
-- Date: 2025-01-27

-- =====================================================
-- FIX: panic_alerts_status_check constraint
-- =====================================================

-- Drop existing constraint (may have been created without 'dismissed')
ALTER TABLE santa_juana.panic_alerts
    DROP CONSTRAINT IF EXISTS panic_alerts_status_check;

-- Re-add constraint with all valid statuses
ALTER TABLE santa_juana.panic_alerts
    ADD CONSTRAINT panic_alerts_status_check
    CHECK (status IN ('active', 'responding', 'resolved', 'cancelled', 'dismissed'));

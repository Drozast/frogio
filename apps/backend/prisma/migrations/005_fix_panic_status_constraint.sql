-- FROGIO Database Migration 005: Fix Database Constraints
-- Fixes CHECK constraints that may be outdated due to CREATE TABLE IF NOT EXISTS
-- Date: 2025-01-27

-- =====================================================
-- FIX: panic_alerts_status_check constraint
-- =====================================================

ALTER TABLE santa_juana.panic_alerts
    DROP CONSTRAINT IF EXISTS panic_alerts_status_check;

ALTER TABLE santa_juana.panic_alerts
    ADD CONSTRAINT panic_alerts_status_check
    CHECK (status IN ('active', 'responding', 'resolved', 'cancelled', 'dismissed'));

-- =====================================================
-- FIX: reports constraints (ensure 'emergencia' type is allowed)
-- =====================================================

ALTER TABLE santa_juana.reports
    DROP CONSTRAINT IF EXISTS reports_type_check;

ALTER TABLE santa_juana.reports
    ADD CONSTRAINT reports_type_check
    CHECK (type IN ('denuncia', 'sugerencia', 'emergencia', 'infraestructura', 'otro'));

ALTER TABLE santa_juana.reports
    DROP CONSTRAINT IF EXISTS reports_status_check;

ALTER TABLE santa_juana.reports
    ADD CONSTRAINT reports_status_check
    CHECK (status IN ('pendiente', 'en_proceso', 'resuelto', 'rechazado'));

ALTER TABLE santa_juana.reports
    DROP CONSTRAINT IF EXISTS reports_priority_check;

ALTER TABLE santa_juana.reports
    ADD CONSTRAINT reports_priority_check
    CHECK (priority IN ('baja', 'media', 'alta', 'urgente'));

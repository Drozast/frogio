-- FROGIO Database Migration 004: Panic Alerts
-- Adds panic_alerts table for SOS emergency system
-- Date: 2025-01-26

-- =====================================================
-- SCHEMA PER TENANT: Panic Alerts Table
-- =====================================================

-- Panic alerts table (alertas de pánico/SOS)
CREATE TABLE IF NOT EXISTS santa_juana.panic_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    message TEXT DEFAULT 'Alerta de emergencia',
    contact_phone VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'responding', 'resolved', 'cancelled', 'dismissed')),
    responder_id UUID REFERENCES santa_juana.users(id) ON DELETE SET NULL,
    responded_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for panic_alerts
CREATE INDEX IF NOT EXISTS idx_panic_alerts_user_id ON santa_juana.panic_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_panic_alerts_status ON santa_juana.panic_alerts(status);
CREATE INDEX IF NOT EXISTS idx_panic_alerts_created_at ON santa_juana.panic_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_panic_alerts_responder_id ON santa_juana.panic_alerts(responder_id);

-- Composite index for active alerts lookup
CREATE INDEX IF NOT EXISTS idx_panic_alerts_active ON santa_juana.panic_alerts(status, created_at DESC)
    WHERE status IN ('active', 'responding');

-- =====================================================
-- Update notifications table type constraint
-- =====================================================

-- Add 'panic' type to notifications if not exists
ALTER TABLE santa_juana.notifications
    DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE santa_juana.notifications
    ADD CONSTRAINT notifications_type_check
    CHECK (type IN ('report', 'infraction', 'citation', 'general', 'urgent', 'panic'));

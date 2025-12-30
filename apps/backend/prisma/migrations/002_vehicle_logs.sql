-- FROGIO Database Migration 002: Vehicle Logs
-- Track vehicle usage for municipal fleet
-- Date: 2024-12-29

-- =====================================================
-- VEHICLE LOGS TABLE: Usage tracking
-- =====================================================

-- Vehicle Usage Logs table (bitácora de vehículos)
CREATE TABLE IF NOT EXISTS santa_juana.vehicle_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES santa_juana.vehicles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    driver_name VARCHAR(255) NOT NULL,
    usage_type VARCHAR(50) NOT NULL CHECK (usage_type IN ('official', 'emergency', 'maintenance', 'transfer', 'other')),
    purpose TEXT,
    start_km DECIMAL(10, 2) NOT NULL,
    end_km DECIMAL(10, 2),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    observations TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicle Log Attachments (photos of km, fuel, etc)
CREATE TABLE IF NOT EXISTS santa_juana.vehicle_log_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_id UUID NOT NULL REFERENCES santa_juana.vehicle_logs(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES santa_juana.files(id) ON DELETE CASCADE,
    attachment_type VARCHAR(50) NOT NULL CHECK (attachment_type IN ('start_km', 'end_km', 'fuel', 'damage', 'other')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_vehicle_logs_vehicle_id ON santa_juana.vehicle_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_logs_driver_id ON santa_juana.vehicle_logs(driver_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_logs_status ON santa_juana.vehicle_logs(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_logs_start_time ON santa_juana.vehicle_logs(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_vehicle_log_attachments_log_id ON santa_juana.vehicle_log_attachments(log_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_vehicle_logs_updated_at BEFORE UPDATE ON santa_juana.vehicle_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- UPDATE FILES TABLE: Add vehicle_log entity type
-- =====================================================

ALTER TABLE santa_juana.files
DROP CONSTRAINT IF EXISTS files_entity_type_check;

ALTER TABLE santa_juana.files
ADD CONSTRAINT files_entity_type_check
CHECK (entity_type IN ('report', 'infraction', 'court_citation', 'medical_record', 'user', 'vehicle_log'));

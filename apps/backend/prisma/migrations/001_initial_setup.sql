-- FROGIO Database Migration 001: Initial Setup
-- Multi-tenant architecture with PostgreSQL schemas
-- Date: 2024-12-14

-- =====================================================
-- SCHEMA PUBLIC: Global tables (Super Admin)
-- =====================================================

-- Tenants table (municipalities)
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(100) UNIQUE,
    subscription_type VARCHAR(20) NOT NULL CHECK (subscription_type IN ('monthly', 'yearly')),
    subscription_status VARCHAR(20) NOT NULL CHECK (subscription_status IN ('active', 'inactive', 'trial')),
    subscription_start TIMESTAMPTZ NOT NULL,
    subscription_end TIMESTAMPTZ,
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    db_schema VARCHAR(100) NOT NULL,
    config JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Super admins table (FROGIO administrators)
CREATE TABLE IF NOT EXISTS public.super_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    avatar TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON public.tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_subscription_status ON public.tenants(subscription_status);
CREATE INDEX IF NOT EXISTS idx_super_admins_email ON public.super_admins(email);

-- =====================================================
-- SCHEMA PER TENANT: Santa Juana (pilot)
-- =====================================================

-- Create schema for Santa Juana
CREATE SCHEMA IF NOT EXISTS santa_juana;

-- Users table (citizens, inspectors, admins)
CREATE TABLE IF NOT EXISTS santa_juana.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rut VARCHAR(12) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    address TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('citizen', 'inspector', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    avatar TEXT,
    oauth_provider VARCHAR(50),
    oauth_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Reports table (denuncias, sugerencias, emergencias)
CREATE TABLE IF NOT EXISTS santa_juana.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('denuncia', 'sugerencia', 'emergencia', 'infraestructura', 'otro')),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    priority VARCHAR(20) NOT NULL DEFAULT 'media' CHECK (priority IN ('baja', 'media', 'alta', 'urgente')),
    status VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'en_proceso', 'resuelto', 'rechazado')),
    assigned_to UUID REFERENCES santa_juana.users(id) ON DELETE SET NULL,
    resolution TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Infractions table (multas)
CREATE TABLE IF NOT EXISTS santa_juana.infractions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('trafico', 'ruido', 'basura', 'construccion', 'otro')),
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    amount DECIMAL(12, 2) NOT NULL,
    vehicle_plate VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'pagada', 'anulada')),
    payment_method VARCHAR(50) CHECK (payment_method IN ('efectivo', 'transferencia', 'tarjeta', 'webpay')),
    payment_reference VARCHAR(255),
    notes TEXT,
    issued_by UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMPTZ
);

-- Court Citations table (citaciones judiciales)
CREATE TABLE IF NOT EXISTS santa_juana.court_citations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    infraction_id UUID REFERENCES santa_juana.infractions(id) ON DELETE SET NULL,
    citation_number VARCHAR(100) UNIQUE NOT NULL,
    court_name VARCHAR(255) NOT NULL,
    hearing_date TIMESTAMPTZ NOT NULL,
    address TEXT NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'notificado', 'asistio', 'no_asistio', 'cancelado')),
    notification_method VARCHAR(50) CHECK (notification_method IN ('email', 'sms', 'carta', 'en_persona')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notified_at TIMESTAMPTZ
);

-- Medical Records table (fichas médicas por hogar)
CREATE TABLE IF NOT EXISTS santa_juana.medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_head_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    address TEXT NOT NULL,
    family_members JSONB NOT NULL,
    chronic_conditions JSONB,
    allergies JSONB,
    medications JSONB,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicles table (registro de vehículos)
CREATE TABLE IF NOT EXISTS santa_juana.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    plate VARCHAR(20) UNIQUE NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    color VARCHAR(50),
    vehicle_type VARCHAR(50) CHECK (vehicle_type IN ('auto', 'moto', 'camion', 'camioneta', 'bus', 'otro')),
    vin VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Files table (archivos adjuntos)
CREATE TABLE IF NOT EXISTS santa_juana.files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('report', 'infraction', 'court_citation', 'medical_record', 'user')),
    entity_id UUID NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    storage_path TEXT NOT NULL,
    uploaded_by UUID REFERENCES santa_juana.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS santa_juana.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES santa_juana.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('report', 'infraction', 'citation', 'general', 'urgent')),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit Log table
CREATE TABLE IF NOT EXISTS santa_juana.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES santa_juana.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR SANTA_JUANA SCHEMA
-- =====================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON santa_juana.users(email);
CREATE INDEX IF NOT EXISTS idx_users_rut ON santa_juana.users(rut);
CREATE INDEX IF NOT EXISTS idx_users_role ON santa_juana.users(role);

-- Reports indexes
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON santa_juana.reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON santa_juana.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_type ON santa_juana.reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON santa_juana.reports(created_at DESC);

-- Infractions indexes
CREATE INDEX IF NOT EXISTS idx_infractions_user_id ON santa_juana.infractions(user_id);
CREATE INDEX IF NOT EXISTS idx_infractions_status ON santa_juana.infractions(status);
CREATE INDEX IF NOT EXISTS idx_infractions_vehicle_plate ON santa_juana.infractions(vehicle_plate);
CREATE INDEX IF NOT EXISTS idx_infractions_created_at ON santa_juana.infractions(created_at DESC);

-- Court Citations indexes
CREATE INDEX IF NOT EXISTS idx_court_citations_user_id ON santa_juana.court_citations(user_id);
CREATE INDEX IF NOT EXISTS idx_court_citations_status ON santa_juana.court_citations(status);
CREATE INDEX IF NOT EXISTS idx_court_citations_hearing_date ON santa_juana.court_citations(hearing_date);

-- Medical Records indexes
CREATE INDEX IF NOT EXISTS idx_medical_records_household_head ON santa_juana.medical_records(household_head_id);

-- Vehicles indexes
CREATE INDEX IF NOT EXISTS idx_vehicles_owner_id ON santa_juana.vehicles(owner_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate ON santa_juana.vehicles(plate);

-- Files indexes
CREATE INDEX IF NOT EXISTS idx_files_entity ON santa_juana.files(entity_type, entity_id);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON santa_juana.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON santa_juana.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON santa_juana.notifications(created_at DESC);

-- Audit Log indexes
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON santa_juana.audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON santa_juana.audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON santa_juana.audit_log(created_at DESC);

-- =====================================================
-- INITIAL DATA: Santa Juana Tenant
-- =====================================================

INSERT INTO public.tenants (slug, name, subscription_type, subscription_status, subscription_start, db_schema)
VALUES (
    'santa_juana',
    'Municipalidad de Santa Juana',
    'yearly',
    'trial',
    NOW(),
    'santa_juana'
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
-- Public schema
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON public.tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_super_admins_updated_at BEFORE UPDATE ON public.super_admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Santa Juana schema
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON santa_juana.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON santa_juana.reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_infractions_updated_at BEFORE UPDATE ON santa_juana.infractions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_court_citations_updated_at BEFORE UPDATE ON santa_juana.court_citations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_records_updated_at BEFORE UPDATE ON santa_juana.medical_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON santa_juana.vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMPLETED!
-- =====================================================

-- Grant permissions
GRANT USAGE ON SCHEMA santa_juana TO frogio;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA santa_juana TO frogio;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA santa_juana TO frogio;

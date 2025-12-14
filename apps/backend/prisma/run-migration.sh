#!/bin/bash

# FROGIO - Database Migration Script
# Runs SQL migrations on the production database

set -e

echo "🚀 FROGIO Database Migration"
echo "================================"
echo ""

# Database connection from .env
DB_HOST="192.168.31.115"
DB_PORT="5432"
DB_NAME="frogio"
DB_USER="frogio"
DB_PASS="N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40="

# Export password for psql
export PGPASSWORD="$DB_PASS"

echo "📊 Target Database:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Check if migration file exists
MIGRATION_FILE="./migrations/001_initial_setup.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📝 Migration file: $MIGRATION_FILE"
echo ""

# Confirm before running
read -p "⚠️  Are you sure you want to run this migration? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Migration cancelled."
    exit 0
fi

echo ""
echo "🔄 Running migration..."
echo ""

# Run migration
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Verify tables: psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\dt santa_juana.*'"
    echo "  2. Check tenants: psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c 'SELECT * FROM public.tenants;'"
    echo "  3. Deploy backend to Coolify"
else
    echo ""
    echo "❌ Migration failed!"
    exit 1
fi

# Clean up
unset PGPASSWORD

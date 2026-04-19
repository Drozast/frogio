/**
 * Browser-based CSV import for the FROGIO admin.
 *
 * Mirrors apps/mobile/lib/features/admin/presentation/services/import_service.dart
 * Posts header-driven row maps to /api/admin/imports/{citations,reports,vehicles,users}.
 */

import Papa from 'papaparse';

import { adminFetch } from './admin-api';

export type ImportDatasetKey = 'citations' | 'reports' | 'vehicles' | 'users';

export interface ImportDatasetDef {
  key: ImportDatasetKey;
  label: string;
  /** Comma-separated header line, in canonical order. */
  headersCsv: string;
  filename: string;
  endpoint: string;
}

export const IMPORT_DATASETS: Record<ImportDatasetKey, ImportDatasetDef> = {
  citations: {
    key: 'citations',
    label: 'Citaciones',
    headersCsv:
      'number,target_name,target_rut,target_address,reason,citation_type,created_at',
    filename: 'plantilla_citaciones.csv',
    endpoint: '/api/admin/imports/citations',
  },
  reports: {
    key: 'reports',
    label: 'Denuncias',
    headersCsv:
      'title,description,category,priority,status,latitude,longitude,address,citizen_name,citizen_phone,created_at',
    filename: 'plantilla_denuncias.csv',
    endpoint: '/api/admin/imports/reports',
  },
  vehicles: {
    key: 'vehicles',
    label: 'Vehiculos',
    headersCsv: 'plate,brand,model,year,type,status,current_km,color',
    filename: 'plantilla_vehiculos.csv',
    endpoint: '/api/admin/imports/vehicles',
  },
  users: {
    key: 'users',
    label: 'Usuarios',
    headersCsv: 'email,first_name,last_name,rut,phone,role,password',
    filename: 'plantilla_usuarios.csv',
    endpoint: '/api/admin/imports/users',
  },
};

export function getDatasetHeaders(dataset: ImportDatasetDef | ImportDatasetKey): string[] {
  const def = typeof dataset === 'string' ? IMPORT_DATASETS[dataset] : dataset;
  return def.headersCsv.split(',').map((s) => s.trim());
}

// ---------------------------------------------------------------------------
// CSV parsing
// ---------------------------------------------------------------------------

export interface ImportSummary {
  inserted: number;
  failed: number;
  errors: string[];
}

function stripBom(s: string): string {
  return s.charCodeAt(0) === 0xfeff ? s.substring(1) : s;
}

/**
 * Parse a File (CSV) into header-driven row maps.
 * - Strips UTF-8 BOM
 * - Skips fully empty rows
 * - All values returned as strings (let the backend coerce types)
 */
export async function parseCsv(file: File): Promise<Record<string, string>[]> {
  const text = stripBom(await file.text());

  return await new Promise((resolve, reject) => {
    Papa.parse<Record<string, string>>(text, {
      header: true,
      skipEmptyLines: 'greedy',
      transformHeader: (h: string) => h.trim(),
      complete: (results) => {
        const rows = (results.data ?? []).filter((row) => {
          if (!row || typeof row !== 'object') return false;
          return Object.values(row).some(
            (v) => v != null && String(v).trim() !== ''
          );
        });
        // Normalize – ensure all values are strings
        const normalized = rows.map((r) => {
          const out: Record<string, string> = {};
          for (const [k, v] of Object.entries(r)) {
            out[k] = v == null ? '' : String(v);
          }
          return out;
        });
        resolve(normalized);
      },
      error: (err: Error) => reject(err),
    });
  });
}

// ---------------------------------------------------------------------------
// Upload
// ---------------------------------------------------------------------------

export async function uploadRows(
  dataset: ImportDatasetDef | ImportDatasetKey,
  rows: Record<string, string>[]
): Promise<ImportSummary> {
  const def = typeof dataset === 'string' ? IMPORT_DATASETS[dataset] : dataset;
  try {
    const raw = await adminFetch<Partial<ImportSummary> & Record<string, unknown>>(
      def.endpoint,
      {
        method: 'POST',
        body: JSON.stringify({ rows }),
      }
    );
    return {
      inserted: Number(raw?.inserted ?? 0),
      failed: Number(raw?.failed ?? 0),
      errors: Array.isArray(raw?.errors)
        ? raw.errors.map((e) => String(e))
        : [],
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Error de importacion';
    return { inserted: 0, failed: rows.length, errors: [message] };
  }
}

// ---------------------------------------------------------------------------
// Template download
// ---------------------------------------------------------------------------

export function downloadTemplate(
  dataset: ImportDatasetDef | ImportDatasetKey
): void {
  if (typeof window === 'undefined') return;
  const def = typeof dataset === 'string' ? IMPORT_DATASETS[dataset] : dataset;
  const content = `\uFEFF${def.headersCsv}\n`;
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = def.filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export const importService = {
  datasets: IMPORT_DATASETS,
  getDatasetHeaders,
  parseCsv,
  uploadRows,
  downloadTemplate,
};

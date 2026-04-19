/**
 * Browser-based CSV and PDF export utilities for the FROGIO admin.
 *
 * Mirrors apps/mobile/lib/features/admin/presentation/services/export_service.dart
 * (FROGIO Verde Sapo branding, A4 landscape, green table header, footer with
 * page numbers + timestamp + generator).
 *
 * Dependencies (must be installed):
 *   - papaparse + @types/papaparse
 *   - jspdf
 *   - jspdf-autotable
 */

import Papa from 'papaparse';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

import { FROGIO_COLORS } from './theme';

const TENANT_NAME = 'Municipalidad de Santa Juana';
const LOGO_URL = '/frogio-logo.png';

// ---------------------------------------------------------------------------
// Filename / time helpers
// ---------------------------------------------------------------------------

function pad(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

function timestampForFilename(d = new Date()): string {
  return (
    `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}` +
    `_${pad(d.getHours())}${pad(d.getMinutes())}`
  );
}

function timestampForDisplay(d = new Date()): string {
  return (
    `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}`
  );
}

function sanitizeForFilename(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
}

function downloadBlob(blob: Blob, filename: string): void {
  if (typeof window === 'undefined') return;
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  // Defer revoke so download starts.
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// ---------------------------------------------------------------------------
// CSV
// ---------------------------------------------------------------------------

export interface ExportCsvOptions {
  filenamePrefix: string;
  headers: string[];
  rows: (string | number | null | undefined)[][];
}

export function exportCSV(opts: ExportCsvOptions): void {
  const { filenamePrefix, headers, rows } = opts;

  const data = [headers, ...rows.map((r) => r.map((c) => (c == null ? '' : c)))];
  const csv = Papa.unparse(data, { quotes: true });

  // Add UTF-8 BOM so Excel recognizes encoding.
  const blob = new Blob([`\uFEFF${csv}`], {
    type: 'text/csv;charset=utf-8;',
  });

  downloadBlob(blob, `${filenamePrefix}_${timestampForFilename()}.csv`);
}

// ---------------------------------------------------------------------------
// PDF
// ---------------------------------------------------------------------------

export interface ExportPdfOptions {
  title: string;
  subtitle: string;
  headers: string[];
  rows: string[][];
  generatedBy?: string;
  /** When true, opens print preview instead of downloading. */
  preview?: boolean;
}

/** Convert "#RRGGBB" → [r, g, b]. */
function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return [r, g, b];
}

async function loadLogoDataUrl(): Promise<string | null> {
  if (typeof window === 'undefined') return null;
  try {
    const res = await fetch(LOGO_URL);
    if (!res.ok) return null;
    const blob = await res.blob();
    if (!blob.type.startsWith('image/')) return null;
    return await new Promise((resolve) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = () => resolve(null);
      reader.readAsDataURL(blob);
    });
  } catch {
    return null;
  }
}

export async function exportPDF(opts: ExportPdfOptions): Promise<void> {
  const {
    title,
    subtitle,
    headers,
    rows,
    generatedBy,
    preview = false,
  } = opts;

  const stamp = timestampForDisplay();
  const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 28;
  const headerHeight = 64;
  const footerHeight = 28;

  const primaryDarkRgb = hexToRgb(FROGIO_COLORS.primaryDark);
  const textPrimaryRgb = hexToRgb(FROGIO_COLORS.textPrimary);
  const greyRgb: [number, number, number] = [110, 110, 110];

  const logo = await loadLogoDataUrl();

  const drawHeader = () => {
    let cursorX = margin;
    // Logo (if available) – png/jpg only. SVG won't render via addImage.
    if (logo) {
      try {
        doc.addImage(logo, 'PNG', cursorX, margin, 40, 40);
        cursorX += 52;
      } catch {
        try {
          doc.addImage(logo, 'JPEG', cursorX, margin, 40, 40);
          cursorX += 52;
        } catch {
          /* ignore – logo unsupported format */
        }
      }
    }

    // Title block
    doc.setTextColor(...primaryDarkRgb);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.text(title, cursorX, margin + 16);

    doc.setTextColor(...greyRgb);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(subtitle, cursorX, margin + 32);

    // Right-aligned brand block
    doc.setTextColor(...primaryDarkRgb);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.text('FROGIO', pageWidth - margin, margin + 14, { align: 'right' });

    doc.setTextColor(...greyRgb);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.text(TENANT_NAME, pageWidth - margin, margin + 28, { align: 'right' });

    // Bottom border
    doc.setDrawColor(...primaryDarkRgb);
    doc.setLineWidth(2);
    const lineY = margin + headerHeight - 8;
    doc.line(margin, lineY, pageWidth - margin, lineY);
  };

  const drawFooter = (page: number, total: number) => {
    const y = pageHeight - margin;
    doc.setDrawColor(220, 220, 220);
    doc.setLineWidth(0.5);
    doc.line(margin, y - footerHeight + 8, pageWidth - margin, y - footerHeight + 8);

    doc.setTextColor(...greyRgb);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);

    const left = `Generado: ${stamp}${generatedBy ? ` por ${generatedBy}` : ''}`;
    doc.text(left, margin, y);

    const right = `Pagina ${page} de ${total}`;
    doc.text(right, pageWidth - margin, y, { align: 'right' });
  };

  autoTable(doc, {
    head: [headers],
    body: rows,
    startY: margin + headerHeight,
    margin: { top: margin + headerHeight, bottom: margin + footerHeight, left: margin, right: margin },
    styles: {
      fontSize: 9,
      cellPadding: { top: 4, bottom: 4, left: 6, right: 6 },
      textColor: textPrimaryRgb,
      lineColor: [220, 220, 220],
      lineWidth: 0.25,
    },
    headStyles: {
      fillColor: primaryDarkRgb,
      textColor: [255, 255, 255],
      fontStyle: 'bold',
      fontSize: 10,
      cellPadding: { top: 6, bottom: 6, left: 6, right: 6 },
    },
    alternateRowStyles: {
      fillColor: [248, 250, 248],
    },
    didDrawPage: (data) => {
      drawHeader();
      const total = doc.getNumberOfPages();
      drawFooter(data.pageNumber, total);
    },
  });

  // Final summary line
  const docWithTable = doc as jsPDF & { lastAutoTable?: { finalY: number } };
  const finalY = docWithTable.lastAutoTable?.finalY ?? margin + headerHeight;
  doc.setTextColor(...textPrimaryRgb);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(10);
  doc.text(
    `Total de registros: ${rows.length}`,
    margin,
    Math.min(finalY + 18, pageHeight - margin - footerHeight - 4)
  );

  // Re-stamp footer page totals on every page (autoTable uses pre-final count).
  const totalPages = doc.getNumberOfPages();
  for (let p = 1; p <= totalPages; p++) {
    doc.setPage(p);
    // Clear footer band by overpainting with white (approximation), then redraw.
    doc.setFillColor(255, 255, 255);
    doc.rect(margin - 4, pageHeight - margin - 16, pageWidth - 2 * margin + 8, 20, 'F');
    drawFooter(p, totalPages);
  }

  const filename = `${sanitizeForFilename(title)}_${timestampForFilename()}.pdf`;

  if (preview && typeof window !== 'undefined') {
    const blobUrl = doc.output('bloburl');
    window.open(blobUrl, '_blank');
    return;
  }

  doc.save(filename);
}

/** Convenience: open print preview in a new tab without downloading. */
export async function previewPDF(opts: Omit<ExportPdfOptions, 'preview'>): Promise<void> {
  return exportPDF({ ...opts, preview: true });
}

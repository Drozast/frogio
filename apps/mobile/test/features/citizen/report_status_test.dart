// test/features/citizen/report_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frogio_mobile/features/citizen/domain/entities/enhanced_report_entity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ReportStatus.fromApiString — canonical Spanish values
  // ---------------------------------------------------------------------------
  group('ReportStatus.fromApiString — canonical API values', () {
    test("'pendiente' → ReportStatus.pendiente", () {
      expect(ReportStatus.fromApiString('pendiente'), ReportStatus.pendiente);
    });

    test("'en_proceso' → ReportStatus.enProceso", () {
      expect(ReportStatus.fromApiString('en_proceso'), ReportStatus.enProceso);
    });

    test("'resuelto' → ReportStatus.resuelto", () {
      expect(ReportStatus.fromApiString('resuelto'), ReportStatus.resuelto);
    });

    test("'rechazado' → ReportStatus.rechazado", () {
      expect(ReportStatus.fromApiString('rechazado'), ReportStatus.rechazado);
    });
  });

  // ---------------------------------------------------------------------------
  // ReportStatus.fromApiString — legacy / alias values
  // ---------------------------------------------------------------------------
  group('ReportStatus.fromApiString — legacy aliases', () {
    test("'submitted' → ReportStatus.pendiente", () {
      expect(ReportStatus.fromApiString('submitted'), ReportStatus.pendiente);
    });

    test("'draft' → ReportStatus.pendiente", () {
      expect(ReportStatus.fromApiString('draft'), ReportStatus.pendiente);
    });

    test("'inprogress' → ReportStatus.enProceso", () {
      expect(ReportStatus.fromApiString('inprogress'), ReportStatus.enProceso);
    });

    test("'in_progress' → ReportStatus.enProceso", () {
      expect(ReportStatus.fromApiString('in_progress'), ReportStatus.enProceso);
    });

    test("'reviewing' → ReportStatus.enProceso", () {
      expect(ReportStatus.fromApiString('reviewing'), ReportStatus.enProceso);
    });

    test("'resolved' → ReportStatus.resuelto", () {
      expect(ReportStatus.fromApiString('resolved'), ReportStatus.resuelto);
    });

    test("'rejected' → ReportStatus.rechazado", () {
      expect(ReportStatus.fromApiString('rejected'), ReportStatus.rechazado);
    });

    test("'duplicate' → ReportStatus.rechazado", () {
      expect(ReportStatus.fromApiString('duplicate'), ReportStatus.rechazado);
    });

    test("'archived' → ReportStatus.rechazado", () {
      expect(ReportStatus.fromApiString('archived'), ReportStatus.rechazado);
    });

    test("'cancelled' → ReportStatus.rechazado", () {
      expect(ReportStatus.fromApiString('cancelled'), ReportStatus.rechazado);
    });

    test('unknown value falls back to pendiente', () {
      expect(ReportStatus.fromApiString('whatever'), ReportStatus.pendiente);
    });

    test('matching is case-insensitive', () {
      expect(ReportStatus.fromApiString('PENDIENTE'), ReportStatus.pendiente);
      expect(ReportStatus.fromApiString('EN_PROCESO'), ReportStatus.enProceso);
    });
  });

  // ---------------------------------------------------------------------------
  // ReportStatus.toApiString
  // ---------------------------------------------------------------------------
  group('ReportStatus.toApiString', () {
    test("ReportStatus.pendiente.toApiString() == 'pendiente'", () {
      expect(ReportStatus.pendiente.toApiString(), equals('pendiente'));
    });

    test("ReportStatus.enProceso.toApiString() == 'en_proceso'", () {
      expect(ReportStatus.enProceso.toApiString(), equals('en_proceso'));
    });

    test("ReportStatus.resuelto.toApiString() == 'resuelto'", () {
      expect(ReportStatus.resuelto.toApiString(), equals('resuelto'));
    });

    test("ReportStatus.rechazado.toApiString() == 'rechazado'", () {
      expect(ReportStatus.rechazado.toApiString(), equals('rechazado'));
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: fromApiString(toApiString(s)) == s for all values
  // ---------------------------------------------------------------------------
  group('ReportStatus round-trip', () {
    for (final status in ReportStatus.values) {
      test('${status.name} round-trips via toApiString/fromApiString', () {
        expect(
          ReportStatus.fromApiString(status.toApiString()),
          equals(status),
        );
      });
    }
  });

  // ---------------------------------------------------------------------------
  // displayName sanity check
  // ---------------------------------------------------------------------------
  group('ReportStatus.displayName', () {
    test('pendiente has non-empty displayName', () {
      expect(ReportStatus.pendiente.displayName, isNotEmpty);
    });

    test('enProceso displayName is En Proceso', () {
      expect(ReportStatus.enProceso.displayName, equals('En Proceso'));
    });
  });
}

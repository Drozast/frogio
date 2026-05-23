// test/features/inspector/citation_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frogio_mobile/features/inspector/domain/entities/citation_entity.dart';

// ---------------------------------------------------------------------------
// Top-level helper
// ---------------------------------------------------------------------------
CitationEntity makeEntity({
  String? courtName,
  DateTime? hearingDate,
}) {
  return CitationEntity(
    id: 'id-1',
    citationType: CitationType.citacion,
    targetType: TargetType.persona,
    citationNumber: 'C-001',
    reason: 'Test reason',
    photos: const [],
    status: CitationStatus.pendiente,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
    courtName: courtName,
    hearingDate: hearingDate,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // CitationEntity — construction & new fields
  // ---------------------------------------------------------------------------
  group('CitationEntity construction', () {
    test('can be created with courtName and hearingDate', () {
      final date = DateTime(2024, 6, 15, 9, 30);
      final entity = makeEntity(courtName: 'Juzgado Civil', hearingDate: date);

      expect(entity.courtName, equals('Juzgado Civil'));
      expect(entity.hearingDate, equals(date));
    });

    test('courtName and hearingDate default to null when omitted', () {
      final entity = makeEntity();

      expect(entity.courtName, isNull);
      expect(entity.hearingDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CitationEntity.copyWith
  // ---------------------------------------------------------------------------
  group('CitationEntity.copyWith', () {
    test('preserves courtName when not overridden', () {
      final original = makeEntity(courtName: 'Juzgado Letras');
      final copy = original.copyWith(reason: 'New reason');

      expect(copy.courtName, equals('Juzgado Letras'));
    });

    test('preserves hearingDate when not overridden', () {
      final date = DateTime(2024, 9, 20);
      final original = makeEntity(hearingDate: date);
      final copy = original.copyWith(reason: 'New reason');

      expect(copy.hearingDate, equals(date));
    });

    test('updates courtName when a new value is passed', () {
      final original = makeEntity(courtName: 'Old Court');
      final copy = original.copyWith(courtName: 'New Court');

      expect(copy.courtName, equals('New Court'));
    });

    test('updates hearingDate when a new value is passed', () {
      final original = makeEntity(hearingDate: DateTime(2024, 1, 1));
      final newDate = DateTime(2025, 3, 10);
      final copy = original.copyWith(hearingDate: newDate);

      expect(copy.hearingDate, equals(newDate));
    });

    test('other fields are unaffected by courtName / hearingDate change', () {
      final original = makeEntity(courtName: 'Court A');
      final copy = original.copyWith(courtName: 'Court B');

      expect(copy.id, equals(original.id));
      expect(copy.reason, equals(original.reason));
      expect(copy.status, equals(original.status));
    });
  });

  // ---------------------------------------------------------------------------
  // CitationStatus enum
  // ---------------------------------------------------------------------------
  group('CitationStatus.fromString', () {
    test("'pendiente' → CitationStatus.pendiente", () {
      expect(CitationStatus.fromString('pendiente'), CitationStatus.pendiente);
    });

    test("'no_asistio' → CitationStatus.noAsistio", () {
      expect(CitationStatus.fromString('no_asistio'), CitationStatus.noAsistio);
    });

    test("'notificado' → CitationStatus.notificado", () {
      expect(CitationStatus.fromString('notificado'), CitationStatus.notificado);
    });

    test("'asistio' → CitationStatus.asistio", () {
      expect(CitationStatus.fromString('asistio'), CitationStatus.asistio);
    });

    test("'cancelado' → CitationStatus.cancelado", () {
      expect(CitationStatus.fromString('cancelado'), CitationStatus.cancelado);
    });

    test('unknown value falls back to pendiente', () {
      expect(CitationStatus.fromString('desconocido'), CitationStatus.pendiente);
    });
  });

  group('CitationStatus round-trip (fromString ∘ toApiString == identity)', () {
    for (final status in CitationStatus.values) {
      test('${status.name} round-trips correctly', () {
        expect(
          CitationStatus.fromString(status.toApiString()),
          equals(status),
        );
      });
    }
  });

  // ---------------------------------------------------------------------------
  // CitationType helpers
  // ---------------------------------------------------------------------------
  group('CitationType.fromString', () {
    test("'advertencia' → CitationType.advertencia", () {
      expect(CitationType.fromString('advertencia'), CitationType.advertencia);
    });

    test("'citacion' → CitationType.citacion", () {
      expect(CitationType.fromString('citacion'), CitationType.citacion);
    });

    test('unknown value falls back to citacion', () {
      expect(CitationType.fromString('xyz'), CitationType.citacion);
    });
  });

  // ---------------------------------------------------------------------------
  // TargetType helpers
  // ---------------------------------------------------------------------------
  group('TargetType.fromString', () {
    final cases = {
      'persona': TargetType.persona,
      'domicilio': TargetType.domicilio,
      'vehiculo': TargetType.vehiculo,
      'comercio': TargetType.comercio,
      'otro': TargetType.otro,
    };
    cases.forEach((input, expected) {
      test("'$input' → TargetType.${expected.name}", () {
        expect(TargetType.fromString(input), equals(expected));
      });
    });

    test('unknown value falls back to otro', () {
      expect(TargetType.fromString('none'), TargetType.otro);
    });
  });

  // ---------------------------------------------------------------------------
  // Equatable props — equality check
  // ---------------------------------------------------------------------------
  group('CitationEntity equality (Equatable)', () {
    test('two entities with same values are equal', () {
      final date = DateTime(2024, 6, 15);
      final a = makeEntity(courtName: 'Court A', hearingDate: date);
      final b = makeEntity(courtName: 'Court A', hearingDate: date);

      expect(a, equals(b));
    });

    test('entities differ when courtName differs', () {
      final a = makeEntity(courtName: 'Court A');
      final b = makeEntity(courtName: 'Court B');

      expect(a, isNot(equals(b)));
    });

    test('entities differ when hearingDate differs', () {
      final a = makeEntity(hearingDate: DateTime(2024, 1, 1));
      final b = makeEntity(hearingDate: DateTime(2024, 1, 2));

      expect(a, isNot(equals(b)));
    });
  });
}

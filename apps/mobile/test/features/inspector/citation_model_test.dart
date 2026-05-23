// test/features/inspector/citation_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frogio_mobile/features/inspector/data/models/citation_model.dart';
import 'package:frogio_mobile/features/inspector/domain/entities/citation_entity.dart';

// ---------------------------------------------------------------------------
// Minimal valid JSON that satisfies all required CitationModel fields
// ---------------------------------------------------------------------------
Map<String, dynamic> minimalJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 'cit-1',
    'citation_type': 'citacion',
    'target_type': 'persona',
    'citation_number': 'C-001',
    'reason': 'Test reason',
    'status': 'pendiente',
    'photos': <String>[],
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-02T00:00:00.000Z',
  };
  if (overrides != null) base.addAll(overrides);
  return base;
}

void main() {
  // ---------------------------------------------------------------------------
  // CitationModel.fromJson — new fields
  // ---------------------------------------------------------------------------
  group('CitationModel.fromJson — court_name and hearing_date', () {
    test('parses court_name correctly', () {
      final model = CitationModel.fromJson(
        minimalJson(overrides: {'court_name': 'Juzgado Civil de Santa Juana'}),
      );

      expect(model.courtName, equals('Juzgado Civil de Santa Juana'));
    });

    test('parses hearing_date correctly', () {
      final model = CitationModel.fromJson(
        minimalJson(overrides: {'hearing_date': '2024-06-15T09:30:00.000Z'}),
      );

      expect(model.hearingDate, equals(DateTime.parse('2024-06-15T09:30:00.000Z')));
    });

    test('handles null court_name gracefully', () {
      final model = CitationModel.fromJson(minimalJson(overrides: {'court_name': null}));

      expect(model.courtName, isNull);
    });

    test('handles null hearing_date gracefully', () {
      final model = CitationModel.fromJson(minimalJson(overrides: {'hearing_date': null}));

      expect(model.hearingDate, isNull);
    });

    test('is backward-compatible — no crash when fields are absent', () {
      // JSON that predates the new fields (no court_name / hearing_date keys)
      expect(() => CitationModel.fromJson(minimalJson()), returnsNormally);

      final model = CitationModel.fromJson(minimalJson());
      expect(model.courtName, isNull);
      expect(model.hearingDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CitationModel.fromJson — other fields
  // ---------------------------------------------------------------------------
  group('CitationModel.fromJson — general parsing', () {
    test('parses required fields', () {
      final model = CitationModel.fromJson(minimalJson());

      expect(model.id, equals('cit-1'));
      expect(model.citationType, equals(CitationType.citacion));
      expect(model.targetType, equals(TargetType.persona));
      expect(model.citationNumber, equals('C-001'));
      expect(model.reason, equals('Test reason'));
      expect(model.status, equals(CitationStatus.pendiente));
    });

    test('parses photos as List', () {
      final model = CitationModel.fromJson(
        minimalJson(overrides: {'photos': ['http://a.com/1.jpg', 'http://a.com/2.jpg']}),
      );

      expect(model.photos, equals(['http://a.com/1.jpg', 'http://a.com/2.jpg']));
    });

    test('parses photos as Postgres array string', () {
      final model = CitationModel.fromJson(
        minimalJson(overrides: {'photos': '{http://a.com/1.jpg,http://a.com/2.jpg}'}),
      );

      expect(model.photos, equals(['http://a.com/1.jpg', 'http://a.com/2.jpg']));
    });

    test('parses issuer name from first/last name fields', () {
      final model = CitationModel.fromJson(
        minimalJson(overrides: {
          'issuer_first_name': 'Juan',
          'issuer_last_name': 'Pérez',
        }),
      );

      expect(model.issuerName, equals('Juan Pérez'));
    });

    test('issuerName is null when first/last name fields absent', () {
      final model = CitationModel.fromJson(minimalJson());

      expect(model.issuerName, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CitationModel.toJson — serialisation
  // ---------------------------------------------------------------------------
  group('CitationModel.toJson', () {
    CitationModel makeModel({String? courtName, DateTime? hearingDate}) {
      return CitationModel(
        id: 'cit-1',
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

    test('serializes courtName when set', () {
      final json = makeModel(courtName: 'Juzgado Civil').toJson();

      expect(json['court_name'], equals('Juzgado Civil'));
    });

    test('omits court_name key when courtName is null', () {
      final json = makeModel().toJson();

      expect(json.containsKey('court_name'), isFalse);
    });

    test('serializes hearingDate as ISO string when set', () {
      final date = DateTime.utc(2024, 6, 15, 9, 30);
      final json = makeModel(hearingDate: date).toJson();

      expect(json['hearing_date'], equals(date.toIso8601String()));
    });

    test('omits hearing_date key when hearingDate is null', () {
      final json = makeModel().toJson();

      expect(json.containsKey('hearing_date'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // CitationFilters.toQueryParams
  // ---------------------------------------------------------------------------
  group('CitationFilters.toQueryParams', () {
    test('includes reportId when set', () {
      final params = const CitationFilters(reportId: 'abc').toQueryParams();

      expect(params['reportId'], equals('abc'));
    });

    test('does NOT include reportId key when not set', () {
      final params = const CitationFilters().toQueryParams();

      expect(params.containsKey('reportId'), isFalse);
    });

    test('includes status when set', () {
      final params = const CitationFilters(status: CitationStatus.notificado).toQueryParams();

      expect(params['status'], equals('notificado'));
    });

    test('empty filters produce empty map', () {
      final params = const CitationFilters().toQueryParams();

      expect(params, isEmpty);
    });

    test('multiple filters are all included', () {
      final params = const CitationFilters(
        reportId: 'r-1',
        status: CitationStatus.asistio,
        search: 'juan',
      ).toQueryParams();

      expect(params['reportId'], equals('r-1'));
      expect(params['status'], equals('asistio'));
      expect(params['search'], equals('juan'));
    });
  });

  // ---------------------------------------------------------------------------
  // CreateCitationDto.toJson
  // ---------------------------------------------------------------------------
  group('CreateCitationDto.toJson', () {
    test('excludes courtName and hearingDate when not provided', () {
      const dto = CreateCitationDto(
        citationType: CitationType.advertencia,
        targetType: TargetType.persona,
        citationNumber: 'C-002',
        reason: 'Reason',
      );
      final json = dto.toJson();

      expect(json.containsKey('courtName'), isFalse);
      expect(json.containsKey('hearingDate'), isFalse);
    });

    test('includes hearingDate as ISO string when set', () {
      final date = DateTime.utc(2024, 9, 20, 10, 0);
      final dto = CreateCitationDto(
        citationType: CitationType.citacion,
        targetType: TargetType.persona,
        citationNumber: 'C-003',
        reason: 'Reason',
        hearingDate: date,
      );
      final json = dto.toJson();

      expect(json['hearingDate'], equals(date.toIso8601String()));
    });

    test('includes courtName when set', () {
      const dto = CreateCitationDto(
        citationType: CitationType.citacion,
        targetType: TargetType.domicilio,
        citationNumber: 'C-004',
        reason: 'Reason',
        courtName: 'Tribunal Oral',
      );
      final json = dto.toJson();

      expect(json['courtName'], equals('Tribunal Oral'));
    });

    test('includes citationType and targetType as enum names', () {
      const dto = CreateCitationDto(
        citationType: CitationType.advertencia,
        targetType: TargetType.vehiculo,
        citationNumber: 'C-005',
        reason: 'Reason',
      );
      final json = dto.toJson();

      expect(json['citationType'], equals('advertencia'));
      expect(json['targetType'], equals('vehiculo'));
    });

    test('omits optional fields when null', () {
      const dto = CreateCitationDto(
        citationType: CitationType.citacion,
        targetType: TargetType.persona,
        citationNumber: 'C-006',
        reason: 'Reason',
      );
      final json = dto.toJson();

      for (final key in ['targetName', 'targetRut', 'notes', 'photos', 'reportId']) {
        expect(json.containsKey(key), isFalse, reason: '$key should be absent');
      }
    });
  });
}

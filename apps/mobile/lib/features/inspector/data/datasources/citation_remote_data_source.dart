// lib/features/inspector/data/datasources/citation_remote_data_source.dart
import 'dart:io';

import '../models/citation_model.dart';

abstract class CitationRemoteDataSource {
  Future<List<CitationModel>> getCitations({CitationFilters? filters});
  Future<CitationModel> getCitationById(String id);
  Future<CitationModel> createCitation(CreateCitationDto dto);
  Future<CitationModel> updateCitation(String id, UpdateCitationDto dto);
  Future<void> deleteCitation(String id);
  Future<List<CitationModel>> getMyCitations();
  Future<String> generateCitationNumber();
  Future<List<String>> uploadPhotos(List<File> photos);
}

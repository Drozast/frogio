// lib/features/citizen/domain/usecases/reports/create_report.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/enhanced_report_entity.dart';
import '../../repositories/report_repository.dart';

class CreateReport implements UseCase<String, CreateReportParams> {
  final ReportRepository repository;

  CreateReport(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateReportParams params) {
    return repository.createReport(
      title: params.title,
      description: params.description,
      category: params.category,
      location: params.location,
      userId: params.userId,
      images: params.images,
    );
  }
}

class CreateReportParams extends Equatable {
  final String title;
  final String description;
  final String category;
  final LocationData location;
  final String userId;
  final List<File> images;

  const CreateReportParams({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.userId,
    required this.images,
  });

  @override
  List<Object?> get props => [title, description, category, location, userId, images];
}
// lib/features/inspector/presentation/pages/citations_main_screen.dart
import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/citation_bloc.dart';
import 'citations_list_screen.dart';

/// A screen that acts as the main entry point for viewing citations.
///
/// This widget is responsible for providing the [CitationBloc] to the widget
/// tree and displaying the primary UI for citation management, which is
/// handled by [CitationsListScreen].
class CitationsMainScreen extends StatelessWidget {
  final UserEntity user;

  const CitationsMainScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // The Bloc is now provided by DashboardScreen, so we just build the UI.
    return const CitationsListScreen();
  }
}

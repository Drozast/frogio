// lib/dashboard/presentation/bloc/theme/theme_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(isDarkMode: false)) {
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);
  }

  void _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    emit(ThemeState(isDarkMode: !state.isDarkMode));
  }

  void _onSetTheme(SetTheme event, Emitter<ThemeState> emit) {
    emit(ThemeState(isDarkMode: event.isDarkMode));
  }
}
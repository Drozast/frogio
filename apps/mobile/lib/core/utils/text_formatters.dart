// lib/core/utils/text_formatters.dart
import 'package:flutter/services.dart';

/// Formateador que capitaliza automáticamente nombres
class NameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final capitalized = _capitalizeName(text);
    
    return TextEditingValue(
      text: capitalized,
      selection: TextSelection.collapsed(offset: capitalized.length),
    );
  }

  String _capitalizeName(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Formateador para números de teléfono chilenos
class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.length > 9) {
      return oldValue;
    }
    
    String formatted = '';
    if (text.isNotEmpty) {
      if (text.length <= 1) {
        formatted = text;
      } else if (text.length <= 5) {
        formatted = '${text.substring(0, 1)} ${text.substring(1)}';
      } else {
        formatted = '${text.substring(0, 1)} ${text.substring(1, 5)} ${text.substring(5)}';
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Validadores
class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length != 9) {
      return 'El teléfono debe tener 9 dígitos';
    }
    if (!cleanPhone.startsWith('9')) {
      return 'El teléfono debe comenzar con 9';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección es requerida';
    }
    if (value.trim().length < 10) {
      return 'La dirección debe ser más específica';
    }
    return null;
  }
}
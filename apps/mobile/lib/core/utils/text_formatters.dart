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

/// Formateador para RUT chileno (12.345.678-9)
class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remover todo excepto números y K
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^\dKk]'), '');

    if (text.length > 9) {
      text = text.substring(0, 9);
    }

    if (text.isEmpty) return newValue.copyWith(text: '');

    String formatted = '';

    if (text.length <= 1) {
      formatted = text;
    } else {
      // Separar dígito verificador
      final dv = text.substring(text.length - 1);
      final numbers = text.substring(0, text.length - 1);

      // Formatear con puntos
      final reversed = numbers.split('').reversed.toList();
      final parts = <String>[];
      for (var i = 0; i < reversed.length; i += 3) {
        final end = (i + 3 > reversed.length) ? reversed.length : i + 3;
        parts.add(reversed.sublist(i, end).reversed.join(''));
      }

      formatted = '${parts.reversed.join('.')}-$dv';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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

  static String? validateRut(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RUT es requerido';
    }

    // Limpiar RUT
    final cleanRut = value.replaceAll(RegExp(r'[^\dKk]'), '').toUpperCase();

    if (cleanRut.length < 8 || cleanRut.length > 9) {
      return 'El RUT debe tener entre 8 y 9 caracteres';
    }

    // Validar dígito verificador
    final dv = cleanRut.substring(cleanRut.length - 1);
    final numbers = cleanRut.substring(0, cleanRut.length - 1);

    final calculatedDv = _calculateDV(int.parse(numbers));
    if (dv != calculatedDv) {
      return 'El RUT no es válido';
    }

    return null;
  }

  static String _calculateDV(int rut) {
    int sum = 0;
    int multiplier = 2;

    while (rut > 0) {
      sum += (rut % 10) * multiplier;
      rut = rut ~/ 10;
      multiplier = multiplier < 7 ? multiplier + 1 : 2;
    }

    final dv = 11 - (sum % 11);
    if (dv == 11) return '0';
    if (dv == 10) return 'K';
    return dv.toString();
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
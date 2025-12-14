// lib/core/utils/password_validator.dart
class PasswordValidator {
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (password.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos un carácter especial';
    }
    
    return null;
  }
  
  static List<String> getRequirements() {
    return [
      'Mínimo 8 caracteres',
      'Al menos una mayúscula',
      'Al menos un número',
      'Al menos un carácter especial (!@#\$%^&*)',
    ];
  }
}
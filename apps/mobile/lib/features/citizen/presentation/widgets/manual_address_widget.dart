// lib/features/citizen/presentation/widgets/manual_address_widget.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';

class ManualAddressWidget extends StatefulWidget {
  final String? initialAddress;
  final Function(String) onAddressEntered;

  const ManualAddressWidget({
    super.key,
    this.initialAddress,
    required this.onAddressEntered,
  });

  @override
  State<ManualAddressWidget> createState() => _ManualAddressWidgetState();
}

class _ManualAddressWidgetState extends State<ManualAddressWidget> {
  late TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.edit_location_alt,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Escribe la dirección manualmente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa la dirección exacta donde ocurre el problema',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Dirección completa',
                hintText: 'Ej: Calle Los Aromos 123, Santa Juana, Región del Biobío',
                prefixIcon: Icon(Icons.location_on),
                helperText: 'Incluye calle, número, comuna y referencias',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La dirección es requerida';
                }
                if (value.trim().length < 10) {
                  return 'La dirección debe ser más específica';
                }
                return null;
              },
              onChanged: (value) {
                // Validar en tiempo real
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 16),
            
            // Sugerencias de formato
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Consejos para una mejor ubicación:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildTips(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirmar Dirección',
                icon: Icons.check,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onAddressEntered(_addressController.text.trim());
                    _showSuccessMessage();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTips() {
    final tips = [
      'Incluye nombre de la calle y número',
      'Agrega referencias cercanas (plaza, escuela, etc.)',
      'Especifica la comuna o sector',
      'Sé lo más preciso posible',
    ];

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    )).toList();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Dirección confirmada'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
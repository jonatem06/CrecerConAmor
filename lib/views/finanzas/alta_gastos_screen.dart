import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AltaGastosScreen extends StatefulWidget {
  const AltaGastosScreen({super.key});

  @override
  State<AltaGastosScreen> createState() => _AltaGastosScreenState();
}

class _AltaGastosScreenState extends State<AltaGastosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costoController = TextEditingController();
  final _fechaGastoController = TextEditingController();
  String? _tipoGastoSeleccionado;

  final List<String> _tiposDeGasto = [
    "Mantenimiento",
    "Papelería",
    "Despensa",
    "Compras"
  ];

  @override
  void initState() {
    super.initState();
    _fechaGastoController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _costoController.dispose();
    _fechaGastoController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaGasto(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Adjust as needed
      lastDate: DateTime(2101), // Adjust as needed
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _fechaGastoController.text = formattedDate;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _costoController.clear();
    _fechaGastoController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _tipoGastoSeleccionado = null;
    });
  }

  Future<void> _guardarGasto() async {
    if (_formKey.currentState!.validate()) {
      double? costo = double.tryParse(_costoController.text);
      if (costo == null) {
        // This should ideally be caught by the validator, but as a safeguard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingrese un costo válido.')),
        );
        return;
      }

      Map<String, dynamic> gastoData = {
        'costo': costo,
        'fecha_gasto': _fechaGastoController.text, // Could also be Timestamp.fromDate(DateFormat('yyyy-MM-dd').parse(_fechaGastoController.text))
        'tipo_gasto': _tipoGastoSeleccionado,
        'fecha_registro': Timestamp.now(),
      };

      try {
        await FirebaseFirestore.instance.collection('gastos').add(gastoData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto guardado exitosamente en Firestore')),
        );
        _resetForm();
      } catch (e) {
        print('Error al guardar gasto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar gasto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(
                  labelText: 'Costo*',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el costo';
                  }
                  final double? costo = double.tryParse(value);
                  if (costo == null) {
                    return 'Por favor, ingrese un número válido';
                  }
                  if (costo <= 0) {
                    return 'El costo debe ser mayor que cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaGastoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha del Gasto*',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectFechaGasto(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, seleccione una fecha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoGastoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Gasto*'),
                items: _tiposDeGasto.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _tipoGastoSeleccionado = newValue;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un tipo de gasto' : null,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarGasto,
                  child: const Text('Guardar Gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

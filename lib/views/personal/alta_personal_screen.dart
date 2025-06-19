import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AltaPersonalScreen extends StatefulWidget {
  final Map<String, dynamic>? personalData;
  final String? documentId;

  const AltaPersonalScreen({super.key, this.personalData, this.documentId});

  @override
  State<AltaPersonalScreen> createState() => _AltaPersonalScreenState();
}

class _AltaPersonalScreenState extends State<AltaPersonalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _rfcController = TextEditingController();
  final _curpController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _nssController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _fechaBajaController = TextEditingController();
  final _razonBajaController = TextEditingController();

  bool _isEditMode = false;

  // Dropdown values
  String? _puestoSeleccionado;
  String? _permisoSeleccionado;
  String? _sexoSeleccionado;

  final List<String> _puestos = [
    'Maestro',
    'Sub director',
    'Director',
    'Director de finanzas',
    'Limpieza',
    'Personal de cocina'
  ];
  final List<String> _permisos = ['Director(a)', 'Maestro'];
  final List<String> _sexos = ['Hombre', 'Mujer', 'Otro'];

  String _fechaAlta = DateFormat('dd/MM/yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.personalData != null && widget.documentId != null) {
      _isEditMode = true;
      _loadPersonalData();
    }
  }

  void _loadPersonalData() {
    final data = widget.personalData!;
    _nombresController.text = data['nombres'] ?? '';
    _apellidoPaternoController.text = data['apellido_paterno'] ?? '';
    _apellidoMaternoController.text = data['apellido_materno'] ?? '';
    _puestoSeleccionado = data['puesto'];
    _permisoSeleccionado = data['permisos'];
    _sexoSeleccionado = data['sexo'];
    _fechaNacimientoController.text = data['fecha_nacimiento'] ?? ''; // Assuming YYYY-MM-DD
    _rfcController.text = data['rfc'] ?? '';
    _curpController.text = data['curp'] ?? '';
    _cedulaController.text = data['cedula'] ?? '';
    _nssController.text = data['nss'] ?? '';
    _fechaAlta = data['fecha_alta'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now()); // Keep original alta date
    _emailController.text = data['email'] ?? '';
    _telefonoController.text = data['telefono'] ?? '';
    _usuarioController.text = data['usuario'] ?? '';
    // Contraseña is not pre-filled for security reasons
    _fechaBajaController.text = data['fecha_baja'] ?? '';
    _razonBajaController.text = data['razon_baja'] ?? '';
    // status is handled by VerPersonalScreen's dropdown directly
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _rfcController.dispose();
    _curpController.dispose();
    _cedulaController.dispose();
    _nssController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _fechaBajaController.dispose();
    _razonBajaController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombresController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _fechaNacimientoController.clear();
    _rfcController.clear();
    _curpController.clear();
    _cedulaController.clear();
    _nssController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _usuarioController.clear();
    _contrasenaController.clear();
    _fechaBajaController.clear();
    _razonBajaController.clear();
    setState(() {
      _puestoSeleccionado = null;
      _permisoSeleccionado = null;
      _sexoSeleccionado = null;
      if (!_isEditMode) { // Only reset fechaAlta if not in edit mode
        _fechaAlta = DateFormat('dd/MM/yyyy').format(DateTime.now());
      }
    });
  }

  Future<void> _guardarPersonal() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> dataMap = {
        'nombres': _nombresController.text,
        'apellido_paterno': _apellidoPaternoController.text,
        'apellido_materno': _apellidoMaternoController.text.isEmpty ? null : _apellidoMaternoController.text,
        'puesto': _puestoSeleccionado,
        'permisos': _permisoSeleccionado,
        'sexo': _sexoSeleccionado,
        'fecha_nacimiento': _fechaNacimientoController.text,
        'rfc': _rfcController.text.isEmpty ? null : _rfcController.text,
        'curp': _curpController.text.isEmpty ? null : _curpController.text,
        'cedula': _cedulaController.text.isEmpty ? null : _cedulaController.text,
        'nss': _nssController.text.isEmpty ? null : _nssController.text,
        'fecha_alta': _fechaAlta, // In edit mode, this preserves the original alta date
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'usuario': _usuarioController.text.isEmpty ? null : _usuarioController.text,
        // 'contrasena': _contrasenaController.text.isEmpty ? null : _contrasenaController.text, // Password ideally not updated here or handled differently
      };

      if (_isEditMode) {
        dataMap['fecha_baja'] = _fechaBajaController.text.isEmpty ? null : _fechaBajaController.text;
        dataMap['razon_baja'] = _razonBajaController.text.isEmpty ? null : _razonBajaController.text;
        // Status is managed by the dropdown in VerPersonalScreen, but if needed here:
        // dataMap['status'] = widget.personalData?['status'] ?? 'Activo';
      } else {
        dataMap['status'] = 'Activo'; // Default status for new entries
        if (_contrasenaController.text.isNotEmpty) { // Only include password if new and provided
           dataMap['contrasena'] = _contrasenaController.text; // Consider hashing
        }
      }


      try {
        if (_isEditMode && widget.documentId != null) {
          await FirebaseFirestore.instance.collection('personal').doc(widget.documentId).update(dataMap);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personal actualizado exitosamente')),
          );
          Navigator.pop(context); // Navigate back after editing
        } else {
          await FirebaseFirestore.instance.collection('personal').add(dataMap);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personal guardado exitosamente en Firestore')),
          );
          _resetForm();
        }
      } catch (e) {
        print('Error al guardar en Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingrese un correo electrónico';
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, ingrese un correo válido';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingrese un teléfono';
    }
    if (int.tryParse(value) == null) {
      return 'Por favor, ingrese solo números';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Personal' : 'Dar de Alta Personal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(labelText: 'Nombre(s)*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoPaternoController,
                decoration: const InputDecoration(labelText: 'Apellido Paterno*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoMaternoController,
                decoration: const InputDecoration(labelText: 'Apellido Materno'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _puestoSeleccionado,
                decoration: const InputDecoration(labelText: 'Puesto*'),
                items: _puestos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _puestoSeleccionado = newValue;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un puesto' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _permisoSeleccionado,
                decoration: const InputDecoration(labelText: 'Permisos'),
                items: _permisos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _permisoSeleccionado = newValue;
                  });
                },
                // validator: (value) { // TODO: Advanced validation if needed
                //   if (_permisoSeleccionado != null && _permisoSeleccionado == value && value == _permisos[0] /* default or initial value */) {
                //     return 'Si selecciona este permiso, debe cambiarlo o seleccionar otro';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexoSeleccionado,
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: _sexos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _sexoSeleccionado = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaNacimientoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento* (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Make it read-only to force use of picker
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900), // Adjust as needed
                    lastDate: DateTime.now(),
                    helpText: 'Seleccione su fecha de nacimiento',
                    cancelText: 'Cancelar',
                    confirmText: 'Aceptar',
                    // You can customize the initial entry mode if needed
                    // initialEntryMode: DatePickerEntryMode.calendarOnly, // or .input
                  );
                  if (pickedDate != null) {
                    String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                    setState(() {
                      _fechaNacimientoController.text = formattedDate;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  // Validate format YYYY-MM-DD
                  try {
                    DateFormat('yyyy-MM-dd').parseStrict(value);
                  } catch (e) {
                    return 'Formato de fecha inválido (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rfcController,
                decoration: const InputDecoration(labelText: 'RFC'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _curpController,
                decoration: const InputDecoration(labelText: 'CURP'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: 'Cédula'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nssController,
                decoration: const InputDecoration(labelText: 'Número del Seguro Social'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _fechaAlta,
                decoration: const InputDecoration(labelText: 'Fecha de Alta'),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico*'),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono*'),
                validator: _validateTelefono,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contrasenaController,
                decoration: InputDecoration(labelText: _isEditMode ? 'Nueva Contraseña (opcional)' : 'Contraseña'),
                obscureText: true,
                // In edit mode, password change is optional
                validator: (value) {
                  if (!_isEditMode && (value == null || value.isEmpty)) {
                    // return 'Este campo es obligatorio para nuevo personal'; // Or make it optional too
                  }
                  return null;
                },
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fechaBajaController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Baja (YYYY-MM-DD)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _fechaBajaController.text.isNotEmpty
                          ? (DateFormat('yyyy-MM-dd').tryParse(_fechaBajaController.text) ?? DateTime.now())
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2101), // Allow future dates for baja
                    );
                    if (pickedDate != null) {
                      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                      setState(() {
                        _fechaBajaController.text = formattedDate;
                      });
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                       try {
                        DateFormat('yyyy-MM-dd').parseStrict(value);
                      } catch (e) {
                        return 'Formato de fecha inválido (YYYY-MM-DD)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _razonBajaController,
                  decoration: const InputDecoration(labelText: 'Razón de la Baja'),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarPersonal,
                  child: Text(_isEditMode ? 'Actualizar' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

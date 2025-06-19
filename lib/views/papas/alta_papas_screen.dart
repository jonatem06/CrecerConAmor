import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Import UUID package

// Helper class to manage controllers for each child's form
class HijoFormControllers {
  final String? idHijoUnico; // To store existing ID in edit mode
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidoPaternoController = TextEditingController();
  final TextEditingController apellidoMaternoController = TextEditingController();
  final TextEditingController fechaNacimientoController = TextEditingController();
  final TextEditingController horaSalidaController = TextEditingController();
  final TextEditingController alergiasController = TextEditingController();

  HijoFormControllers({this.idHijoUnico}); // Constructor to accept existing ID

  void dispose() {
    nombresController.dispose();
    apellidoPaternoController.dispose();
    apellidoMaternoController.dispose();
    fechaNacimientoController.dispose();
    horaSalidaController.dispose();
    alergiasController.dispose();
  }

  void clear() {
    nombresController.clear();
    apellidoPaternoController.clear();
    apellidoMaternoController.clear();
    fechaNacimientoController.clear();
    horaSalidaController.clear();
    alergiasController.clear();
    // idHijoUnico remains as it's either from existing data or will be newly generated
  }

  Map<String, dynamic> toMap() {
    return {
      'id_hijo_unico': idHijoUnico ?? const Uuid().v4(), // Generate new if null
      'nombres': nombresController.text,
      'apellido_paterno': apellidoPaternoController.text,
      'apellido_materno': apellidoMaternoController.text,
      'fecha_nacimiento': fechaNacimientoController.text,
      'hora_salida': horaSalidaController.text.isEmpty ? null : horaSalidaController.text,
      'alergias': alergiasController.text.isEmpty ? null : alergiasController.text,
    };
  }
}

class AltaPapasScreen extends StatefulWidget {
  final Map<String, dynamic>? familiaData;
  final String? documentId;

  const AltaPapasScreen({super.key, this.familiaData, this.documentId});

  @override
  State<AltaPapasScreen> createState() => _AltaPapasScreenState();
}

class _AltaPapasScreenState extends State<AltaPapasScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;

  // Controllers for Padre
  final _padreNombresController = TextEditingController();
  final _padreApellidosController = TextEditingController();
  final _padreFechaNacimientoController = TextEditingController();
  final _padreEmailController = TextEditingController();
  final _padreTelefonoController = TextEditingController();
  final _padreUsuarioController = TextEditingController();
  final _padreContrasenaController = TextEditingController();

  // Controllers for Madre
  final _madreNombresController = TextEditingController();
  final _madreApellidosController = TextEditingController();
  final _madreFechaNacimientoController = TextEditingController();
  final _madreEmailController = TextEditingController();
  final _madreTelefonoController = TextEditingController();
  final _madreUsuarioController = TextEditingController();
  final _madreContrasenaController = TextEditingController();

  List<HijoFormControllers> _hijosForms = [];
  List<TextEditingController> _personasPermitidasControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.familiaData != null && widget.documentId != null) {
      _isEditMode = true;
      _cargarDatosFamilia(widget.familiaData!);
    } else {
      _agregarHijoForm(); // Add one initial empty child form
      _agregarPersonaPermitidaController(); // Add one initial empty permitted person field
    }
  }

  void _cargarDatosFamilia(Map<String, dynamic> data) {
    // Padre
    final padreData = data['padre'] as Map<String, dynamic>? ?? {};
    _padreNombresController.text = padreData['nombres'] ?? '';
    _padreApellidosController.text = padreData['apellidos'] ?? '';
    _padreFechaNacimientoController.text = padreData['fecha_nacimiento'] ?? '';
    _padreEmailController.text = padreData['email'] ?? '';
    _padreTelefonoController.text = padreData['telefono'] ?? '';
    _padreUsuarioController.text = padreData['usuario'] ?? '';

    // Madre
    final madreData = data['madre'] as Map<String, dynamic>? ?? {};
    _madreNombresController.text = madreData['nombres'] ?? '';
    _madreApellidosController.text = madreData['apellidos'] ?? '';
    _madreFechaNacimientoController.text = madreData['fecha_nacimiento'] ?? '';
    _madreEmailController.text = madreData['email'] ?? '';
    _madreTelefonoController.text = madreData['telefono'] ?? '';
    _madreUsuarioController.text = madreData['usuario'] ?? '';

    // Hijos
    final hijosData = data['hijos'] as List<dynamic>? ?? [];
    _hijosForms.forEach((hf) => hf.dispose());
    _hijosForms = [];
    if (hijosData.isNotEmpty) {
      for (var hijoMap in hijosData) {
        if (hijoMap is Map<String, dynamic>) {
          final controllers = HijoFormControllers(idHijoUnico: hijoMap['id_hijo_unico'] as String?);
          controllers.nombresController.text = hijoMap['nombres'] ?? '';
          controllers.apellidoPaternoController.text = hijoMap['apellido_paterno'] ?? '';
          controllers.apellidoMaternoController.text = hijoMap['apellido_materno'] ?? '';
          controllers.fechaNacimientoController.text = hijoMap['fecha_nacimiento'] ?? '';
          controllers.horaSalidaController.text = hijoMap['hora_salida'] ?? '';
          controllers.alergiasController.text = hijoMap['alergias'] ?? '';
          _hijosForms.add(controllers);
        }
      }
    } else {
      _agregarHijoForm(); // Add one empty if none exist in edit mode
    }

    // Personas Permitidas
    final personasData = data['personas_permitidas'] as List<dynamic>? ?? [];
    _personasPermitidasControllers.forEach((c) => c.dispose());
    _personasPermitidasControllers = [];
    if (personasData.isNotEmpty) {
      for (var nombrePersona in personasData) {
        if (nombrePersona is String) {
          _personasPermitidasControllers.add(TextEditingController(text: nombrePersona));
        }
      }
    } else {
      _agregarPersonaPermitidaController(); // Add one empty if none exist
    }
    setState(() {});
  }


  @override
  void dispose() {
    _padreNombresController.dispose();
    _padreApellidosController.dispose();
    _padreFechaNacimientoController.dispose();
    _padreEmailController.dispose();
    _padreTelefonoController.dispose();
    _padreUsuarioController.dispose();
    _padreContrasenaController.dispose();

    _madreNombresController.dispose();
    _madreApellidosController.dispose();
    _madreFechaNacimientoController.dispose();
    _madreEmailController.dispose();
    _madreTelefonoController.dispose();
    _madreUsuarioController.dispose();
    _madreContrasenaController.dispose();

    for (var hijoForm in _hijosForms) {
      hijoForm.dispose();
    }
    for (var controller in _personasPermitidasControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _agregarHijoForm() {
    setState(() {
      // When adding a new form (either initially or by user action),
      // idHijoUnico is null. It will be generated upon saving if it's a new child.
      _hijosForms.add(HijoFormControllers());
    });
  }

  void _eliminarHijoForm(int index) {
    setState(() {
      if (_hijosForms.length > 1) {
        _hijosForms[index].dispose();
        _hijosForms.removeAt(index);
      } else if (_hijosForms.length == 1 && !_isEditMode) {
        // Allow removing the initial empty form if not in edit mode, then add a new one
        _hijosForms[index].dispose();
        _hijosForms.removeAt(index);
        _agregarHijoForm();
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe haber al menos un hijo.')),
        );
      }
    });
  }

  void _agregarPersonaPermitidaController() {
    setState(() {
      _personasPermitidasControllers.add(TextEditingController());
    });
  }

  void _eliminarPersonaPermitidaController(int index) {
    setState(() {
      if (_personasPermitidasControllers.length > 1) {
        _personasPermitidasControllers[index].dispose();
        _personasPermitidasControllers.removeAt(index);
      } else if (_personasPermitidasControllers.length == 1 && !_isEditMode) {
        _personasPermitidasControllers[index].dispose();
        _personasPermitidasControllers.removeAt(index);
        _agregarPersonaPermitidaController();
      }
       else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe haber al menos una persona permitida.')),
        );
      }
    });
  }

  void _resetFormCompleto() {
    _formKey.currentState?.reset();

    _padreNombresController.clear();
    _padreApellidosController.clear();
    _padreFechaNacimientoController.clear();
    _padreEmailController.clear();
    _padreTelefonoController.clear();
    _padreUsuarioController.clear();
    _padreContrasenaController.clear();

    _madreNombresController.clear();
    _madreApellidosController.clear();
    _madreFechaNacimientoController.clear();
    _madreEmailController.clear();
    _madreTelefonoController.clear();
    _madreUsuarioController.clear();
    _madreContrasenaController.clear();

    for (var hijoForm in _hijosForms) {
      hijoForm.dispose();
    }
    _hijosForms = [];
    _agregarHijoForm();

    for (var controller in _personasPermitidasControllers) {
      controller.dispose();
    }
    _personasPermitidasControllers = [];
    _agregarPersonaPermitidaController();

    setState(() {});
  }


  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? initialEntryDate;
    if (controller.text.isNotEmpty) {
      try {
        initialEntryDate = DateFormat('yyyy-MM-dd').parseStrict(controller.text);
      } catch (e) {
        initialEntryDate = DateTime.now();
      }
    } else {
      initialEntryDate = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialEntryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Or DateTime(2101) if future dates are allowed for some fields
      helpText: 'Seleccione fecha',
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName no puede estar vacío';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value)) {
      return 'Formato de correo inválido';
    }
    return null;
  }

  Future<void> _guardarPapas() async {
    if (_formKey.currentState!.validate()) {
      bool hijosValidos = true;
      if (_hijosForms.isNotEmpty) { // Only validate if there is at least one child form
        for (var hijoForm in _hijosForms) {
          if (hijoForm.nombresController.text.isEmpty ||
              hijoForm.apellidoPaternoController.text.isEmpty ||
              hijoForm.apellidoMaternoController.text.isEmpty ||
              hijoForm.fechaNacimientoController.text.isEmpty) {
            hijosValidos = false;
            break;
          }
        }
      }
      if (!hijosValidos) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete los campos obligatorios de todos los hijos.')),
        );
        return;
      }

      bool personasPermitidasValidas = true;
       if (_personasPermitidasControllers.isNotEmpty) {
        for (var controller in _personasPermitidasControllers) {
          if (controller.text.isEmpty) {
            personasPermitidasValidas = false;
            break;
          }
        }
      }
      if (!personasPermitidasValidas) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete el nombre de todas las personas permitidas.')),
        );
        return;
      }

      Map<String, dynamic> familiaData = {
        'padre': {
          'nombres': _padreNombresController.text,
          'apellidos': _padreApellidosController.text,
          'fecha_nacimiento': _padreFechaNacimientoController.text,
          'email': _padreEmailController.text.isEmpty ? null : _padreEmailController.text,
          'telefono': _padreTelefonoController.text.isEmpty ? null : _padreTelefonoController.text,
          'usuario': _padreUsuarioController.text.isEmpty ? null : _padreUsuarioController.text,
        },
        'madre': {
          'nombres': _madreNombresController.text,
          'apellidos': _madreApellidosController.text,
          'fecha_nacimiento': _madreFechaNacimientoController.text,
          'email': _madreEmailController.text.isEmpty ? null : _madreEmailController.text,
          'telefono': _madreTelefonoController.text.isEmpty ? null : _madreTelefonoController.text,
          'usuario': _madreUsuarioController.text.isEmpty ? null : _madreUsuarioController.text,
        },
        'hijos': _hijosForms.map((hijoForm) => hijoForm.toMap()).toList(),
        'personas_permitidas': _personasPermitidasControllers.map((controller) => controller.text).where((name) => name.isNotEmpty).toList(),
        'status': widget.familiaData?['status'] ?? 'Activo',
      };

      if (!_isEditMode) {
        familiaData['fecha_alta_familia'] = Timestamp.now();
        familiaData['permiso'] = 'papa';
      }

      if (_padreContrasenaController.text.isNotEmpty) {
        familiaData['padre']['contrasena'] = _padreContrasenaController.text;
      }
      if (_madreContrasenaController.text.isNotEmpty) {
        familiaData['madre']['contrasena'] = _madreContrasenaController.text;
      }

      try {
        if (_isEditMode && widget.documentId != null) {
          await FirebaseFirestore.instance.collection('familias').doc(widget.documentId).update(familiaData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Familia actualizada exitosamente')),
          );
          Navigator.pop(context);
        } else {
          await FirebaseFirestore.instance.collection('familias').add(familiaData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Familia guardada exitosamente en Firestore')),
          );
          _resetFormCompleto();
        }
      } catch (e) {
        print('Error al guardar familia: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar familia: $e')),
        );
      }
    }
  }

  Widget _buildParentSection({
    required String title,
    required TextEditingController nombresController,
    required TextEditingController apellidosController,
    required TextEditingController fechaNacimientoController,
    required TextEditingController emailController,
    required TextEditingController telefonoController,
    required TextEditingController usuarioController,
    required TextEditingController contrasenaController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextFormField(
          controller: nombresController,
          decoration: const InputDecoration(labelText: 'Nombre(s)*'),
          validator: (value) => _validateNotEmpty(value, 'Nombre(s)'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: apellidosController,
          decoration: const InputDecoration(labelText: 'Apellidos*'),
          validator: (value) => _validateNotEmpty(value, 'Apellidos'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: fechaNacimientoController,
          decoration: const InputDecoration(
            labelText: 'Fecha de Nacimiento* (YYYY-MM-DD)',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () => _selectDate(context, fechaNacimientoController),
          validator: (value) => _validateNotEmpty(value, 'Fecha de Nacimiento'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Correo Electrónico'),
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: telefonoController,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usuarioController,
          decoration: const InputDecoration(labelText: 'Usuario'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: contrasenaController,
          decoration: InputDecoration(labelText: _isEditMode && (title.contains("Padre") || title.contains("Madre")) ? 'Nueva Contraseña (opcional)' : 'Contraseña'),
          obscureText: true,
           validator: (value) {
            if (!_isEditMode && (title.contains("Padre") || title.contains("Madre")) && (value == null || value.isEmpty)) {
              // Optional: Make password mandatory for new parents if desired
              // return 'Contraseña es obligatoria para nuevos registros';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Familia' : 'Dar de alta Papás'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildParentSection(
                title: 'Información del Padre',
                nombresController: _padreNombresController,
                apellidosController: _padreApellidosController,
                fechaNacimientoController: _padreFechaNacimientoController,
                emailController: _padreEmailController,
                telefonoController: _padreTelefonoController,
                usuarioController: _padreUsuarioController,
                contrasenaController: _padreContrasenaController,
              ),
              const Divider(height: 32, thickness: 2),
              _buildParentSection(
                title: 'Información de la Madre',
                nombresController: _madreNombresController,
                apellidosController: _madreApellidosController,
                fechaNacimientoController: _madreFechaNacimientoController,
                emailController: _madreEmailController,
                telefonoController: _madreTelefonoController,
                usuarioController: _madreUsuarioController,
                contrasenaController: _madreContrasenaController,
              ),
              const Divider(height: 32, thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Información de Hijos", style: Theme.of(context).textTheme.titleLarge),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _hijosForms.length,
                itemBuilder: (context, index) {
                  return _buildHijoForm(index);
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Hijo'),
                  onPressed: _agregarHijoForm,
                ),
              ),
              const Divider(height: 32, thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Personas Permitidas para recoger a los Hijos", style: Theme.of(context).textTheme.titleLarge),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _personasPermitidasControllers.length,
                itemBuilder: (context, index) {
                  return _buildPersonaPermitidaForm(index);
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar Persona Permitida'),
                  onPressed: _agregarPersonaPermitidaController,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarPapas,
                  child: Text(_isEditMode ? 'Actualizar Familia' : 'Guardar Familia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHijoForm(int index) {
    HijoFormControllers hijoForm = _hijosForms[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hijo ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                if (_hijosForms.length > 1 || (_hijosForms.length == 1 && !_isEditMode ))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarHijoForm(index),
                  ),
              ],
            ),
            TextFormField(
              controller: hijoForm.nombresController,
              decoration: const InputDecoration(labelText: 'Nombre(s) del Hijo*'),
              validator: (value) => _validateNotEmpty(value, 'Nombre(s) del Hijo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: hijoForm.apellidoPaternoController,
              decoration: const InputDecoration(labelText: 'Apellido Paterno del Hijo*'),
              validator: (value) => _validateNotEmpty(value, 'Apellido Paterno del Hijo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: hijoForm.apellidoMaternoController,
              decoration: const InputDecoration(labelText: 'Apellido Materno del Hijo*'),
               validator: (value) => _validateNotEmpty(value, 'Apellido Materno del Hijo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: hijoForm.fechaNacimientoController,
              decoration: const InputDecoration(
                labelText: 'Fecha de Nacimiento del Hijo* (YYYY-MM-DD)',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, hijoForm.fechaNacimientoController),
              validator: (value) => _validateNotEmpty(value, 'Fecha de Nacimiento del Hijo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: hijoForm.horaSalidaController,
              decoration: const InputDecoration(labelText: 'Hora de Salida (ej. 14:00)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: hijoForm.alergiasController,
              decoration: const InputDecoration(labelText: 'Alergias'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildPersonaPermitidaForm(int index) {
    TextEditingController controller = _personasPermitidasControllers[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Nombre completo Persona ${index + 1}*'),
                validator: (value) => _validateNotEmpty(value, 'Nombre completo Persona ${index + 1}'),
              ),
            ),
            if (_personasPermitidasControllers.length > 1 || (_personasPermitidasControllers.length == 1 && !_isEditMode))
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarPersonaPermitidaController(index),
              ),
          ],
        ),
      ),
    );
  }
}

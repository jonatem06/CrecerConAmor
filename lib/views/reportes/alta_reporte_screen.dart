import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AltaReporteScreen extends StatefulWidget {
  const AltaReporteScreen({super.key});

  @override
  State<AltaReporteScreen> createState() => _AltaReporteScreenState();
}

class _AltaReporteScreenState extends State<AltaReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _idNinoController = TextEditingController(); // Replaced by _idNinoSeleccionado
  String? _idNinoSeleccionado;
  List<Map<String, dynamic>> _listaNinosParaSelector = [];
  bool _cargandoNinos = true;

  final _fechaReporteController = TextEditingController();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _tipoReporteSeleccionado;

  final List<String> _tiposDeReporte = [
    "Académico",
    "Comportamiento",
    "Salud",
    "General"
  ];

  @override
  void initState() {
    super.initState();
    _fechaReporteController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _cargarNinos();

    // Placeholder for permission check
    // TODO: Replace with actual permission logic based on user profile
    String? userPermiso = FirebaseAuth.instance.currentUser?.displayName; // Example, replace with actual permission field
    print("DEBUG: Pantalla AltaReporteScreen accesible. Permiso del usuario actual (placeholder): ${userPermiso ?? 'No logueado o sin permiso definido'}");
  }

  Future<void> _cargarNinos() async {
    setState(() {
      _cargandoNinos = true;
    });
    try {
      QuerySnapshot familiasSnapshot = await FirebaseFirestore.instance.collection('familias').get();
      List<Map<String, dynamic>> ninosList = [];
      for (var familiaDoc in familiasSnapshot.docs) {
        final familiaData = familiaDoc.data() as Map<String, dynamic>?;
        if (familiaData != null && familiaData.containsKey('hijos') && familiaData['hijos'] is List) {
          List<dynamic> hijos = familiaData['hijos'];
          for (int i = 0; i < hijos.length; i++) {
            if (hijos[i] is Map<String, dynamic>) {
              Map<String, dynamic> hijoData = hijos[i] as Map<String, dynamic>;
              String nombre = hijoData['nombres'] ?? 'Desconocido';
              String apellidoP = hijoData['apellido_paterno'] ?? '';
              String apellidoM = hijoData['apellido_materno'] ?? '';
              String nombreCompleto = '$nombre $apellidoP $apellidoM'.trim();

              String? idRealNino = hijoData['id_hijo_unico'] as String?;

              if (idRealNino == null || idRealNino.isEmpty) {
                print("ADVERTENCIA: Niño '${nombreCompleto}' (Familia ID: ${familiaDoc.id}, Index: $i) omitido del selector por no tener id_hijo_unico.");
                continue; // Skip this child
              }
              ninosList.add({'id': idRealNino, 'nombre_completo': nombreCompleto});
            }
          }
        }
      }
      setState(() {
        _listaNinosParaSelector = ninosList;
        _cargandoNinos = false;
      });
    } catch (e) {
      print("Error cargando niños: $e");
      setState(() {
        _cargandoNinos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar lista de niños: $e')),
      );
    }
  }

  @override
  void dispose() {
    // _idNinoController.dispose(); // No longer used
    _fechaReporteController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaReporte(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _fechaReporteController.text = formattedDate;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _idNinoSeleccionado = null; // Reset selected child ID
    _tituloController.clear();
    _descripcionController.clear();
    _fechaReporteController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _tipoReporteSeleccionado = null;
    });
  }

  Future<void> _guardarReporte() async {
    if (_formKey.currentState!.validate()) {
      if (_idNinoSeleccionado == null) { // Ensure a child is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione un niño.')),
        );
        return;
      }
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo obtener el ID del usuario. Asegúrese de estar logueado.')),
        );
        return;
      }

      Map<String, dynamic> reporteData = {
        'id_nino': _idNinoSeleccionado, // Use selected ID
        'fecha_reporte': _fechaReporteController.text,
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'tipo_reporte': _tipoReporteSeleccionado,
        'id_usuario_creador': userId,
        'fecha_creacion_reporte': Timestamp.now(),
        'status_reporte': 'Activo', // Default status
      };

      try {
        await FirebaseFirestore.instance.collection('reportes').add(reporteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte guardado exitosamente en Firestore')),
        );
        _resetForm();
      } catch (e) {
        print('Error al guardar reporte: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar reporte: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _cargandoNinos
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _idNinoSeleccionado,
                        hint: const Text('Seleccione un Niño*'),
                        isExpanded: true,
                        items: _listaNinosParaSelector.map((nino) {
                          return DropdownMenuItem<String>(
                            value: nino['id'] as String,
                            child: Text(nino['nombre_completo'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _idNinoSeleccionado = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, seleccione un niño';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fechaReporteController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha del Reporte*',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectFechaReporte(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, seleccione una fecha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título del Reporte*'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción del Reporte*'),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipoReporteSeleccionado,
                  decoration: const InputDecoration(labelText: 'Tipo de Reporte*'),
                  items: _tiposDeReporte.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _tipoReporteSeleccionado = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Seleccione un tipo de reporte' : null,
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _guardarReporte,
                    child: const Text('Guardar Reporte'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

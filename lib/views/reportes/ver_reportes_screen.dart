import 'package:control_escolar_app/views/reportes/alta_reporte_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates, if needed

class VerReportesScreen extends StatefulWidget {
  const VerReportesScreen({super.key});

  @override
  State<VerReportesScreen> createState() => _VerReportesScreenState();
}

class _VerReportesScreenState extends State<VerReportesScreen> {
  String? _filtroMaestroSeleccionado;
  String? _filtroNinoSeleccionado;

  List<Map<String, dynamic>> _listaMaestrosFiltro = [];
  List<Map<String, dynamic>> _listaNinosFiltro = []; // Used by Director/Maestro for general child filter
  List<Map<String, dynamic>> _hijosDelPapa = [];   // Used by Papa to list their children
  String? _idNinoSeleccionadoPorPapa;
  String? _familiaIdDelPapa; // Optional: good for context if needed later

  bool _cargandoFiltros = true; // For Director/Maestro child filter
  bool _cargandoDatosPapa = true; // Specifically for Papa's children list

  Stream<QuerySnapshot>? _reportesStream;
  String? _userRole;
  bool _isLoadingRole = true;


  @override
  void initState() {
    super.initState();
    _determineUserRoleAndLoadData();
  }

  Future<void> _determineUserRoleAndLoadData() async {
    setState(() { _isLoadingRole = true; });
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() {
        _userRole = "Desconocido";
        _isLoadingRole = false;
        _reportesStream = Stream.empty();
      });
      return;
    }

    try {
      DocumentSnapshot personalDoc = await FirebaseFirestore.instance
          .collection('personal')
          .doc(currentUser.uid)
          .get();

      if (personalDoc.exists) {
        final data = personalDoc.data() as Map<String, dynamic>?;
        String puesto = data?['puesto'] ?? 'Otro';
        if (puesto == 'Director') {
          _userRole = 'Director';
        } else if (puesto == 'Maestro') {
          _userRole = 'Maestro';
        } else {
          _userRole = 'Otro';
        }
        await _cargarListasParaFiltros();
      } else {
        // Check if user is a 'Papa'
        QuerySnapshot familiaPadreQuery = await FirebaseFirestore.instance
            .collection('familias')
            .where('padre.auth_uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        QuerySnapshot familiaMadreQuery;

        if (familiaPadreQuery.docs.isNotEmpty) {
          _userRole = "Papa";
          final familiaDoc = familiaPadreQuery.docs.first;
          _familiaIdDelPapa = familiaDoc.id;
          final familiaData = familiaDoc.data() as Map<String, dynamic>?;
          _cargarHijosDelPapa(familiaData);
        } else {
          familiaMadreQuery = await FirebaseFirestore.instance
              .collection('familias')
              .where('madre.auth_uid', isEqualTo: currentUser.uid)
              .limit(1)
              .get();
          if (familiaMadreQuery.docs.isNotEmpty) {
             _userRole = "Papa";
             final familiaDoc = familiaMadreQuery.docs.first;
             _familiaIdDelPapa = familiaDoc.id;
             final familiaData = familiaDoc.data() as Map<String, dynamic>?;
            _cargarHijosDelPapa(familiaData);
          } else {
            _userRole = "Otro";
          }
        }
      }
    } catch (e) {
      print("Error determinando rol: $e");
      _userRole = "Error";
    } finally {
       setState(() { _isLoadingRole = false; });
      _actualizarStreamReportes();
    }
  }

  void _cargarHijosDelPapa(Map<String, dynamic>? familiaData) {
    if (familiaData != null && familiaData.containsKey('hijos') && familiaData['hijos'] is List) {
      List<dynamic> hijos = familiaData['hijos'];
      List<Map<String, dynamic>> tempHijos = [];
      for (int i = 0; i < hijos.length; i++) {
        if (hijos[i] is Map<String, dynamic>) {
          Map<String, dynamic> hijoData = hijos[i] as Map<String, dynamic>;
          String? idRealNino = hijoData['id_hijo_unico'] as String?;
          String nombre = hijoData['nombres'] ?? 'Desconocido';
          String apellidoP = hijoData['apellido_paterno'] ?? '';
          String apellidoM = hijoData['apellido_materno'] ?? '';
          String nombreCompleto = '$nombre $apellidoP $apellidoM'.trim();

          if (idRealNino != null && idRealNino.isNotEmpty) {
            tempHijos.add({'id': idRealNino, 'nombre_completo': nombreCompleto});
          }
        }
      }
      _hijosDelPapa = tempHijos;
    }
    _cargandoDatosPapa = false; // Assuming this is called after role is determined
  }

  Future<void> _cargarListasParaFiltros() async {
    if (_userRole == "Director") {
      await _cargarMaestrosParaFiltro();
    }
    // For Director/Maestro, _cargarNinosParaFiltro populates the general child filter
    // For Papa, their children are loaded via _cargarHijosDelPapa
    if (_userRole == "Director" || _userRole == "Maestro") {
      await _cargarNinosParaFiltro();
    }
    setState(() {
      _cargandoFiltros = false;
    });
  }

  Future<void> _cargarMaestrosParaFiltro() async {
    try {
      QuerySnapshot personalSnapshot = await FirebaseFirestore.instance
          .collection('personal')
          .where('puesto', whereIn: ['Maestro', 'Director'])
          .orderBy('apellido_paterno')
          .get();

      List<Map<String, dynamic>> maestros = personalSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String nombreCompleto = "${data['apellido_paterno'] ?? ''} ${data['apellido_materno'] ?? ''} ${data['nombres'] ?? ''}".trim();
        if (nombreCompleto.isEmpty) nombreCompleto = "Nombre no disponible";
        return {'id': doc.id, 'nombre': nombreCompleto};
      }).toList();

      setState(() {
        _listaMaestrosFiltro = maestros;
      });
    } catch (e) {
      print("Error cargando maestros para filtro: $e");
      // Handle error appropriately, maybe show a SnackBar
    }
  }

   Future<void> _cargarNinosParaFiltro() async {
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
              String? idRealNino = hijoData['id_hijo_unico'] as String?;
              String nombre = hijoData['nombres'] ?? 'Desconocido';
              String apellidoP = hijoData['apellido_paterno'] ?? '';
              String apellidoM = hijoData['apellido_materno'] ?? '';
              String nombreCompleto = '$nombre $apellidoP $apellidoM'.trim();

              if (idRealNino != null && idRealNino.isNotEmpty) {
                ninosList.add({'id': idRealNino, 'nombre_completo': nombreCompleto});
              } else {
                 print("ADVERTENCIA (Filtro): Niño '${nombreCompleto}' (Familia ID: ${familiaDoc.id}, Index: $i) omitido por no tener id_hijo_unico.");
              }
            }
          }
        }
      }
      // Sort children by name for consistent dropdown order
      ninosList.sort((a, b) => (a['nombre_completo'] as String).compareTo(b['nombre_completo'] as String));
      setState(() {
        _listaNinosFiltro = ninosList;
      });
    } catch (e) {
      print("Error cargando niños para filtro: $e");
      // Handle error
    }
  }

  void _actualizarStreamReportes() {
    if (_isLoadingRole) return;

    Query query = FirebaseFirestore.instance.collection('reportes');

    if (_userRole == "Maestro") {
      query = query.where('id_usuario_creador', isEqualTo: FirebaseAuth.instance.currentUser!.uid);
      if (_filtroNinoSeleccionado != null && _filtroNinoSeleccionado != 'todos_ninos') {
        query = query.where('id_nino', isEqualTo: _filtroNinoSeleccionado);
      }
    } else if (_userRole == "Director") {
      if (_filtroMaestroSeleccionado != null && _filtroMaestroSeleccionado != 'todos_maestros') {
        query = query.where('id_usuario_creador', isEqualTo: _filtroMaestroSeleccionado);
      }
      if (_filtroNinoSeleccionado != null && _filtroNinoSeleccionado != 'todos_ninos') {
        query = query.where('id_nino', isEqualTo: _filtroNinoSeleccionado);
      }
    } else if (_userRole == "Papa") {
      if (_idNinoSeleccionadoPorPapa == null || _idNinoSeleccionadoPorPapa!.isEmpty) {
        setState(() { _reportesStream = Stream.empty(); }); // No child selected, show no reports
        return;
      }
      query = query.where('id_nino', isEqualTo: _idNinoSeleccionadoPorPapa);
    }
     else {
      setState(() { _reportesStream = Stream.empty(); });
      return;
    }

    query = query.orderBy('fecha_creacion_reporte', descending: true);

    setState(() {
      _reportesStream = query.snapshots();
    });
  }

  void _mostrarDescripcion(BuildContext context, String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(child: Text(descripcion)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoadingRole ? 'Cargando...' :
          _userRole == "Papa" ? "Reportes de mis Hijos" : 'Reportes (${_userRole ?? "N/A"})'
        ),
        actions: [
          if (!_isLoadingRole && (_userRole == "Maestro" || _userRole == "Director"))
            IconButton(
              icon: const Icon(Icons.add_comment),
              tooltip: 'Nuevo Reporte',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AltaReporteScreen()),
                );
              },
            ),
        ],
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : _userRole == "Otro" || _userRole == "Desconocido" || _userRole == "Error"
              ? const Center(child: Text('No tiene permiso para ver esta sección o error al determinar el rol.'))
              : _userRole == "Papa"
                  ? _buildVistaPapa()
                  : _buildVistaDirectorMaestro(),
    );
  }

  Widget _buildVistaDirectorMaestro() {
     return Column(
        children: [
          // --- FILTERS ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_userRole == "Director")
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filtroMaestroSeleccionado,
                      hint: const Text('Filtrar por Maestro'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'todos_maestros',
                          child: Text('Todos los Maestros'),
                        ),
                        ..._listaMaestrosFiltro.map((maestro) {
                          return DropdownMenuItem<String>(
                            value: maestro['id'] as String,
                            child: Text(maestro['nombre'] as String),
                          );
                        }).toList(),
                      ],
                      onChanged: _cargandoFiltros ? null : (value) {
                        setState(() {
                          _filtroMaestroSeleccionado = value == 'todos_maestros' ? null : value;
                          _actualizarStreamReportes();
                        });
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      disabledHint: _cargandoFiltros ? const Text("Cargando...") : null,
                    ),
                  ),
                if (_userRole == "Director") const SizedBox(width: 8),
                Expanded( // Niño filter visible for Director and Maestro
                  child: DropdownButtonFormField<String>(
                    value: _filtroNinoSeleccionado,
                    hint: const Text('Filtrar por Niño'),
                    items: [
                       const DropdownMenuItem<String>(
                        value: 'todos_ninos', // Special value for "all"
                        child: Text('Todos los Niños'),
                      ),
                      ..._listaNinosFiltro.map((nino) {
                        return DropdownMenuItem<String>(
                          value: nino['id'] as String,
                          child: Text(nino['nombre_completo'] as String),
                        );
                      }).toList(),
                    ],
                    onChanged: _cargandoFiltros ? null : (value) {
                       setState(() {
                        _filtroNinoSeleccionado = value == 'todos_ninos' ? null : value;
                        _actualizarStreamReportes();
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    disabledHint: _cargandoFiltros ? const Text("Cargando...") : null,
                  ),
                ),
              ],
            ),
          ),
          // --- END FILTERS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _reportesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay reportes para los filtros seleccionados.'));
                }

                final reportesDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reportesDocs.length,
                  itemBuilder: (context, index) {
                    final data = reportesDocs[index].data() as Map<String, dynamic>;
                    final fechaReporte = data['fecha_reporte'] ?? 'N/A';
                    final idNino = data['id_nino'] ?? 'N/A';
                    final idCreador = data['id_usuario_creador'] ?? 'N/A';
                    final titulo = data['titulo'] ?? 'Sin título';
                    final descripcion = data['descripcion'] ?? 'Sin descripción.';

                    String fechaCreacionStr = 'N/A';
                    if (data['fecha_creacion_reporte'] is Timestamp) {
                       fechaCreacionStr = DateFormat('yyyy-MM-dd HH:mm').format((data['fecha_creacion_reporte'] as Timestamp).toDate());
                    }


                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Niño ID: $idNino'),
                            Text('Fecha Reporte: $fechaReporte'),
                            Text('Tipo: ${data['tipo_reporte'] ?? 'No especificado'}'),
                            Text('Creado por ID: $idCreador'),
                            Text('Fecha Creación: $fechaCreacionStr'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.description_outlined),
                          tooltip: 'Ver Descripción',
                          onPressed: () => _mostrarDescripcion(context, titulo, descripcion),
                        ),
                        isThreeLine: false, // Adjust based on content, might need to be true
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaPapa() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Seleccione un hijo para ver sus reportes:", style: Theme.of(context).textTheme.titleMedium),
        ),
        if (_cargandoDatosPapa) const LinearProgressIndicator(),
        SizedBox(
          height: 150, // Adjust height as needed
          child: _hijosDelPapa.isEmpty && !_cargandoDatosPapa
              ? const Center(child: Text("No tiene hijos registrados o no se pudieron cargar."))
              : ListView.builder(
                  itemCount: _hijosDelPapa.length,
                  itemBuilder: (context, index) {
                    final hijo = _hijosDelPapa[index];
                    return ListTile(
                      title: Text(hijo['nombre_completo'] as String),
                      selected: _idNinoSeleccionadoPorPapa == hijo['id'] as String?,
                      onTap: () {
                        setState(() {
                          _idNinoSeleccionadoPorPapa = hijo['id'] as String?;
                        });
                        _actualizarStreamReportes();
                      },
                    );
                  },
                ),
        ),
        const Divider(),
        Expanded(
          child: _idNinoSeleccionadoPorPapa == null
              ? const Center(child: Text("Seleccione un hijo para ver sus reportes."))
              : StreamBuilder<QuerySnapshot>(
                  stream: _reportesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hay reportes para este hijo.'));
                    }
                    final reportesDocs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: reportesDocs.length,
                      itemBuilder: (context, index) {
                        final data = reportesDocs[index].data() as Map<String, dynamic>;
                        final fechaReporte = data['fecha_reporte'] ?? 'N/A';
                        final idCreador = data['id_usuario_creador'] ?? 'N/A'; // Could fetch maestro name
                        final titulo = data['titulo'] ?? 'Sin título';
                        final descripcion = data['descripcion'] ?? 'Sin descripción.';
                         String fechaCreacionStr = 'N/A';
                        if (data['fecha_creacion_reporte'] is Timestamp) {
                           fechaCreacionStr = DateFormat('yyyy-MM-dd HH:mm').format((data['fecha_creacion_reporte'] as Timestamp).toDate());
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Fecha Reporte: $fechaReporte'),
                                Text('Tipo: ${data['tipo_reporte'] ?? 'No especificado'}'),
                                Text('Creado por ID: $idCreador'), // Consider fetching Maestro name
                                Text('Fecha Creación: $fechaCreacionStr'),
                              ],
                            ),
                             trailing: IconButton(
                              icon: const Icon(Icons.description_outlined),
                              tooltip: 'Ver Descripción',
                              onPressed: () => _mostrarDescripcion(context, titulo, descripcion),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

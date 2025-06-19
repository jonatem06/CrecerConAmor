import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AsignarMaestrosScreen extends StatefulWidget {
  const AsignarMaestrosScreen({super.key});

  @override
  State<AsignarMaestrosScreen> createState() => _AsignarMaestrosScreenState();
}

class _AsignarMaestrosScreenState extends State<AsignarMaestrosScreen> {
  String? _maestroSeleccionadoId;
  String? _maestroSeleccionadoNombre;

  final List<Map<String, dynamic>> _todosLosNinosSimulados = [
    {'id_nino': 'sim_nino_001', 'nombre_nino': 'Ana Simulada Torres'},
    {'id_nino': 'sim_nino_002', 'nombre_nino': 'Pedro Simulado Vega'},
    {'id_nino': 'sim_nino_003', 'nombre_nino': 'Luisa Simulada Lara'},
    {'id_nino': 'sim_nino_004', 'nombre_nino': 'Carlos Simulado Mora'},
    {'id_nino': 'sim_nino_005', 'nombre_nino': 'Elena Simulada Ríos'},
    {'id_nino': 'sim_nino_006', 'nombre_nino': 'Miguel Simulado Garza'}
  ];

  List<Map<String, dynamic>> _ninosAsignadosAlMaestroActual = [];
  List<Map<String, dynamic>> _ninosNoAsignados = [];
  bool _cargandoNinos = false;

  Future<void> _cargarDatosNinos(String maestroId) async {
    setState(() {
      _cargandoNinos = true;
      _ninosAsignadosAlMaestroActual = [];
      _ninosNoAsignados = [];
    });

    try {
      DocumentSnapshot maestroDoc = await FirebaseFirestore.instance
          .collection('personal')
          .doc(maestroId)
          .get();

      List<String> idsNinosAsignados = [];
      if (maestroDoc.exists && maestroDoc.data() != null) {
        final data = maestroDoc.data() as Map<String, dynamic>;
        if (data.containsKey('ninos_asignados') && data['ninos_asignados'] is List) {
          idsNinosAsignados = List<String>.from(data['ninos_asignados']);
        }
      }

      List<Map<String, dynamic>> asignadosTemp = [];
      List<Map<String, dynamic>> noAsignadosTemp = [];

      for (var nino in _todosLosNinosSimulados) {
        if (idsNinosAsignados.contains(nino['id_nino'])) {
          asignadosTemp.add(nino);
        } else {
          noAsignadosTemp.add(nino);
        }
      }
      setState(() {
        _ninosAsignadosAlMaestroActual = asignadosTemp;
        _ninosNoAsignados = noAsignadosTemp;
      });
    } catch (e) {
      print("Error cargando niños: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de niños: $e')),
      );
    } finally {
      setState(() {
        _cargandoNinos = false;
      });
    }
  }

  Future<void> _asignarNino(String maestroId, String idNino, String nombreNino) async {
    try {
      await FirebaseFirestore.instance.collection('personal').doc(maestroId).update({
        'ninos_asignados': FieldValue.arrayUnion([idNino])
      });
      setState(() {
        _ninosNoAsignados.removeWhere((nino) => nino['id_nino'] == idNino);
        _ninosAsignadosAlMaestroActual.add({'id_nino': idNino, 'nombre_nino': nombreNino});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombreNino asignado a $_maestroSeleccionadoNombre')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar niño: $e')),
      );
    }
  }

  Future<void> _desasignarNino(String maestroId, String idNino, String nombreNino) async {
    try {
      await FirebaseFirestore.instance.collection('personal').doc(maestroId).update({
        'ninos_asignados': FieldValue.arrayRemove([idNino])
      });
      setState(() {
        _ninosAsignadosAlMaestroActual.removeWhere((nino) => nino['id_nino'] == idNino);
        _ninosNoAsignados.add({'id_nino': idNino, 'nombre_nino': nombreNino});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombreNino desasignado de $_maestroSeleccionadoNombre')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al desasignar niño: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Maestros a Niños'),
      ),
      body: Row(
        children: [
          // Lista de Maestros
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('personal')
                  .where('puesto', whereIn: ['Maestro', 'Director'])
                  .orderBy('apellido_paterno')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay maestros disponibles.'));
                }

                final maestrosDocs = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Maestros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: maestrosDocs.length,
                        itemBuilder: (context, index) {
                          final data = maestrosDocs[index].data() as Map<String, dynamic>;
                          final docId = maestrosDocs[index].id;
                          String nombreCompleto =
                              "${data['apellido_paterno'] ?? ''} ${data['apellido_materno'] ?? ''} ${data['nombres'] ?? ''}";

                          return ListTile(
                            title: Text(nombreCompleto.trim()),
                            selected: _maestroSeleccionadoId == docId,
                            onTap: () {
                              setState(() {
                                _maestroSeleccionadoId = docId;
                                _maestroSeleccionadoNombre = nombreCompleto.trim();
                                _cargarDatosNinos(docId);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Separador Vertical
          const VerticalDivider(width: 1),

          // Sección de Niños (Asignados y No Asignados)
          Expanded(
            flex: 2,
            child: _maestroSeleccionadoId == null
                ? const Center(child: Text('Seleccione un maestro para ver los niños.'))
                : _cargandoNinos
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Gestionar Niños para: $_maestroSeleccionadoNombre',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Niños Asignados a $_maestroSeleccionadoNombre', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                child: _ninosAsignadosAlMaestroActual.isEmpty
                                  ? Container(alignment: Alignment.center, color: Colors.grey[200], child: const Text('No hay niños asignados.'))
                                  : ListView.builder(
                                      itemCount: _ninosAsignadosAlMaestroActual.length,
                                      itemBuilder: (context, index) {
                                        final nino = _ninosAsignadosAlMaestroActual[index];
                                        return ListTile(
                                          title: Text(nino['nombre_nino']),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () {
                                              _desasignarNino(_maestroSeleccionadoId!, nino['id_nino'], nino['nombre_nino']);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                              ),
                              const SizedBox(height: 10),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Niños No Asignados (Disponibles)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                child: _ninosNoAsignados.isEmpty
                                  ? Container(alignment: Alignment.center, color: Colors.grey[200], child: const Text('Todos los niños están asignados o no hay niños disponibles.'))
                                  : ListView.builder(
                                    itemCount: _ninosNoAsignados.length,
                                    itemBuilder: (context, index) {
                                      final nino = _ninosNoAsignados[index];
                                      return ListTile(
                                        title: Text(nino['nombre_nino']),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                          onPressed: () {
                                             _asignarNino(_maestroSeleccionadoId!, nino['id_nino'], nino['nombre_nino']);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

import 'package:control_escolar_app/views/papas/alta_papas_screen.dart'; // Import AltaPapasScreen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerPapasScreen extends StatefulWidget {
  const VerPapasScreen({super.key});

  @override
  State<VerPapasScreen> createState() => _VerPapasScreenState();
}

class _VerPapasScreenState extends State<VerPapasScreen> {
  String _formatNombre(Map<String, dynamic>? data) {
    if (data == null) return 'No disponible';
    String nombres = data['nombres'] ?? '';
    String apellidos = data['apellidos'] ?? '';
    if (nombres.isEmpty && apellidos.isEmpty) return 'No especificado';
    return '$apellidos $nombres'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Familias (Papás)'),
        // Optional: Add a button to navigate to AltaPapasScreen
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dar de alta nueva familia',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AltaPapasScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('familias')
            .orderBy('fecha_alta_familia', descending: true) // Order by most recent
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay familias registradas.'));
          }

          final familiasDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: familiasDocs.length,
            itemBuilder: (context, index) {
              final docData = familiasDocs[index].data() as Map<String, dynamic>;
              final docId = familiasDocs[index].id;
              final padreData = docData['padre'] as Map<String, dynamic>?;
              final madreData = docData['madre'] as Map<String, dynamic>?;

              String nombrePadre = _formatNombre(padreData);
              String nombreMadre = _formatNombre(madreData);
              String currentStatus = docData['status'] ?? 'Activo'; // Default if null

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Familia (ID: ${docId.substring(0, 6)}...)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Padre: $nombrePadre'),
                      Text('Madre: $nombreMadre'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Status: '),
                              DropdownButton<String>(
                                value: currentStatus,
                                items: <String>['Activo', 'Desactivado']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != currentStatus) {
                                    FirebaseFirestore.instance
                                        .collection('familias')
                                        .doc(docId)
                                        .update({'status': newValue}).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Status de la familia $docId actualizado a $newValue')),
                                      );
                                    }).catchError((error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al actualizar status: $error')),
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Editar Familia',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AltaPapasScreen(familiaData: docData, documentId: docId),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              );
            },
          );
        },
      ),
    );
  }
}

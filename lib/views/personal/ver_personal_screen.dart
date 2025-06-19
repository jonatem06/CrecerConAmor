import 'package:control_escolar_app/views/personal/alta_personal_screen.dart'; // Import AltaPersonalScreen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerPersonalScreen extends StatefulWidget {
  const VerPersonalScreen({super.key});

  @override
  State<VerPersonalScreen> createState() => _VerPersonalScreenState();
}

class _VerPersonalScreenState extends State<VerPersonalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Personal'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('personal')
            .orderBy('apellido_paterno') // Order by last name
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay personal registrado.'));
          }

          final personalDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: personalDocs.length,
            itemBuilder: (context, index) {
              final data = personalDocs[index].data() as Map<String, dynamic>;
              final docId = personalDocs[index].id;
              String nombreCompleto =
                  "${data['apellido_paterno'] ?? ''} ${data['apellido_materno'] ?? ''} ${data['nombres'] ?? ''}";
              String currentStatus = data['status'] ?? 'Activo'; // Default to 'Activo' if null

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nombreCompleto.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AltaPersonalScreen(
                                    personalData: data,
                                    documentId: docId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text('Puesto: ${data['puesto'] ?? 'No especificado'}'),
                      Text('Fecha de Alta: ${data['fecha_alta'] ?? 'No especificada'}'),
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
                                    .collection('personal')
                                    .doc(docId)
                                    .update({'status': newValue}).then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Status de ${nombreCompleto.trim()} actualizado a $newValue')),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

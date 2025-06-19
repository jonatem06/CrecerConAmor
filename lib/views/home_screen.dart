import 'package:control_escolar_app/views/finanzas/control_gastos_screen.dart';
import 'package:control_escolar_app/views/papas/ver_papas_screen.dart';
import 'package:control_escolar_app/views/personal/asignar_maestros_screen.dart';
import 'package:control_escolar_app/views/reportes/ver_reportes_screen.dart'; // Import VerReportesScreen
import 'package:control_escolar_app/views/personal/ver_personal_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Inicio'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menú Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Personal'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerPersonalScreen()), // Changed to VerPersonalScreen
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Papás'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerPapasScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Finanzas'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ControlGastosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerReportesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind), // Example Icon
              title: const Text('Asignar Maestros'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AsignarMaestrosScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                print('Cerrar Sesión');
                Navigator.pop(context); // Close the drawer
                // Navigate back to LoginScreen - assuming LoginScreen is the root for logout
                // You might need to adjust this based on your actual navigation setup
                // For example, if LoginScreen is always the first route:
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                // Or if you have a specific route name for LoginScreen:
                // Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bienvenido'),
      ),
    );
  }
}

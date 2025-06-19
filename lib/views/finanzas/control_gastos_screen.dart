import 'package:control_escolar_app/views/finanzas/alta_gastos_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ControlGastosScreen extends StatefulWidget {
  const ControlGastosScreen({super.key});

  @override
  State<ControlGastosScreen> createState() => _ControlGastosScreenState();
}

class _ControlGastosScreenState extends State<ControlGastosScreen> {
  final _fechaDesdeController = TextEditingController();
  final _fechaHastaController = TextEditingController();
  DateTime? _fechaDesdeSeleccionada;
  DateTime? _fechaHastaSeleccionada;
  Stream<QuerySnapshot>? _gastosStream;
  String _appBarTitle = 'Control de Gastos (Último Mes)';

  @override
  void initState() {
    super.initState();
    _resetFechasYActualizarStream();
  }

  void _resetFechasYActualizarStream() {
    final now = DateTime.now();
    final unMesAtras = DateTime(now.year, now.month - 1, now.day);
    _fechaDesdeSeleccionada = unMesAtras;
    _fechaHastaSeleccionada = now;
    _fechaDesdeController.text = DateFormat('yyyy-MM-dd').format(unMesAtras);
    _fechaHastaController.text = DateFormat('yyyy-MM-dd').format(now);
    _actualizarStreamGastos(unMesAtras, now);
    setState(() {
       _appBarTitle = 'Control de Gastos (Último Mes)';
    });
  }

  void _actualizarStreamGastos([DateTime? desde, DateTime? hasta]) {
    String fechaDesdeStr;
    String fechaHastaStr;

    if (desde != null && hasta != null) {
      fechaDesdeStr = DateFormat('yyyy-MM-dd').format(desde);
      fechaHastaStr = DateFormat('yyyy-MM-dd').format(hasta);
       setState(() {
        _appBarTitle = 'Gastos: ${fechaDesdeStr} a ${fechaHastaStr}';
      });
    } else {
      // Default to last month
      final now = DateTime.now();
      final unMesAtras = DateTime(now.year, now.month - 1, now.day);
      fechaDesdeStr = DateFormat('yyyy-MM-dd').format(unMesAtras);
      fechaHastaStr = DateFormat('yyyy-MM-dd').format(now);
       setState(() {
         _appBarTitle = 'Control de Gastos (Último Mes)';
      });
    }

    Query query = FirebaseFirestore.instance.collection('gastos')
        .where('fecha_gasto', isGreaterThanOrEqualTo: fechaDesdeStr)
        .where('fecha_gasto', isLessThanOrEqualTo: fechaHastaStr)
        .orderBy('fecha_gasto', descending: true);

    setState(() {
      _gastosStream = query.snapshots();
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isFechaDesde) async {
    DateTime initial = DateTime.now();
    if (isFechaDesde && _fechaDesdeSeleccionada != null) initial = _fechaDesdeSeleccionada!;
    if (!isFechaDesde && _fechaHastaSeleccionada != null) initial = _fechaHastaSeleccionada!;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        controller.text = formattedDate;
        if (isFechaDesde) {
          _fechaDesdeSeleccionada = pickedDate;
        } else {
          _fechaHastaSeleccionada = pickedDate;
        }
      });
    }
  }

  @override
  void dispose() {
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    double totalGastos = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fechaDesdeController,
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _fechaDesdeController, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _fechaHastaController,
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _fechaHastaController, false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_fechaDesdeSeleccionada != null && _fechaHastaSeleccionada != null) {
                      if (_fechaDesdeSeleccionada!.isAfter(_fechaHastaSeleccionada!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La "Fecha Desde" no puede ser posterior a la "Fecha Hasta".')),
                        );
                        return;
                      }
                      _actualizarStreamGastos(_fechaDesdeSeleccionada, _fechaHastaSeleccionada);
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, seleccione ambas fechas.')),
                      );
                    }
                  },
                  child: const Text('Filtrar Gastos'),
                ),
                TextButton(
                  onPressed: _resetFechasYActualizarStream,
                  child: const Text('Mostrar Último Mes'),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _gastosStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay gastos registrados para el rango seleccionado.'));
                }

                final gastosDocs = snapshot.data!.docs;
                totalGastos = 0;
                for (var doc in gastosDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalGastos += (data['costo'] as num?)?.toDouble() ?? 0.0;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total de Gastos: ${numberFormat.format(totalGastos)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: gastosDocs.length,
                  itemBuilder: (context, index) {
                    final data = gastosDocs[index].data() as Map<String, dynamic>;
                    final costo = (data['costo'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(data['tipo_gasto'] ?? 'No especificado', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Fecha: ${data['fecha_gasto'] ?? 'N/A'}'),
                        trailing: Text(numberFormat.format(costo), style: const TextStyle(fontSize: 16, color: Colors.redAccent)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AltaGastosScreen()),
          );
        },
        tooltip: 'Registrar Nuevo Gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

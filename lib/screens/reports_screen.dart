import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../models/sede.dart';
import '../services/sede_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final SedeService _sedeService = SedeService();
  late TabController _tabController;
  String _selectedPeriod = 'today';
  String? _selectedSedeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.analytics)),
            Tab(text: 'Por Sede', icon: Icon(Icons.location_city)),
            Tab(text: 'Ganancias', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildSedeTab(),
                _buildEarningsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Text('Período: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Hoy')),
                DropdownMenuItem(value: 'week', child: Text('Esta Semana')),
                DropdownMenuItem(value: 'month', child: Text('Este Mes')),
                DropdownMenuItem(value: 'all', child: Text('Todo el Tiempo')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final services = snapshot.data?.docs ?? [];
        final stats = _calculateGeneralStats(services);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCard('Total de Servicios', stats['total'].toString(), Icons.work, Colors.blue),
              const SizedBox(height: 16),
              _buildStatsCard('Completados', stats['completed'].toString(), Icons.check_circle, Colors.green),
              const SizedBox(height: 16),
              _buildStatsCard('Pendientes', stats['pending'].toString(), Icons.pending, Colors.orange),
              const SizedBox(height: 16),
              _buildStatsCard('En Progreso', stats['inProgress'].toString(), Icons.build, Colors.amber),
              const SizedBox(height: 16),
              _buildStatsCard('Cancelados', stats['cancelled'].toString(), Icons.cancel, Colors.red),
              const SizedBox(height: 24),
              _buildServiceTypeChart(services),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSedeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<Sede>>(
            stream: _sedeService.getSedesActivas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final sedes = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                value: _selectedSedeId,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Sede',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todas las Sedes'),
                  ),
                  ...sedes.map((sede) => DropdownMenuItem<String>(
                    value: sede.id,
                    child: Text(sede.nombre),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSedeId = value;
                  });
                },
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getServicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final services = snapshot.data?.docs ?? [];
              return _buildSedeStats(services);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = snapshot.data?.docs ?? [];
        final earnings = _calculateEarnings(services);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCard(
                'Ganancias Totales',
                '\$${earnings['total'].toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Comisión Admin',
                '\$${earnings['admin'].toStringAsFixed(0)}',
                Icons.admin_panel_settings,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Comisión Técnicos',
                '\$${earnings['technicians'].toStringAsFixed(0)}',
                Icons.engineering,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Servicios Pagados',
                earnings['paid'].toString(),
                Icons.paid,
                Colors.green[700]!,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Servicios Pendientes de Pago',
                earnings['unpaid'].toString(),
                Icons.payment,
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeChart(List<QueryDocumentSnapshot> services) {
    final revisionCount = services.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['serviceType'] == 'revision';
    }).length;

    final completeCount = services.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['serviceType'] == 'complete';
    }).length;

    final undefinedCount = services.length - revisionCount - completeCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipos de Servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTypeRow('Revisiones', revisionCount, Colors.blue),
            _buildTypeRow('Servicios Completos', completeCount, Colors.green),
            _buildTypeRow('Sin Definir', undefinedCount, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSedeStats(List<QueryDocumentSnapshot> services) {
    return StreamBuilder<List<Sede>>(
      stream: _sedeService.getSedesActivas(),
      builder: (context, sedeSnapshot) {
        if (sedeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sedes = sedeSnapshot.data ?? [];
        final sedeStats = <String, Map<String, dynamic>>{};

        // Inicializar estadísticas para cada sede
        for (final sede in sedes) {
          sedeStats[sede.id] = {
            'name': sede.nombre,
            'total': 0,
            'completed': 0,
            'earnings': 0.0,
          };
        }

        // Calcular estadísticas por sede
        for (final doc in services) {
          final data = doc.data() as Map<String, dynamic>;
          final location = data['location'] as String? ?? '';
          
          // Buscar la sede basada en la ubicación
          for (final sede in sedes) {
            if (location.contains(sede.nombre)) {
              sedeStats[sede.id]!['total']++;
              if (data['status'] == 'completed') {
                sedeStats[sede.id]!['completed']++;
                sedeStats[sede.id]!['earnings'] += (data['finalPrice'] as num?)?.toDouble() ?? 0.0;
              }
              break;
            }
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sedeStats.length,
          itemBuilder: (context, index) {
            final sedeId = sedeStats.keys.elementAt(index);
            final stats = sedeStats[sedeId]!;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSedeStatItem(
                          'Total',
                          stats['total'].toString(),
                          Icons.work,
                          Colors.blue,
                        ),
                        _buildSedeStatItem(
                          'Completados',
                          stats['completed'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildSedeStatItem(
                          'Ganancias',
                          '\$${stats['earnings'].toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.orange,
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
    );
  }

  Widget _buildSedeStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getServicesStream() {
    Query query = FirebaseFirestore.instance.collection('services');

    // Filtrar por período
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        return query.snapshots();
    }

    return query
        .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .snapshots();
  }

  Map<String, int> _calculateGeneralStats(List<QueryDocumentSnapshot> services) {
    int total = services.length;
    int completed = 0;
    int pending = 0;
    int inProgress = 0;
    int cancelled = 0;

    for (final doc in services) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      switch (status) {
        case 'completed':
        case 'paid':
          completed++;
          break;
        case 'pending':
          pending++;
          break;
        case 'assigned':
        case 'onWay':
        case 'inProgress':
          inProgress++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'cancelled': cancelled,
    };
  }

  Map<String, dynamic> _calculateEarnings(List<QueryDocumentSnapshot> services) {
    double total = 0;
    double admin = 0;
    double technicians = 0;
    int paid = 0;
    int unpaid = 0;

    for (final doc in services) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      
      if (status == 'completed' || status == 'paid') {
        final finalPrice = (data['finalPrice'] as num?)?.toDouble() ?? 0.0;
        final adminCommission = (data['adminCommission'] as num?)?.toDouble() ?? 0.0;
        final technicianCommission = (data['technicianCommission'] as num?)?.toDouble() ?? 0.0;
        
        total += finalPrice;
        admin += adminCommission;
        technicians += technicianCommission;
        
        if (status == 'paid' || (data['isPaid'] as bool?) == true) {
          paid++;
        } else {
          unpaid++;
        }
      }
    }

    return {
      'total': total,
      'admin': admin,
      'technicians': technicians,
      'paid': paid,
      'unpaid': unpaid,
    };
  }
}

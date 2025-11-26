import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../models/sede.dart';
import '../services/sede_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  final SedeService _sedeService = SedeService();
  late TabController _tabController;
  String _selectedPeriod = 'today';

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
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Sedes', icon: Icon(Icons.location_city_outlined)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Período:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Resumen de Servicios'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                        'Total', stats['total'].toString(), Icons.work, AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard('Completados', stats['completed'].toString(),
                        Icons.check_circle, AppTheme.successText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard('Pendientes', stats['pending'].toString(),
                        Icons.pending, AppTheme.warningText),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard('En Progreso', stats['inProgress'].toString(),
                        Icons.build, Colors.amber[800]!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsCard('Cancelados', stats['cancelled'].toString(),
                  Icons.cancel, AppTheme.errorText),
              const SizedBox(height: 24),
              _buildSectionTitle('Distribución por Tipo'),
              const SizedBox(height: 16),
              _buildServiceTypeChart(services),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSedeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = snapshot.data?.docs ?? [];
        return _buildSedeStats(services);
      },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Resumen Financiero'),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Ganancias Totales',
                '\$${earnings['total'].toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
                isLarge: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Comisión Admin',
                      '\$${earnings['admin'].toStringAsFixed(0)}',
                      Icons.admin_panel_settings,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Comisión Técnicos',
                      '\$${earnings['technicians'].toStringAsFixed(0)}',
                      Icons.engineering,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Estado de Pagos'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Pagados',
                      earnings['paid'].toString(),
                      Icons.paid,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Pendientes',
                      earnings['unpaid'].toString(),
                      Icons.payment,
                      AppTheme.errorText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeRow('Revisiones', revisionCount, AppTheme.primaryBlue),
          const Divider(height: 24),
          _buildTypeRow('Servicios Completos', completeCount, AppTheme.successText),
          const Divider(height: 24),
          _buildTypeRow('Sin Definir', undefinedCount, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTypeRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
              if (data['status'] == 'completed' || data['status'] == 'paid') {
                sedeStats[sede.id]!['completed']++;
                sedeStats[sede.id]!['earnings'] +=
                    (data['finalPrice'] as num?)?.toDouble() ?? 0.0;
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

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_city, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        stats['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSedeStatItem(
                        'Total',
                        stats['total'].toString(),
                        Icons.work_outline,
                        Colors.blue,
                      ),
                      _buildSedeStatItem(
                        'Completados',
                        stats['completed'].toString(),
                        Icons.check_circle_outline,
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
            );
          },
        );
      },
    );
  }

  Widget _buildSedeStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);
        break;
      default: // 'all'
        return query.orderBy('createdAt', descending: true).snapshots();
    }

    // Firestore queries require ordering by the same field that is used for range filters
    return query
        .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('createdAt', isLessThan: endDate.toIso8601String())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Map<String, int> _calculateGeneralStats(
      List<QueryDocumentSnapshot> services) {
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

  Map<String, dynamic> _calculateEarnings(
      List<QueryDocumentSnapshot> services) {
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
        final adminCommission =
            (data['adminCommission'] as num?)?.toDouble() ?? 0.0;
        final technicianCommission =
            (data['technicianCommission'] as num?)?.toDouble() ?? 0.0;

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

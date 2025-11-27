import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../models/sede.dart';
import '../services/sede_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Reportes y Estadísticas',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172B4D)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF0052CC),
              unselectedLabelColor: const Color(0xFF5E6C84),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'General', icon: Icon(Icons.analytics_outlined, size: 20)),
                Tab(text: 'Sedes', icon: Icon(Icons.location_city_outlined, size: 20)),
                Tab(text: 'Finanzas', icon: Icon(Icons.attach_money, size: 20)),
              ],
            ),
          ),
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
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0052CC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, color: Color(0xFF0052CC), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Período:',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5E6C84)),
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  dropdownColor: Colors.white,
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final services = snapshot.data?.docs ?? [];
        final stats = _calculateGeneralStats(services);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Resumen de Servicios'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                        'Total', stats['total'].toString(), Icons.work_outline, const Color(0xFF0052CC)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard('Completados', stats['completed'].toString(),
                        Icons.check_circle_outline, const Color(0xFF36B37E)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard('Pendientes', stats['pending'].toString(),
                        Icons.pending_outlined, const Color(0xFFFFAB00)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard('En Progreso', stats['inProgress'].toString(),
                        Icons.build_circle_outlined, const Color(0xFF6554C0)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsCard('Cancelados', stats['cancelled'].toString(),
                  Icons.cancel_outlined, const Color(0xFFFF5630)),
              const SizedBox(height: 30),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
        }

        final services = snapshot.data?.docs ?? [];
        final earnings = _calculateEarnings(services);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Resumen Financiero'),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Ganancias Totales',
                formatCurrency(earnings['total']),
                Icons.attach_money,
                const Color(0xFF36B37E),
                isLarge: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Comisión Admin',
                      formatCurrency(earnings['admin']),
                      Icons.admin_panel_settings_outlined,
                      const Color(0xFF0052CC),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Comisión Técnicos',
                      formatCurrency(earnings['technicians']),
                      Icons.engineering_outlined,
                      const Color(0xFFFFAB00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Estado de Pagos'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Pagados',
                      earnings['paid'].toString(),
                      Icons.paid_outlined,
                      const Color(0xFF36B37E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Pendientes',
                      earnings['unpaid'].toString(),
                      Icons.payment_outlined,
                      const Color(0xFFFF5630),
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
        color: Color(0xFF172B4D),
      ),
    );
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5E6C84),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeRow('Revisiones', revisionCount, const Color(0xFF0052CC)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEBECF0)),
          ),
          _buildTypeRow('Servicios Completos', completeCount, const Color(0xFF36B37E)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEBECF0)),
          ),
          _buildTypeRow('Sin Definir', undefinedCount, const Color(0xFF5E6C84)),
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
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF172B4D),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
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
          padding: const EdgeInsets.all(20),
          itemCount: sedeStats.length,
          itemBuilder: (context, index) {
            final sedeId = sedeStats.keys.elementAt(index);
            final stats = sedeStats[sedeId]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF172B4D).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_city, color: Color(0xFF0052CC)),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        stats['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSedeStatItem(
                        'Total',
                        stats['total'].toString(),
                        Icons.work_outline,
                        const Color(0xFF0052CC),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFEBECF0)),
                      _buildSedeStatItem(
                        'Completados',
                        stats['completed'].toString(),
                        Icons.check_circle_outline,
                        const Color(0xFF36B37E),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFEBECF0)),
                      _buildSedeStatItem(
                        'Ganancias',
                        '\$${stats['earnings'].toStringAsFixed(0)}',
                        Icons.attach_money,
                        const Color(0xFFFFAB00),
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
            color: Color(0xFF172B4D),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5E6C84),
            fontWeight: FontWeight.w500,
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

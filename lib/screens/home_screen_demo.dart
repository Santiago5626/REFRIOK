import 'package:flutter/material.dart';
import '../models/service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userRole;

  const HomeScreen({super.key, required this.onLogout, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Datos de ejemplo
  final List<Service> _availableServices = [
    Service(
      id: '1',
      title: 'Reparación de Aire Acondicionado',
      description: 'Cliente reporta que el aire no enfría lo suficiente',
      location: 'Calle Principal #123',
      clientName: 'Juan Pérez',
      clientPhone: '+57 300 123 4567',
      createdAt: DateTime.now(),
      scheduledFor: DateTime.now().add(const Duration(hours: 2)),
      basePrice: 150000,
      status: ServiceStatus.pending,
    ),
    Service(
      id: '2',
      title: 'Mantenimiento de Calefacción',
      description: 'Mantenimiento preventivo programado',
      location: 'Avenida Central #456',
      clientName: 'María García',
      clientPhone: '+57 301 987 6543',
      createdAt: DateTime.now(),
      scheduledFor: DateTime.now().add(const Duration(hours: 4)),
      basePrice: 120000,
      status: ServiceStatus.pending,
    ),
  ];

  final List<Service> _myServices = [];
  final List<Service> _completedServices = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userRole == 'admin' ? 'Panel Admin' : 'Tech Service'} - Demo'),
        backgroundColor: widget.userRole == 'admin' ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.userRole == 'admin' ? _buildAdminTabs() : _buildTechnicianTabs(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: widget.userRole == 'admin' ? _buildAdminNavItems() : _buildTechnicianNavItems(),
      ),
    );
  }

  List<Widget> _buildAdminTabs() {
    return [
      _buildAllServicesTab(),
      _buildTechniciansTab(),
      _buildReportsTab(),
      _buildAdminProfileTab(),
    ];
  }

  Widget _buildAllServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableServices.length + _myServices.length + _completedServices.length,
      itemBuilder: (context, index) {
        Service service;
        if (index < _availableServices.length) {
          service = _availableServices[index];
        } else if (index < _availableServices.length + _myServices.length) {
          service = _myServices[index - _availableServices.length];
        } else {
          service = _completedServices[index - _availableServices.length - _myServices.length];
        }
        return _buildServiceCard(service, false);
      },
    );
  }

  Widget _buildTechniciansTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Lista de Técnicos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Técnico Demo'),
            subtitle: Text('ID: TECH-001'),
            trailing: Chip(
              label: Text('Activo'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Reportes y Estadísticas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatCard('Total Servicios', '${_availableServices.length + _myServices.length + _completedServices.length}'),
          _buildStatCard('Servicios Pendientes', '${_availableServices.length}'),
          _buildStatCard('Servicios en Progreso', '${_myServices.length}'),
          _buildStatCard('Servicios Completados', '${_completedServices.length}'),
        ],
      ),
    );
  }

  Widget _buildAdminProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Administrador',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ID: ADMIN-001',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatCard('Técnicos Activos', '1'),
          _buildStatCard('Servicios este Mes', '${_availableServices.length + _myServices.length + _completedServices.length}'),
          _buildStatCard('Ingresos Totales', '\$${(_completedServices.length * 150000).toString()}'),
        ],
      ),
    );
  }

  List<Widget> _buildTechnicianTabs() {
    return [
      _buildServicesTab(),
      _buildMyServicesTab(),
      _buildHistoryTab(),
      _buildProfileTab(),
    ];
  }

  List<BottomNavigationBarItem> _buildAdminNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Técnicos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Reportes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildTechnicianNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.work),
        label: 'Servicios',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'Mis Servicios',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Historial',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }

  Widget _buildServicesTab() {
    if (_availableServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay servicios disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableServices.length,
      itemBuilder: (context, index) {
        Service service = _availableServices[index];
        return _buildServiceCard(service, true);
      },
    );
  }

  Widget _buildMyServicesTab() {
    if (_myServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tienes servicios asignados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myServices.length,
      itemBuilder: (context, index) {
        Service service = _myServices[index];
        return _buildServiceCard(service, false);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_completedServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay servicios completados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedServices.length,
      itemBuilder: (context, index) {
        Service service = _completedServices[index];
        return _buildServiceCard(service, false);
      },
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Técnico Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ID: TECH-001',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatCard('Servicios Completados', '0'),
          _buildStatCard('Ganancias Totales', '\$0'),
          _buildStatCard('Calificación Promedio', '5.0'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service, bool isAvailable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(service.status),
          child: Icon(
            _getStatusIcon(service.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          service.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.location),
            const SizedBox(height: 4),
            Text(
              'Programado: ${_formatDateTime(service.scheduledFor)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 4),
              Text(
                'Estado: ${_getStatusText(service.status)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(service.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: isAvailable
            ? ElevatedButton(
                onPressed: () => _acceptService(service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aceptar'),
              )
            : _buildStatusChip(service.status),
      ),
    );
  }

  Widget _buildStatusChip(ServiceStatus status) {
    return Chip(
      label: Text(
        _getStatusText(status),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: _getStatusColor(status),
    );
  }

  void _acceptService(Service service) {
    setState(() {
      _availableServices.remove(service);
      final updatedService = Service(
        id: service.id,
        title: service.title,
        description: service.description,
        location: service.location,
        clientName: service.clientName,
        clientPhone: service.clientPhone,
        createdAt: service.createdAt,
        scheduledFor: service.scheduledFor,
        basePrice: service.basePrice,
        status: ServiceStatus.assigned,
        assignedTechnicianId: 'TECH-001',
      );
      _myServices.add(updatedService);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Servicio aceptado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange;
      case ServiceStatus.assigned:
        return Colors.blue;
      case ServiceStatus.completed:
        return Colors.green;
      case ServiceStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Icons.pending;
      case ServiceStatus.assigned:
        return Icons.assignment;
      case ServiceStatus.completed:
        return Icons.check;
      case ServiceStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'Pendiente';
      case ServiceStatus.assigned:
        return 'Asignado';
      case ServiceStatus.completed:
        return 'Completado';
      case ServiceStatus.cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

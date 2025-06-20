import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/service_management_service.dart';
import '../services/notification_service.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ServiceManagementService _serviceService = ServiceManagementService();
  final NotificationService _notificationService = NotificationService();
  app_user.User? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    app_user.User? user = await _authService.getCurrentUserData();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser!.isBlocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cuenta Bloqueada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tu cuenta está bloqueada por falta de pago. '
                  'Realiza el pago correspondiente y contacta al administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _signOut,
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${_currentUser!.name}'),
        actions: [
          // Botón de notificaciones con badge
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(_currentUser!.id),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Only show the index test button for admin users
          if (_currentUser!.isAdmin)
            IconButton(
              icon: const Icon(Icons.build_circle),
              tooltip: 'Test Índices Firestore',
              onPressed: () => Navigator.pushNamed(context, '/index-test'),
            ),
          // Solo mostrar botón de logout para administradores
          if (_currentUser!.isAdmin)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _currentUser!.isAdmin
            ? [
                _buildServicesTab(),
                ProfileScreen(initialUser: _currentUser!, onSignOut: _signOut),
              ]
            : [
                _buildServicesTab(),
                _buildMyServicesTab(),
                _buildHistoryTab(),
                ProfileScreen(initialUser: _currentUser!, onSignOut: _signOut),
              ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildServicesTab() {
    // Los administradores ven todos los servicios, los técnicos solo los disponibles
    Stream<List<Service>> servicesStream = _currentUser!.isAdmin 
        ? _serviceService.getAllServices()
        : _serviceService.getAvailableServices();

    return StreamBuilder<List<Service>>(
      stream: servicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        List<Service> services = snapshot.data ?? [];

        if (services.isEmpty) {
          return Center(
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
                  _currentUser!.isAdmin 
                      ? 'No hay servicios registrados'
                      : 'No hay servicios disponibles',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              Service service = services[index];
              // Para admin: isAvailable = true solo si el servicio está pendiente
              // Para técnicos: siempre true porque solo ven servicios disponibles
              bool isAvailable = _currentUser!.isAdmin 
                  ? service.status == ServiceStatus.pending
                  : true;
              return _buildServiceCard(service, isAvailable);
            },
          ),
        );
      },
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
            ? const Icon(Icons.arrow_forward_ios)
            : _buildStatusChip(service.status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                service: service,
                isAvailable: isAvailable,
              ),
            ),
          );
        },
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

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange;
      case ServiceStatus.assigned:
        return Colors.blue;
      case ServiceStatus.onWay:
        return Colors.purple;
      case ServiceStatus.inProgress:
        return Colors.amber;
      case ServiceStatus.completed:
        return Colors.green;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Icons.pending;
      case ServiceStatus.assigned:
        return Icons.assignment;
      case ServiceStatus.onWay:
        return Icons.directions_car;
      case ServiceStatus.inProgress:
        return Icons.build;
      case ServiceStatus.completed:
        return Icons.check;
      case ServiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'Pendiente';
      case ServiceStatus.assigned:
        return 'Asignado';
      case ServiceStatus.onWay:
        return 'En Camino';
      case ServiceStatus.inProgress:
        return 'En Progreso';
      case ServiceStatus.completed:
        return 'Completado';
      case ServiceStatus.cancelled:
        return 'Cancelado';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMyServicesTab() {
    return StreamBuilder<List<Service>>(
      stream: _serviceService.getTechnicianServices(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        List<Service> services = snapshot.data ?? [];

        if (services.isEmpty) {
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
          itemCount: services.length,
          itemBuilder: (context, index) {
            Service service = services[index];
            return _buildServiceCard(service, false);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Service>>(
      stream: _serviceService.getCompletedServices(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        List<Service> services = snapshot.data ?? [];

        if (services.isEmpty) {
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
          itemCount: services.length,
          itemBuilder: (context, index) {
            Service service = services[index];
            return _buildCompletedServiceCard(service);
          },
        );
      },
    );
  }

  Widget _buildCompletedServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
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
              'Completado: ${service.completedAt != null ? _formatDateTime(service.completedAt!) : 'N/A'}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Tipo: ${service.serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ganancia: \$${service.technicianCommission.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    if (_currentUser!.isAdmin) {
      // Navegación para administradores (2 pestañas)
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      );
    } else {
      // Navegación para técnicos (4 pestañas)
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
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
        ],
      );
    }
  }
}

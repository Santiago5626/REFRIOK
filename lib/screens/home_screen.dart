import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/service_management_service.dart';
import '../services/notification_service.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import '../utils/dialog_utils.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'add_service_screen.dart';
import 'reports_screen.dart';
import 'admin/payment_management_screen.dart';
import 'admin/admin_management_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/service_card.dart';

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
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Guardar token FCM al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveFcmToken();
    });
  }

  Future<void> _saveFcmToken() async {
    final user = await _authService.getCurrentUserData();
    if (user != null) {
      await _notificationService.saveTokenToUser(user.id);
    }
  }

  Future<void> _loadCurrentUser() async {
    app_user.User? user = await _authService.getCurrentUserData();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _signOut() async {
    // Mostrar diálogo de confirmación
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorText,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, proceder con el cierre de sesión
    if (shouldLogout == true) {
      try {
        await _authService.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        showAnimatedDialog(context, DialogType.error, e.toString());
      }
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
              Icon(
                Icons.block,
                size: 100,
                color: AppTheme.errorText,
              ),
              const SizedBox(height: 16),
              Text(
                'Cuenta Bloqueada',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.errorText,
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
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorText),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 85,
        title: Row(
          children: [
            // Logo de la empresa
            Container(
              height: 60,
              width: 60,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentUser!.isAdmin ? 'Administrador' : 'Técnico',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E6C84),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentUser!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón de notificaciones con badge
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(_currentUser!.id),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF172B4D)),
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
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5630),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
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
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _currentUser!.isAdmin
            ? [
                _buildAdminServicesTab(),
                _buildMyServicesTab(), // Nueva pestaña para servicios del admin
                _buildPaymentsTab(),
                const AdminManagementScreen(),
                ProfileScreen(initialUser: _currentUser!, onSignOut: _signOut),
              ]
            : [
                _buildMyServicesTab(),
                _buildHistoryTab(),
                ProfileScreen(initialUser: _currentUser!, onSignOut: _signOut),
              ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAdminServicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddServiceScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Servicio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Reportes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryBlue, // Header background color
                                  onPrimary: Colors.white, // Header text color
                                  onSurface: AppTheme.textPrimary, // Body text color
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryBlue, // Button text color
                                  ),
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor: AppTheme.primaryBlue,
                                  headerForegroundColor: Colors.white,
                                  confirmButtonStyle: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  cancelButtonStyle: TextButton.styleFrom(
                                    foregroundColor: AppTheme.textSecondary,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_today, 
                        color: _selectedDate != null ? AppTheme.primaryBlue : Colors.grey),
                      label: Text(
                        _selectedDate == null 
                            ? 'Filtrar por fecha' 
                            : 'Fecha: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate != null ? AppTheme.primaryBlue : Colors.grey[700],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _selectedDate != null ? AppTheme.primaryBlue : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      tooltip: 'Limpiar filtro',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Service>>(
            stream: _serviceService.getAllServices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<Service> services = snapshot.data ?? [];
              
              // Aplicar filtro de fecha si existe
              if (_selectedDate != null) {
                services = services.where((s) {
                  return s.scheduledFor.year == _selectedDate!.year &&
                         s.scheduledFor.month == _selectedDate!.month &&
                         s.scheduledFor.day == _selectedDate!.day;
                }).toList();
              }

              if (services.isEmpty) {
                return _buildEmptyState(
                  'No hay servicios registrados',
                  'Crea un nuevo servicio para comenzar',
                  Icons.post_add_rounded,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    Service service = services[index];
                    return ServiceCard(
                      service: service,
                      isAvailable: service.status == ServiceStatus.pending,
                      currentUser: _currentUser!,
                      onAssign: _showAssignDialog,
                      onDelete: _showDeleteConfirmation,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    return const PaymentManagementScreen();
  }

  Widget _buildMyServicesTab() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: StreamBuilder<List<Service>>(
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
            return _buildEmptyState(
              'No tienes servicios asignados',
              'Los nuevos servicios aparecerán aquí',
              Icons.assignment_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: services.length,
              itemBuilder: (context, index) {
                Service service = services[index];
                return ServiceCard(
                  service: service,
                  isAvailable: false,
                  currentUser: _currentUser!,
                  onAssign: (_) {},
                  onDelete: (_) {},
                  showStatusInBottom: false, // No mostrar estado duplicado
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: StreamBuilder<List<Service>>(
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
            return _buildEmptyState(
              'No hay servicios completados',
              'Tu historial aparecerá aquí',
              Icons.history_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: services.length,
              itemBuilder: (context, index) {
                Service service = services[index];
                return ServiceCard(
                  service: service,
                  isAvailable: false,
                  currentUser: _currentUser!,
                  onAssign: (_) {},
                  onDelete: (_) {},
                  showStatusInBottom: false, // Nueva prop para no mostrar estado duplicado
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0052CC).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: const Color(0xFF0052CC).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog(Service service) async {
    final BuildContext currentContext = context;
    List<app_user.User> allUsers = await _authService.getUsers();

    // Incluir tanto técnicos como administradores
    List<app_user.User> availableUsers = allUsers
        .where((user) =>
            (service.sedeId == null || user.sedeId == service.sedeId || user.isAdmin))
        .toList();

    app_user.User? selectedTechnician = await showDialog<app_user.User>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Asignar Usuario'),
          content: SizedBox(
            width: double.maxFinite,
            child: availableUsers.isEmpty
                ? const Text('No hay usuarios disponibles para esta sede.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin 
                              ? const Color(0xFF0052CC).withValues(alpha: 0.1)
                              : AppTheme.primaryBlue.withValues(alpha: 0.1),
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              color: user.isAdmin 
                                  ? const Color(0xFF0052CC)
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(
                          user.isAdmin ? 'Administrador' : 'Técnico',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isAdmin 
                                ? const Color(0xFF0052CC)
                                : const Color(0xFF5E6C84),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop(user);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );

    if (selectedTechnician != null) {
      try {
        await _serviceService.assignService(service.id, selectedTechnician.id);
        if (!mounted) return;
        showAnimatedDialog(currentContext, DialogType.success, 'Servicio asignado correctamente');
      } catch (e) {
        if (!mounted) return;
        showAnimatedDialog(currentContext, DialogType.error, e.toString());
      }
    }
  }

  Future<void> _showDeleteConfirmation(Service service) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Servicio'),
          content: Text('¿Estás seguro de que deseas eliminar el servicio "${service.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorText,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        bool success = await _serviceService.deleteService(service.id);
        if (!mounted) return;
        
        if (success) {
          showAnimatedDialog(context, DialogType.success, 'Servicio eliminado exitosamente');
        } else {
          showAnimatedDialog(context, DialogType.error, 'Error al eliminar el servicio');
        }
      } catch (e) {
        if (!mounted) return;
        showAnimatedDialog(context, DialogType.error, e.toString());
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBottomNavigationBar() {
    final items = _currentUser!.isAdmin
        ? [
            _NavItem(Icons.grid_view_rounded, Icons.grid_view, 'Inicio'),
            _NavItem(Icons.assignment_outlined, Icons.assignment, 'Mis Servicios'),
            _NavItem(Icons.payments_outlined, Icons.payments_rounded, 'Pagos'),
            _NavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Admin'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
          ]
        : [
            _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
            _NavItem(Icons.history_outlined, Icons.history_rounded, 'Historial'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                items[index].icon,
                items[index].activeIcon,
                items[index].label,
                index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF0052CC).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected 
                    ? const Color(0xFF0052CC)
                    : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF0052CC)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem(this.icon, this.activeIcon, this.label);
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service_management_service.dart';
import '../services/auth_service.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import '../screens/login_screen.dart';
import 'edit_service_screen.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildServicesTab(),
          _buildCreateServiceTab(),
          _buildUsersTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Crear Servicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return StreamBuilder<List<Service>>(
      stream: _serviceService.getAllServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Service> services = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            Service service = services[index];
            return _buildServiceCard(service);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
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
            Text('Cliente: ${service.clientName}'),
            Text('Estado: ${_getStatusText(service.status)}'),
            if (service.assignedTechnicianId != null)
              FutureBuilder<app_user.User?>(
                future: _authService.getUserById(service.assignedTechnicianId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('Técnico: ${snapshot.data!.name}');
                  }
                  return Text('Técnico: ${service.assignedTechnicianId}');
                },
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (service.status == ServiceStatus.pending)
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Asignar a Técnico', style: TextStyle(color: Colors.green)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAssignTechnicianDialog(service);
                  },
                ),
              ),
            if (service.status != ServiceStatus.completed)
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Editar', style: TextStyle(color: Colors.blue)),
                  onTap: () async {
                    Navigator.pop(context);
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditServiceScreen(service: service),
                      ),
                    );
                    
                    if (updated == true) {
                      // El servicio fue actualizado, el StreamBuilder se actualizará automáticamente
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Servicio actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
            if (service.status == ServiceStatus.completed)
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.blue),
                  title: const Text('Descargar Factura', style: TextStyle(color: Colors.blue)),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadInvoice(service);
                  },
                ),
              ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteServiceConfirmation(service);
                },
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción: ${service.description}'),
                const SizedBox(height: 8),
                Text('Ubicación: ${service.location}'),
                const SizedBox(height: 8),
                Text('Teléfono: ${service.clientPhone}'),
                const SizedBox(height: 8),
                Text('Precio base: \$${service.basePrice.toStringAsFixed(0)}'),
                if (service.serviceType != null) ...[
                  const SizedBox(height: 8),
                  Text('Tipo: ${service.serviceType == ServiceType.revision ? 'Revisión' : 'Completo'}'),
                  Text('Precio final: \$${service.finalPrice.toStringAsFixed(0)}'),
                  Text('Comisión admin: \$${service.adminCommission.toStringAsFixed(0)}'),
                ],
                const SizedBox(height: 8),
                Text('Programado: ${_formatDateTime(service.scheduledFor)}'),
                if (service.completedAt != null)
                  Text('Completado: ${_formatDateTime(service.completedAt!)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateServiceTab() {
    return const CreateServiceForm();
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<app_user.User>>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<app_user.User> users = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Crear Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin ? Colors.blue : Colors.blue,
                          child: Icon(
                            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text(
                              user.isBlocked ? 'Bloqueado' : 'Activo',
                              style: TextStyle(
                                color: user.isBlocked ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(Icons.password),
                                title: const Text('Restablecer Contraseña'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _resetPassword(user.email);
                                },
                              ),
                            ),
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(user.isBlocked ? Icons.lock_open : Icons.lock),
                                title: Text(user.isBlocked ? 'Desbloquear' : 'Bloquear'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _toggleUserStatus(user.id, !user.isBlocked);
                                },
                              ),
                            ),
                            if (!user.isAdmin)
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirmation(context, user);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<List<app_user.User>> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_user.User.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isAdmin = false;

    // Mostrar directamente el formulario de creación de usuario
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Crear Usuario'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Campo requerido';
                      }
                      if (value != passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Es administrador'),
                    value: isAdmin,
                    onChanged: (value) {
                      setState(() {
                        isAdmin = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    final userId = await _authService.createUser(
                      email: emailController.text,
                      password: passwordController.text,
                      name: nameController.text,
                      isAdmin: isAdmin,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (userId != null) {
                      // Cambiar a la pestaña de usuarios
                      setState(() {
                        _selectedIndex = 2; // Índice de la pestaña de usuarios
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al crear usuario'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetPassword(String email) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: $email'),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo requerido';
                  }
                  if (value!.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo requerido';
                  }
                  if (value != newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                
                final success = await _authService.changePassword(
                  email,
                  newPasswordController.text,
                );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Contraseña cambiada exitosamente'
                          : 'Error al cambiar la contraseña',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(String userId, bool isBlocked) async {
    final success = await _authService.toggleUserStatus(userId, isBlocked);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? isBlocked
                  ? 'Usuario bloqueado exitosamente'
                  : 'Usuario desbloqueado exitosamente'
              : 'Error al cambiar el estado del usuario',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, app_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar al usuario ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Guardar referencia al contexto antes de cerrar el diálogo
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await _authService.deleteUser(user.id);
              
              // Usar la referencia guardada en lugar del contexto
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Usuario eliminado exitosamente'
                        : 'Error al eliminar usuario',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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

  // Descargar factura para un servicio completado
  void _downloadInvoice(Service service) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando factura...'),
            ],
          ),
        ),
      );

      // Generar la factura
      await _serviceService.previewInvoice(service.id, context);

      // Cerrar el indicador de carga
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura generada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar el indicador de carga si está abierto
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar factura: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignTechnicianDialog(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Técnico'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<app_user.User>>(
            stream: _authService.getTechnicians(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              List<app_user.User> technicians = snapshot.data ?? [];
              
              if (technicians.isEmpty) {
                return const Text('No hay técnicos disponibles');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  final technician = technicians[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: technician.isBlocked ? Colors.red : Colors.green,
                      child: Icon(
                        technician.isBlocked ? Icons.block : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(technician.name),
                    subtitle: Text(
                      technician.isBlocked ? 'Bloqueado' : 'Disponible',
                      style: TextStyle(
                        color: technician.isBlocked ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    enabled: !technician.isBlocked,
                    onTap: technician.isBlocked ? null : () async {
                      Navigator.pop(context);
                      
                      final success = await _serviceService.assignTechnician(
                        service.id,
                        technician.id,
                      );
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Servicio asignado a ${technician.name}'
                                : 'Error al asignar el servicio',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteServiceConfirmation(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar el servicio "${service.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _serviceService.deleteService(service.id);
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Servicio eliminado exitosamente'
                        : 'Error al eliminar servicio',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class CreateServiceForm extends StatefulWidget {
  const CreateServiceForm({super.key});

  @override
  State<CreateServiceForm> createState() => _CreateServiceFormState();
}

class _CreateServiceFormState extends State<CreateServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressObservationsController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _basePriceController = TextEditingController();
  final ServiceManagementService _serviceService = ServiceManagementService();
  
  final List<String> _availableCities = [
    'Pereira',
    'Dos Quebradas',
    'Valledupar',
    'Santa Marta'
  ];
  String? _selectedCity;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _addressObservationsController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _createService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final scheduledDateTime = DateTime.now();

      // Usar precio por defecto si no se especifica
      double basePrice = 30000.0; // Precio por defecto
      if (_basePriceController.text.isNotEmpty) {
        basePrice = double.parse(_basePriceController.text);
      }

      // Construir la ubicación completa
      String fullLocation = '';
      if (_selectedCity != null) {
        fullLocation = _selectedCity!;
        if (_addressController.text.isNotEmpty) {
          fullLocation += ', ${_addressController.text}';
        }
        if (_addressObservationsController.text.isNotEmpty) {
          fullLocation += ' - ${_addressObservationsController.text}';
        }
      }

      String? serviceId = await _serviceService.createService(
        title: _titleController.text,
        description: _descriptionController.text,
        location: fullLocation,
        clientName: _clientNameController.text,
        clientPhone: _clientPhoneController.text,
        scheduledFor: scheduledDateTime,
        basePrice: basePrice,
      );

      setState(() {
        _isLoading = false;
      });

      if (serviceId != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el servicio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedCity = null;
    _addressController.clear();
    _addressObservationsController.clear();
    _clientNameController.clear();
    _clientPhoneController.clear();
    _basePriceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crear Nuevo Servicio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Servicio',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                border: OutlineInputBorder(),
              ),
              items: _availableCities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione una ciudad';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
                helperText: 'Ingrese la dirección específica (calle, carrera, número)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressObservationsController,
              decoration: const InputDecoration(
                labelText: 'Observaciones de la Dirección (Opcional)',
                border: OutlineInputBorder(),
                helperText: 'Detalles adicionales como apartamento, piso, referencias, etc.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Cliente',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre del cliente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono del Cliente',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el teléfono';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basePriceController,
              decoration: const InputDecoration(
                labelText: 'Precio Base (Opcional)',
                border: OutlineInputBorder(),
                prefixText: '\$',
                helperText: 'Si no se especifica, se usará \$30.000 por defecto',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un precio válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createService,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Crear Servicio',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

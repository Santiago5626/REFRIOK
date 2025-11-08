import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;
import '../models/sede.dart';
import '../services/auth_service.dart';
import '../services/sede_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final AuthService _authService = AuthService();
  final SedeService _sedeService = SedeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showCreateUserDialog(context),
            icon: const Icon(Icons.person_add),
            tooltip: 'Agregar Usuario',
          ),
        ],
      ),
      body: StreamBuilder<List<app_user.User>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<app_user.User> users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserCard(app_user.User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: user.isAdmin ? Colors.blue : Colors.green,
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isAdmin ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isAdmin ? 'Administrador' : 'Técnico',
                              style: TextStyle(
                                fontSize: 12,
                                color: user.isAdmin ? Colors.blue : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isBlocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isBlocked ? 'Bloqueado' : 'Activo',
                              style: TextStyle(
                                fontSize: 12,
                                color: user.isBlocked ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.password, color: Colors.blue),
                        title: const Text('Restablecer Contraseña'),
                        onTap: () {
                          Navigator.pop(context);
                          _resetPassword(user.email);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(
                          user.isBlocked ? Icons.lock_open : Icons.lock,
                          color: user.isBlocked ? Colors.green : Colors.orange,
                        ),
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
              ],
            ),
            if (!user.isAdmin) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Servicios completados: ${user.completedServices}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Ganancias totales: \$${user.totalEarnings.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Stream<List<app_user.User>> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
          // Crear un mapa para evitar duplicados por email
          Map<String, app_user.User> uniqueUsers = {};
          
          for (var doc in snapshot.docs) {
            final userData = {
              'id': doc.id,
              ...doc.data(),
            };
            final user = app_user.User.fromMap(userData);
            
            // Usar email como clave única para evitar duplicados
            uniqueUsers[user.email] = user;
          }
          
          // Convertir a lista y ordenar (admins primero)
          final usersList = uniqueUsers.values.toList();
          usersList.sort((a, b) {
            if (a.isAdmin && !b.isAdmin) return -1;
            if (!a.isAdmin && b.isAdmin) return 1;
            return a.name.compareTo(b.name);
          });
          
          return usersList;
        });
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isAdmin = false;
    String? selectedSedeId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
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
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Campo requerido';
                      }
                      if (value!.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Es administrador'),
                    subtitle: const Text('Los administradores tienen acceso completo'),
                    value: isAdmin,
                    onChanged: (value) {
                      setState(() {
                        isAdmin = value ?? false;
                        if (isAdmin) {
                          selectedSedeId = null; // Los admins no tienen sede
                        }
                      });
                    },
                  ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 16),
                    StreamBuilder<List<Sede>>(
                      stream: _sedeService.getSedesActivas(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error al cargar sedes: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final sedes = snapshot.data ?? [];
                        if (sedes.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'No hay sedes disponibles. Cree una sede primero.',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedSedeId,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Sede',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                            helperText: 'Sede donde trabajará el técnico',
                          ),
                          items: sedes.map((sede) {
                            return DropdownMenuItem<String>(
                              value: sede.id,
                              child: Text(sede.nombre),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSedeId = newValue;
                            });
                          },
                          validator: (value) {
                            if (!isAdmin && (value == null || value.isEmpty)) {
                              return 'Debe seleccionar una sede para el técnico';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                      sedeId: isAdmin ? null : selectedSedeId,
                    );
                    
                    Navigator.pop(dialogContext); // Close the dialog

                    if (userId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Usuario creado exitosamente'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Error al crear usuario'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.toString())),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
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
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                ),
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
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          success
                              ? 'Contraseña cambiada exitosamente'
                              : 'Error al cambiar la contraseña',
                        ),
                      ],
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
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              success
                  ? isBlocked
                      ? 'Usuario bloqueado exitosamente'
                      : 'Usuario desbloqueado exitosamente'
                  : 'Error al cambiar el estado del usuario',
            ),
          ],
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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await _authService.deleteUser(user.id);
              
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        success
                            ? 'Usuario eliminado exitosamente'
                            : 'Error al eliminar usuario',
                      ),
                    ],
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

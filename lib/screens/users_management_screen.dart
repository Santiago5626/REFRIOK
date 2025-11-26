import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;
import '../models/sede.dart';
import '../services/auth_service.dart';
import '../services/sede_service.dart';
import '../utils/dialog_utils.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
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
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        actions: [
          IconButton(
            onPressed: () => _showCreateUserDialog(context),
            icon: const Icon(Icons.person_add_outlined, color: Color(0xFF0052CC)),
            tooltip: 'Agregar Usuario',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF4F5F7),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<app_user.User>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<app_user.User> users = snapshot.data ?? [];

          if (users.isEmpty) {
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
                      Icons.people_outline,
                      size: 64,
                      color: const Color(0xFF0052CC).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No hay usuarios registrados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0052CC),
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
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
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserCard(app_user.User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: user.isAdmin 
                        ? const Color(0xFF0052CC).withValues(alpha: 0.1) 
                        : const Color(0xFF36B37E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: user.isAdmin ? const Color(0xFF0052CC) : const Color(0xFF36B37E),
                      ),
                    ),
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
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E6C84),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(
                            user.isAdmin ? 'Administrador' : 'Técnico',
                            user.isAdmin ? const Color(0xFF0052CC) : const Color(0xFF36B37E),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            user.isBlocked ? 'Bloqueado' : 'Activo',
                            user.isBlocked ? const Color(0xFFFF5630) : const Color(0xFF36B37E),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF5E6C84)),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.password, color: Color(0xFF0052CC)),
                        title: const Text('Restablecer Contraseña', style: TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.pop(context);
                          _resetPassword(user.email);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(
                          user.isBlocked ? Icons.lock_open : Icons.lock_outline,
                          color: user.isBlocked ? const Color(0xFF36B37E) : const Color(0xFFFFAB00),
                        ),
                        title: Text(
                          user.isBlocked ? 'Desbloquear' : 'Bloquear',
                          style: const TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleUserStatus(user.id, !user.isBlocked);
                        },
                      ),
                    ),
                    if (!user.isAdmin)
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline, color: Color(0xFFFF5630)),
                          title: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF5630), fontSize: 14)),
                          contentPadding: EdgeInsets.zero,
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
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEBECF0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.work_outline, size: 16, color: Color(0xFF5E6C84)),
                  const SizedBox(width: 8),
                  Text(
                    'Servicios completados: ${user.completedServices}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5E6C84),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Color(0xFF5E6C84)),
                  const SizedBox(width: 8),
                  Text(
                    'Ganancias totales: \$${user.totalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5E6C84),
                      fontWeight: FontWeight.w500,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Stream<List<app_user.User>> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
          Map<String, app_user.User> uniqueUsers = {};
          
          for (var doc in snapshot.docs) {
            final userData = {
              'id': doc.id,
              ...doc.data(),
            };
            final user = app_user.User.fromMap(userData);
            uniqueUsers[user.email] = user;
          }
          
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
          title: const Text('Crear Usuario', style: TextStyle(color: Color(0xFF172B4D))),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Nombre', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(passwordController, 'Contraseña', Icons.lock_outline, obscureText: true, minLength: 6),
                  const SizedBox(height: 16),
                  _buildTextField(confirmPasswordController, 'Confirmar Contraseña', Icons.lock_outline, obscureText: true, matchController: passwordController),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Es administrador', style: TextStyle(color: Color(0xFF172B4D))),
                    subtitle: const Text('Los administradores tienen acceso completo', style: TextStyle(color: Color(0xFF5E6C84), fontSize: 12)),
                    value: isAdmin,
                    activeColor: const Color(0xFF0052CC),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        isAdmin = value ?? false;
                        if (isAdmin) {
                          selectedSedeId = null;
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
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }

                        final sedes = snapshot.data ?? [];
                        if (sedes.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5630).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('No hay sedes disponibles. Cree una sede primero.', style: TextStyle(color: Color(0xFFFF5630))),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedSedeId,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar Sede',
                            prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF5E6C84)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0052CC), width: 2),
                            ),
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
                              return 'Debe seleccionar una sede';
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
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
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
                    
                    Navigator.pop(dialogContext);

                    if (userId != null) {
                      showAnimatedDialog(context, DialogType.success, 'Usuario creado exitosamente');
                    } else {
                      showAnimatedDialog(context, DialogType.error, 'Error al crear usuario');
                    }
                  } catch (e) {
                    showAnimatedDialog(context, DialogType.error, e.toString());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool obscureText = false, 
    TextInputType? keyboardType,
    int? minLength,
    TextEditingController? matchController}
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5E6C84)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0052CC), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF5E6C84)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo requerido';
        if (minLength != null && value!.length < minLength) return 'Mínimo $minLength caracteres';
        if (matchController != null && value != matchController.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }

  void _resetPassword(String email) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña', style: TextStyle(color: Color(0xFF172B4D))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: $email', style: const TextStyle(color: Color(0xFF5E6C84))),
              const SizedBox(height: 16),
              _buildTextField(newPasswordController, 'Nueva Contraseña', Icons.lock_outline, obscureText: true, minLength: 6),
              const SizedBox(height: 16),
              _buildTextField(confirmPasswordController, 'Confirmar Contraseña', Icons.lock_outline, obscureText: true, matchController: newPasswordController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
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
                if(success) {
                  showAnimatedDialog(context, DialogType.success, 'Contraseña cambiada exitosamente');
                } else {
                  showAnimatedDialog(context, DialogType.error, 'Error al cambiar la contraseña');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(String userId, bool isBlocked) async {
    final success = await _authService.toggleUserStatus(userId, isBlocked);
    if (!mounted) return;

    if (success) {
      showAnimatedDialog(context, DialogType.success, isBlocked ? 'Usuario bloqueado exitosamente' : 'Usuario desbloqueado exitosamente');
    } else {
      showAnimatedDialog(context, DialogType.error, 'Error al cambiar el estado del usuario');
    }
  }

  void _showDeleteConfirmation(BuildContext context, app_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación', style: TextStyle(color: Color(0xFF172B4D))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        content: Text('¿Está seguro que desea eliminar al usuario ${user.name}?', style: const TextStyle(color: Color(0xFF5E6C84))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await _authService.deleteUser(user.id);
              
              if (success) {
                showAnimatedDialog(context, DialogType.success, 'Usuario eliminado exitosamente');
              } else {
                showAnimatedDialog(context, DialogType.error, 'Error al eliminar usuario');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5630),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

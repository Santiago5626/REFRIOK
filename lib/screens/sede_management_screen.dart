import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sede.dart';
import '../services/sede_service.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';

class SedeManagementScreen extends StatefulWidget {
  const SedeManagementScreen({super.key});

  @override
  State<SedeManagementScreen> createState() => _SedeManagementScreenState();
}

class _SedeManagementScreenState extends State<SedeManagementScreen> {
  final SedeService _sedeService = SedeService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateSedeDialog(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Crear Nueva Sede'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Sede>>(
            stream: _sedeService.getAllSedes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final sedes = snapshot.data ?? [];
              if (sedes.isEmpty) {
                return const Center(
                  child: Text('No hay sedes registradas'),
                );
              }

              return ListView.builder(
                itemCount: sedes.length,
                itemBuilder: (context, index) {
                  final sede = sedes[index];
                  return _buildSedeCard(sede);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSedeCard(Sede sede) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: sede.activa ? Colors.green : Colors.grey,
          child: Icon(
            Icons.location_city,
            color: Colors.white,
          ),
        ),
        title: Text(
          sede.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor base revisión: \$${sede.valorBaseRevision.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.blue),
            ),
            Text(
              sede.activa ? 'Activa' : 'Inactiva',
              style: TextStyle(
                color: sede.activa ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSedeDialog(context, sede);
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  sede.activa ? Icons.block : Icons.check_circle,
                  color: sede.activa ? Colors.red : Colors.green,
                ),
                title: Text(sede.activa ? 'Desactivar' : 'Activar'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSedeStatus(sede);
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Asignar Técnico'),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignTechnicianDialog(context, sede);
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, sede);
                },
              ),
            ),
          ],
        ),
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sedeService.getTechniciansBySede(sede.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final technicians = snapshot.data ?? [];
              if (technicians.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay técnicos asignados a esta sede'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Técnicos Asignados:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      final technician = technicians[index];
                      return ListTile(
                        title: Text(technician['name'] ?? ''),
                        subtitle: Text(technician['email'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeTechnicianFromSede(
                            technician['id'],
                            sede.nombre,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateSedeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final valorBaseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Sede'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de la Sede'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valorBaseController,
                decoration: const InputDecoration(
                  labelText: 'Valor Base de Revisión',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo requerido';
                  }
                  final number = int.tryParse(value!);
                  if (number == null || number <= 0) {
                    return 'Ingrese un valor válido';
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
                final nombre = nombreController.text;
                final valorBase = double.parse(valorBaseController.text);

                Navigator.pop(context);

                final sedeId = await _sedeService.createSede(
                  nombre: nombre,
                  valorBaseRevision: valorBase,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sedeId != null
                          ? 'Sede creada exitosamente'
                          : 'Error al crear la sede',
                    ),
                    backgroundColor: sedeId != null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditSedeDialog(BuildContext context, Sede sede) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: sede.nombre);
    final valorBaseController = TextEditingController(
      text: sede.valorBaseRevision.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Sede'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de la Sede'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valorBaseController,
                decoration: const InputDecoration(
                  labelText: 'Valor Base de Revisión',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo requerido';
                  }
                  final number = int.tryParse(value!);
                  if (number == null || number <= 0) {
                    return 'Ingrese un valor válido';
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
                final updatedSede = Sede(
                  id: sede.id,
                  nombre: nombreController.text,
                  valorBaseRevision: double.parse(valorBaseController.text),
                  createdAt: sede.createdAt,
                  activa: sede.activa,
                );

                Navigator.pop(context);

                final success = await _sedeService.updateSede(updatedSede);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Sede actualizada exitosamente'
                          : 'Error al actualizar la sede',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _toggleSedeStatus(Sede sede) async {
    final success = await _sedeService.toggleSedeStatus(sede.id, !sede.activa);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? sede.activa
                  ? 'Sede desactivada exitosamente'
                  : 'Sede activada exitosamente'
              : 'Error al cambiar el estado de la sede',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showAssignTechnicianDialog(BuildContext context, Sede sede) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Técnico a ${sede.nombre}'),
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

              final technicians = snapshot.data ?? [];
              if (technicians.isEmpty) {
                return const Text('No hay técnicos disponibles');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  final technician = technicians[index];
                  final isAssigned = technician.sedeId == sede.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          technician.isBlocked ? Colors.red : Colors.green,
                      child: Icon(
                        technician.isBlocked ? Icons.block : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(technician.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(technician.email),
                        if (technician.sedeId != null && !isAssigned)
                          const Text(
                            'Ya asignado a otra sede',
                            style: TextStyle(color: Colors.orange),
                          ),
                      ],
                    ),
                    trailing: isAssigned
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    enabled: !technician.isBlocked && !isAssigned,
                    onTap: technician.isBlocked || isAssigned
                        ? null
                        : () async {
                            Navigator.pop(context);
                            final success =
                                await _sedeService.assignTechnicianToSede(
                              technician.id,
                              sede.id,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Técnico asignado exitosamente'
                                      : 'Error al asignar técnico',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _removeTechnicianFromSede(String technicianId, String sedeName) async {
    final success = await _sedeService.removeTechnicianFromSede(technicianId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Técnico removido de $sedeName exitosamente'
              : 'Error al remover técnico',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Sede sede) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro que desea eliminar la sede ${sede.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _sedeService.deleteSede(sede.id);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Sede eliminada exitosamente'
                        : 'Error al eliminar la sede. Asegúrese de que no tenga técnicos asignados.',
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

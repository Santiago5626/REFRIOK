import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import '../services/invoice_service.dart';
import '../services/auth_service.dart';
import '../services/service_management_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/download_helper.dart';
import '../screens/edit_service_screen.dart';
import '../screens/service_detail_screen.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final bool isAvailable;
  final app_user.User currentUser;
  final Function(Service) onAssign;
  final Function(Service) onDelete;
  final bool showStatusInBottom;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isAvailable,
    required this.currentUser,
    required this.onAssign,
    required this.onDelete,
    this.showStatusInBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(service.status);
    final statusIcon = _getStatusIcon(service.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF172B4D),
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, 
                                size: 16, 
                                color: Colors.grey[500]
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  service.location,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (currentUser.isAdmin)
                      _buildAdminActions(context)
                    else if (!isAvailable)
                      _buildStatusChip(service.status),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF5E6C84)),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(service.scheduledFor),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E6C84),
                        ),
                      ),
                      const Spacer(),
                      if (!isAvailable && showStatusInBottom)
                        Text(
                          _getStatusText(service.status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40), // Desplaza el menú hacia abajo
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditServiceScreen(service: service),
            ),
          );
        } else if (value == 'assign') {
          _showAssignDialog(context, service);
        } else if (value == 'delete') {
          onDelete(service);
        } else if (value == 'invoice') {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            
            final invoiceService = InvoiceService();
            final bytes = await invoiceService.generateInvoice(service);
            
            if (context.mounted) Navigator.pop(context); // Cerrar loading
            
            if (bytes.isNotEmpty) {
              await downloadFile(bytes, 'factura_${service.id}.pdf');
            } else {
              if (context.mounted) {
                showAnimatedDialog(context, DialogType.error, 'No se pudo generar la factura');
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Cerrar loading si sigue abierto
              showAnimatedDialog(context, DialogType.error, 'Error: $e');
            }
          }
        }
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[];

        // Editar (si no está pagado)
        if (service.status != ServiceStatus.paid) {
          items.add(
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0052CC)),
                  SizedBox(width: 12),
                  Text('Editar', style: TextStyle(color: Color(0xFF0052CC))),
                ],
              ),
            ),
          );
        }

        // Asignar/Reasignar (solo si no está completado o pagado)
        if (service.status != ServiceStatus.completed && service.status != ServiceStatus.paid) {
          items.add(
            PopupMenuItem<String>(
              value: 'assign',
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined, size: 20, color: Color(0xFF6554C0)),
                  const SizedBox(width: 12),
                  Text(
                    service.assignedTechnicianId != null ? 'Reasignar' : 'Asignar',
                    style: const TextStyle(color: Color(0xFF6554C0)),
                  ),
                ],
              ),
            ),
          );
        }

        // Factura (solo si está completado o pagado)
        if (service.status == ServiceStatus.completed || service.status == ServiceStatus.paid) {
          items.add(
            const PopupMenuItem<String>(
              value: 'invoice',
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 20, color: Color(0xFF36B37E)),
                  SizedBox(width: 12),
                  Text('Factura', style: TextStyle(color: Color(0xFF36B37E))),
                ],
              ),
            ),
          );
        }

        // Eliminar
        items.add(
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: AppTheme.errorText, size: 20),
                SizedBox(width: 12),
                Text('Eliminar', style: TextStyle(color: AppTheme.errorText)),
              ],
            ),
          ),
        );

        return items;
      },
    );
  }

  Widget _buildStatusChip(ServiceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return AppTheme.warningText;
      case ServiceStatus.assigned:
        return AppTheme.primaryBlue;
      case ServiceStatus.onWay:
        return Colors.purple;
      case ServiceStatus.inProgress:
        return Colors.amber[800]!;
      case ServiceStatus.completed:
        return AppTheme.successText;
      case ServiceStatus.cancelled:
        return AppTheme.errorText;
      case ServiceStatus.paid:
        return Colors.teal;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Icons.pending_outlined;
      case ServiceStatus.assigned:
        return Icons.assignment_ind_outlined;
      case ServiceStatus.onWay:
        return Icons.directions_car_outlined;
      case ServiceStatus.inProgress:
        return Icons.build_outlined;
      case ServiceStatus.completed:
        return Icons.check_circle_outline;
      case ServiceStatus.cancelled:
        return Icons.cancel_outlined;
      case ServiceStatus.paid:
        return Icons.paid_outlined;
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
      case ServiceStatus.paid:
        return 'Pagado';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showAssignDialog(BuildContext context, Service service) async {
    final authService = AuthService();
    final serviceService = ServiceManagementService();
    
    List<app_user.User> allUsers = await authService.getUsers();

    // Incluir tanto técnicos como administradores
    List<app_user.User> availableUsers = allUsers
        .where((user) =>
            (service.sedeId == null || user.sedeId == service.sedeId || user.isAdmin))
        .toList();

    if (!context.mounted) return;

    app_user.User? selectedTechnician = await showDialog<app_user.User>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Asignar Usuario'),
          content: SizedBox(
            width: double.maxFinite,
            child: availableUsers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay usuarios disponibles'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin
                              ? AppTheme.primaryBlue
                              : AppTheme.successText,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.isAdmin ? 'Administrador' : 'Técnico'),
                        onTap: () {
                          Navigator.of(dialogContext).pop(user);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedTechnician != null) {
      if (!context.mounted) return;
      
      try {
        await serviceService.assignService(service.id, selectedTechnician.id);
        if (!context.mounted) return;
        showAnimatedDialog(context, DialogType.success, 'Servicio asignado correctamente');
      } catch (e) {
        if (!context.mounted) return;
        showAnimatedDialog(context, DialogType.error, e.toString());
      }
    }
  }
}

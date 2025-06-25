import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import 'notification_service.dart';
import 'auth_service.dart';
import 'invoice_service.dart';
import 'permission_service.dart';

class ServiceManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener servicios disponibles para un técnico
  Stream<List<Service>> getAvailableServices() {
    return _firestore
        .collection('services')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Obtener servicios asignados a un técnico específico
  Stream<List<Service>> getTechnicianServices(String technicianId) {
    return _firestore
        .collection('services')
        .where('assignedTechnicianId', isEqualTo: technicianId)
        .where('status', whereIn: ['assigned', 'onWay', 'inProgress'])
        .orderBy('scheduledFor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Obtener historial de servicios completados
  Stream<List<Service>> getCompletedServices(String technicianId) {
    return _firestore
        .collection('services')
        .where('assignedTechnicianId', isEqualTo: technicianId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  // Verificar y bloquear técnicos con servicios impagos
  Future<void> checkAndBlockTechnicians() async {
    try {
      // Obtener todos los servicios completados y no pagados
      QuerySnapshot unpaidServices = await _firestore
          .collection('services')
          .where('status', isEqualTo: 'completed')
          .where('isPaid', isEqualTo: false)
          .get();

      // Agrupar servicios por técnico
      Map<String, List<Service>> servicesByTechnician = {};
      
      for (var doc in unpaidServices.docs) {
        Service service = Service.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        
        if (service.assignedTechnicianId != null) {
          if (!servicesByTechnician.containsKey(service.assignedTechnicianId)) {
            servicesByTechnician[service.assignedTechnicianId!] = [];
          }
          servicesByTechnician[service.assignedTechnicianId!] ??= [];
          servicesByTechnician[service.assignedTechnicianId!]?.add(service);
        }
      }

      // Verificar cada técnico
      for (var entry in servicesByTechnician.entries) {
        String technicianId = entry.key;
        List<Service> services = entry.value;
        
        // Verificar si hay servicios que requieren bloqueo
        bool shouldBlock = services.any((service) => service.shouldBlockTechnician());
        
        if (shouldBlock) {
          // Bloquear al técnico
          await _firestore.collection('users').doc(technicianId).update({
            'isBlocked': true,
            'blockedAt': DateTime.now().toIso8601String(),
            'blockReason': 'Servicios completados sin pago de comisión',
          });

          // Notificar al técnico
          await _notificationService.notifyTechnicianBlocked(
            technicianId: technicianId,
            reason: 'Tienes servicios completados pendientes de pago',
          );
        }
      }
    } catch (e) {
      print('Error al verificar y bloquear técnicos: $e');
    }
  }

  // Marcar servicio como pagado (solo admin)
  Future<bool> markServiceAsPaid(String serviceId) async {
    try {
      DocumentSnapshot serviceDoc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      if (service.status != ServiceStatus.completed) {
        throw Exception('Solo se pueden marcar como pagados los servicios completados');
      }

      await _firestore.collection('services').doc(serviceId).update({
        'isPaid': true,
        'paidAt': DateTime.now().toIso8601String(),
        'status': ServiceStatus.paid.toString().split('.').last,
      });

      // Si el técnico estaba bloqueado, desbloquearlo
      if (service.assignedTechnicianId != null) {
        DocumentSnapshot technicianDoc = await _firestore
            .collection('users')
            .doc(service.assignedTechnicianId)
            .get();

        if (technicianDoc.exists) {
          Map<String, dynamic> technicianData = 
              technicianDoc.data() as Map<String, dynamic>;
          
          if (technicianData['isBlocked'] == true) {
            // Verificar si tiene otros servicios pendientes de pago
            QuerySnapshot unpaidServices = await _firestore
                .collection('services')
                .where('assignedTechnicianId', isEqualTo: service.assignedTechnicianId)
                .where('status', isEqualTo: 'completed')
                .where('isPaid', isEqualTo: false)
                .get();

            if (unpaidServices.docs.isEmpty) {
              // No hay más servicios pendientes, desbloquear al técnico
              await _firestore
                  .collection('users')
                  .doc(service.assignedTechnicianId)
                  .update({
                'isBlocked': false,
                'blockedAt': null,
                'blockReason': null,
              });

              // Notificar al técnico que ha sido desbloqueado
              await _notificationService.notifyTechnicianUnblocked(
                technicianId: service.assignedTechnicianId!,
              );
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Error al marcar servicio como pagado: $e');
      return false;
    }
  }

  // Obtener el ID del administrador
  Future<String?> _getAdminId() async {
    try {
      QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return adminQuery.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error al obtener ID del admin: $e');
      return null;
    }
  }

  // Aceptar un servicio
  Future<bool> acceptService(String serviceId, String technicianId) async {
    try {
      // Obtener los detalles del servicio antes de actualizarlo
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      // Actualizar el estado del servicio
      await _firestore.collection('services').doc(serviceId).update({
        'assignedTechnicianId': technicianId,
        'status': 'assigned',
      });

      // Enviar notificación al técnico
      await _notificationService.notifyServiceAssignment(
        technicianId: technicianId,
        serviceId: serviceId,
        serviceTitle: service.title,
        clientName: service.clientName,
        location: service.location,
      );

      // Notificar al admin sobre la asignación
      String? adminId = await _getAdminId();
      if (adminId != null) {
        await _notificationService.notifyServiceStatusChange(
          serviceId: serviceId,
          serviceTitle: service.title,
          newStatus: 'assigned',
          technicianId: technicianId,
          clientName: service.clientName,
        );
      }

      return true;
    } catch (e) {
      print('Error al aceptar servicio: $e');
      return false;
    }
  }

  // Marcar que el técnico está en camino
  Future<bool> markOnWay(String serviceId) async {
    try {
      // Obtener los detalles del servicio
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      await _firestore.collection('services').doc(serviceId).update({
        'status': 'onWay',
      });

      // Notificar al admin
      String? adminId = await _getAdminId();
      if (adminId != null) {
        await _notificationService.notifyServiceStatusChange(
          serviceId: serviceId,
          serviceTitle: service.title,
          newStatus: 'onWay',
          technicianId: service.assignedTechnicianId ?? '',
          clientName: service.clientName,
        );
      }

      return true;
    } catch (e) {
      print('Error al marcar en camino: $e');
      return false;
    }
  }

  // Marcar llegada al lugar con tipo de servicio
  Future<bool> markArrivedWithServiceType(
      String serviceId, ServiceType serviceType) async {
    try {
      // Obtener el servicio para calcular el precio final
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      // Calcular precio final según el tipo de servicio
      double finalPrice = serviceType == ServiceType.revision
          ? service.basePrice // Usar precio base de la sede para revisión
          : service.basePrice; // Precio base para servicio completo

      await _firestore.collection('services').doc(serviceId).update({
        'status': 'inProgress',
        'arrivedAt': DateTime.now().toIso8601String(),
        'serviceType': serviceType.toString().split('.').last,
        'finalPrice': finalPrice,
        'technicianCommission': finalPrice * 0.7, // 70% para el técnico
        'adminCommission': finalPrice * 0.3, // 30% para el admin
      });

      // Notificar al admin
      String? adminId = await _getAdminId();
      if (adminId != null) {
        await _notificationService.notifyServiceStatusChange(
          serviceId: serviceId,
          serviceTitle: service.title,
          newStatus: 'inProgress',
          technicianId: service.assignedTechnicianId ?? '',
          clientName: service.clientName,
        );
      }

      return true;
    } catch (e) {
      print('Error al marcar llegada: $e');
      return false;
    }
  }

  // Completar servicio
  Future<bool> completeService(
    String serviceId,
    ServiceType serviceType, {
    String? notes,
    double? finalPrice,
  }) async {
    try {
      // Obtener el servicio actual para verificar si ya tiene tipo de servicio
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Map<String, dynamic> serviceData =
          serviceDoc.data() as Map<String, dynamic>;
      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceData,
      });

      // Calcular precio final
      double calculatedPrice;
      if (serviceType == ServiceType.revision) {
        calculatedPrice = service.basePrice; // Usar precio base de la sede para revisión
      } else if (finalPrice != null) {
        calculatedPrice =
            finalPrice; // Usar precio proporcionado para servicio completo
      } else {
        throw Exception(
            'Para servicios completos, se debe especificar el precio final');
      }

      Map<String, dynamic> updateData = {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
        'notes': notes,
        'serviceType': serviceType.toString().split('.').last,
        'finalPrice': calculatedPrice,
        'technicianCommission': calculatedPrice * 0.7,
        'adminCommission': calculatedPrice * 0.3,
      };

      await _firestore.collection('services').doc(serviceId).update(updateData);

      // Actualizar estadísticas del técnico
      await _updateTechnicianStats(serviceId, serviceType);

      // Notificar al admin sobre la finalización
      String? adminId = await _getAdminId();
      if (adminId != null) {
        await _notificationService.notifyServiceStatusChange(
          serviceId: serviceId,
          serviceTitle: service.title,
          newStatus: 'completed',
          technicianId: service.assignedTechnicianId ?? '',
          clientName: service.clientName,
        );
      }

      return true;
    } catch (e) {
      print('Error al completar servicio: $e');
      return false;
    }
  }

  // Actualizar estadísticas del técnico
  Future<void> _updateTechnicianStats(
      String serviceId, ServiceType serviceType) async {
    try {
      // Obtener el servicio para calcular la comisión
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (serviceDoc.exists) {
        Service service = Service.fromMap({
          'id': serviceDoc.id,
          ...serviceDoc.data() as Map<String, dynamic>,
        });

        // Obtener todos los servicios completados del técnico
        QuerySnapshot completedServices = await _firestore
            .collection('services')
            .where('assignedTechnicianId', isEqualTo: service.assignedTechnicianId)
            .where('status', isEqualTo: 'completed')
            .get();

        // Calcular totales
        double totalEarnings = 0.0;
        int totalServices = completedServices.docs.length;

        for (var doc in completedServices.docs) {
          Service completedService = Service.fromMap({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
          totalEarnings += completedService.technicianCommission;
        }

        // Actualizar estadísticas del técnico
        await _firestore
            .collection('users')
            .doc(service.assignedTechnicianId!)
            .update({
          'totalEarnings': totalEarnings,
          'completedServices': totalServices,
        });
      }
    } catch (e) {
      print('Error al actualizar estadísticas del técnico: $e');
    }
  }

  // Cancelar servicio
  Future<bool> cancelService(String serviceId, String reason) async {
    try {
      // Obtener los detalles del servicio
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      await _firestore.collection('services').doc(serviceId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': DateTime.now().toIso8601String(),
      });

      // Notificar al admin
      String? adminId = await _getAdminId();
      if (adminId != null) {
        await _notificationService.notifyServiceStatusChange(
          serviceId: serviceId,
          serviceTitle: service.title,
          newStatus: 'cancelled',
          technicianId: service.assignedTechnicianId ?? '',
          clientName: service.clientName,
        );
      }

      return true;
    } catch (e) {
      print('Error al cancelar servicio: $e');
      return false;
    }
  }

  // Crear nuevo servicio (para admin)
  Future<String?> createService({
    required String title,
    required String description,
    required String location,
    required String clientName,
    required String clientPhone,
    required DateTime scheduledFor,
    required double basePrice,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      // Determinar automáticamente el tipo de servicio si el precio base > 30000
      ServiceType? serviceType;
      double finalPrice = 0.0;
      double technicianCommission = 0.0;
      double adminCommission = 0.0;

      if (basePrice > 30000) {
        serviceType = ServiceType.complete;
        finalPrice = basePrice;
        technicianCommission = finalPrice * 0.7;
        adminCommission = finalPrice * 0.3;
      }

      Map<String, dynamic> serviceData = {
        'title': title,
        'description': description,
        'location': location,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'createdAt': DateTime.now().toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'basePrice': basePrice,
        'status': 'pending',
        'finalPrice': finalPrice,
        'technicianCommission': technicianCommission,
        'adminCommission': adminCommission,
      };

      // Solo agregar serviceType si está definido
      if (serviceType != null) {
        serviceData['serviceType'] = serviceType.toString().split('.').last;
      }

      if (additionalDetails != null) {
        serviceData['additionalDetails'] = additionalDetails;
      }

      DocumentReference docRef =
          await _firestore.collection('services').add(serviceData);
      return docRef.id;
    } catch (e) {
      print('Error al crear servicio: $e');
      return null;
    }
  }

  // Obtener todos los servicios (para admin)
  Stream<List<Service>> getAllServices() {
    return _firestore
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Eliminar servicio (para admin)
  Future<bool> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar servicio: $e');
      return false;
    }
  }

  // Actualizar servicio (para admin)
  Future<bool> updateService({
    required String serviceId,
    String? title,
    String? description,
    String? location,
    String? clientName,
    String? clientPhone,
    DateTime? scheduledFor,
    double? basePrice,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (clientName != null) updateData['clientName'] = clientName;
      if (clientPhone != null) updateData['clientPhone'] = clientPhone;
      if (scheduledFor != null) {
        updateData['scheduledFor'] = scheduledFor.toIso8601String();
      }
      if (basePrice != null) {
        updateData['basePrice'] = basePrice;

        // Recalcular comisiones si el servicio aún no está completado
        DocumentSnapshot serviceDoc =
            await _firestore.collection('services').doc(serviceId).get();
        if (serviceDoc.exists) {
          Map<String, dynamic> serviceData =
              serviceDoc.data() as Map<String, dynamic>;
          String status = serviceData['status'] ?? 'pending';

          // Solo recalcular si el servicio no está completado
          if (status != 'completed') {
            if (basePrice > 30000) {
              updateData['finalPrice'] = basePrice;
              updateData['technicianCommission'] = basePrice * 0.7;
              updateData['adminCommission'] = basePrice * 0.3;
              updateData['serviceType'] = 'complete';
            } else {
              // Si el precio es menor o igual a 30000, remover el tipo de servicio predefinido
              updateData['finalPrice'] = 0.0;
              updateData['technicianCommission'] = 0.0;
              updateData['adminCommission'] = 0.0;
              updateData['serviceType'] = FieldValue.delete();
            }
          }
        }
      }
      if (additionalDetails != null) {
        updateData['additionalDetails'] = additionalDetails;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('services')
            .doc(serviceId)
            .update(updateData);
        return true;
      }

      return false;
    } catch (e) {
      print('Error al actualizar servicio: $e');
      return false;
    }
  }

  // Obtener técnicos disponibles para asignar servicios
  Future<List<app_user.User>> getAvailableTechnicians() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error al obtener técnicos disponibles: $e');
      return [];
    }
  }

  // Asignar técnico a un servicio (para admin)
  Future<bool> assignTechnician(String serviceId, String technicianId) async {
    try {
      // Obtener los detalles del servicio antes de actualizarlo
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        return false;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      // Actualizar el estado del servicio
      await _firestore.collection('services').doc(serviceId).update({
        'assignedTechnicianId': technicianId,
        'status': 'assigned',
        'assignedAt': DateTime.now().toIso8601String(),
      });

      // Enviar notificación al técnico
      await _notificationService.notifyServiceAssignment(
        technicianId: technicianId,
        serviceId: serviceId,
        serviceTitle: service.title,
        clientName: service.clientName,
        location: service.location,
      );

      return true;
    } catch (e) {
      print('Error al asignar técnico: $e');
      return false;
    }
  }

  // Generar factura para un servicio completado
  Future<File?> generateInvoice(String serviceId) async {
    try {
      // Obtener los detalles del servicio
      DocumentSnapshot serviceDoc =
          await _firestore.collection('services').doc(serviceId).get();

      if (!serviceDoc.exists) {
        print('Error: Servicio no encontrado');
        return null;
      }

      Service service = Service.fromMap({
        'id': serviceDoc.id,
        ...serviceDoc.data() as Map<String, dynamic>,
      });

      // Verificar que el servicio esté completado
      if (service.status != ServiceStatus.completed) {
        print('Error: El servicio no está completado');
        return null;
      }

      // Obtener los detalles del técnico
      DocumentSnapshot technicianDoc = await _firestore
          .collection('users')
          .doc(service.assignedTechnicianId)
          .get();

      if (!technicianDoc.exists) {
        print('Error: Técnico no encontrado');
        return null;
      }

      app_user.User technician = app_user.User.fromMap({
        'id': technicianDoc.id,
        ...technicianDoc.data() as Map<String, dynamic>,
      });

      // Generar la factura usando el InvoiceService
      File invoice = await InvoiceService.generateInvoice(service, technician);

      return invoice;
    } catch (e) {
      print('Error al generar factura: $e');
      return null;
    }
  }

  // Imprimir o mostrar vista previa de la factura
  Future<void> previewInvoice(String serviceId, BuildContext context) async {
    try {
      // Solicitar permisos primero
      bool hasPermission =
          await PermissionService.requestStoragePermission(context);
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Se requieren permisos de almacenamiento para generar facturas'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      File? invoice = await generateInvoice(serviceId);
      if (invoice != null) {
        if (context.mounted) {
          await Printing.layoutPdf(
            onLayout: (_) => invoice.readAsBytes(),
          );
          // Mostrar mensaje de éxito con la ubicación del archivo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Factura guardada en: ${invoice.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al mostrar vista previa de factura: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el total de comisiones pendientes de pago para un técnico
  Future<double> getPendingCommissions(String technicianId) async {
    try {
      // Obtener todos los servicios completados pero no pagados del técnico
      QuerySnapshot unpaidServices = await _firestore
          .collection('services')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed')
          .where('isPaid', isEqualTo: false)
          .get();

      double totalPending = 0.0;

      for (var doc in unpaidServices.docs) {
        Service service = Service.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Calcular la comisión del admin (30% del precio final)
        totalPending += service.adminCommission;
      }

      return totalPending;
    } catch (e) {
      print('Error al calcular comisiones pendientes: $e');
      return 0.0;
    }
  }

  // Obtener las ganancias pendientes del técnico (su comisión del 70%)
  Future<double> getPendingEarnings(String technicianId) async {
    try {
      // Obtener todos los servicios completados pero no pagados del técnico
      QuerySnapshot unpaidServices = await _firestore
          .collection('services')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed')
          .where('isPaid', isEqualTo: false)
          .get();

      double totalPendingEarnings = 0.0;

      for (var doc in unpaidServices.docs) {
        Service service = Service.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Sumar la comisión del técnico (70% del precio final)
        totalPendingEarnings += service.technicianCommission;
      }

      return totalPendingEarnings;
    } catch (e) {
      print('Error al calcular ganancias pendientes: $e');
      return 0.0;
    }
  }

  // Obtener el historial de pagos de un técnico
  Future<List<Map<String, dynamic>>> getPaymentHistory(String technicianId) async {
    try {
      QuerySnapshot paidServices = await _firestore
          .collection('services')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .where('isPaid', isEqualTo: true)
          .orderBy('paidAt', descending: true)
          .get();

      return paidServices.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'serviceId': doc.id,
          'title': data['title'] ?? '',
          'paidAt': data['paidAt'] != null ? DateTime.parse(data['paidAt']) : null,
          'amount': (data['adminCommission'] ?? 0.0).toDouble(),
        };
      }).toList();
    } catch (e) {
      print('Error al obtener historial de pagos: $e');
      return [];
    }
  }

  // Verificar si un técnico tiene pagos pendientes
  Future<bool> hasPendingPayments(String technicianId) async {
    double pendingAmount = await getPendingCommissions(technicianId);
    return pendingAmount > 0;
  }

  // Obtener el historial de pagos de un técnico como Stream
  Stream<List<Map<String, dynamic>>> getTechnicianPayments(String technicianId) {
    return _firestore
        .collection('payments')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data();
              return {
                'id': doc.id,
                'amount': (data['amount'] ?? 0.0).toDouble(),
                'paymentDate': data['paymentDate'] ?? DateTime.now().toIso8601String(),
                'description': data['description'] ?? '',
              };
            }).toList());
  }

  // Marcar comisión como pagada
  Future<bool> markCommissionPaid(String technicianId, double amount) async {
    try {
      // Crear registro de pago
      await _firestore.collection('payments').add({
        'technicianId': technicianId,
        'amount': amount,
        'paymentDate': DateTime.now().toIso8601String(),
        'description': 'Pago de comisiones',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Marcar servicios como pagados
      QuerySnapshot unpaidServices = await _firestore
          .collection('services')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed')
          .where('isPaid', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unpaidServices.docs) {
        batch.update(doc.reference, {
          'isPaid': true,
          'paidAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();

      // Actualizar fecha de último pago del técnico
      await _firestore.collection('users').doc(technicianId).update({
        'lastPaymentDate': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error al marcar comisión como pagada: $e');
      return false;
    }
  }

  // Desbloquear técnico
  Future<bool> unblockTechnician(String technicianId) async {
    try {
      await _firestore.collection('users').doc(technicianId).update({
        'isBlocked': false,
        'unblockedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error al desbloquear técnico: $e');
      return false;
    }
  }
}

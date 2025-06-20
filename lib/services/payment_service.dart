import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Marcar que un técnico pagó su comisión
  Future<bool> markCommissionPaid(String technicianId, double amount) async {
    try {
      final now = DateTime.now();
      
      // Actualizar la fecha de último pago del técnico
      await _firestore.collection('users').doc(technicianId).update({
        'lastPaymentDate': now.toIso8601String(),
        'isBlocked': false,
      });

      // Registrar el pago en el historial
      await _firestore.collection('payments').add({
        'technicianId': technicianId,
        'amount': amount,
        'paymentDate': now.toIso8601String(),
        'type': 'commission_payment',
        'status': 'completed',
      });

      return true;
    } catch (e) {
      print('Error al marcar comisión como pagada: $e');
      return false;
    }
  }

  // Obtener historial de pagos de un técnico
  Stream<List<Map<String, dynamic>>> getTechnicianPayments(String technicianId) {
    return _firestore
        .collection('payments')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Obtener todos los pagos (para admin)
  Stream<List<Map<String, dynamic>>> getAllPayments() {
    return _firestore
        .collection('payments')
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Calcular comisiones pendientes de un técnico
  Future<double> getPendingCommissions(String technicianId) async {
    try {
      // Obtener servicios completados desde la última fecha de pago
      final userDoc = await _firestore.collection('users').doc(technicianId).get();
      final userData = userDoc.data();
      
      DateTime? lastPaymentDate;
      if (userData?['lastPaymentDate'] != null) {
        lastPaymentDate = DateTime.parse(userData!['lastPaymentDate']);
      }

      Query query = _firestore
          .collection('services')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: 'completed');

      if (lastPaymentDate != null) {
        query = query.where('completedAt', isGreaterThan: lastPaymentDate.toIso8601String());
      }

      final snapshot = await query.get();
      double totalCommissions = 0;

      for (var doc in snapshot.docs) {
        final serviceData = doc.data() as Map<String, dynamic>;
        final basePrice = (serviceData['basePrice'] ?? 0.0).toDouble();
        final serviceType = serviceData['serviceType'];
        
        double finalPrice;
        if (serviceType == 'revision') {
          finalPrice = 30000.0; // Precio fijo para revisión
        } else {
          finalPrice = basePrice;
        }
        
        totalCommissions += finalPrice * 0.70; // 70% para el técnico
      }

      return totalCommissions;
    } catch (e) {
      print('Error al calcular comisiones pendientes: $e');
      return 0;
    }
  }

  // Bloquear técnicos que no han pagado (ejecutar automáticamente)
  Future<void> blockOverdueTechnicians() async {
    try {
      final now = DateTime.now();
      final deadline = DateTime(now.year, now.month, now.day, 22); // 10 PM

      if (now.isAfter(deadline)) {
        // Obtener todos los técnicos
        final snapshot = await _firestore
            .collection('users')
            .where('isAdmin', isEqualTo: false)
            .get();

        WriteBatch batch = _firestore.batch();

        for (var doc in snapshot.docs) {
          final userData = doc.data();
          final lastPaymentDate = userData['lastPaymentDate'] != null
              ? DateTime.parse(userData['lastPaymentDate'])
              : null;

          // Si no ha pagado hoy, bloquear
          if (lastPaymentDate == null || 
              lastPaymentDate.isBefore(DateTime(now.year, now.month, now.day))) {
            batch.update(doc.reference, {'isBlocked': true});
          }
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error al bloquear técnicos: $e');
    }
  }

  // Desbloquear técnico manualmente (para admin)
  Future<bool> unblockTechnician(String technicianId) async {
    try {
      await _firestore.collection('users').doc(technicianId).update({
        'isBlocked': false,
      });
      return true;
    } catch (e) {
      print('Error al desbloquear técnico: $e');
      return false;
    }
  }
}

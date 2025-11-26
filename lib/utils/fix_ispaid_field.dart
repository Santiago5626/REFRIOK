import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para agregar isPaid: false a servicios completados que no tienen este campo
class FixIsPaidField {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fixServices() async {
    try {
      print('Buscando servicios completados sin campo isPaid...');
      
      // Obtener todos los servicios completados
      QuerySnapshot servicesSnapshot = await _firestore
          .collection('services')
          .where('status', isEqualTo: 'completed')
          .get();

      print('Encontrados ${servicesSnapshot.docs.length} servicios completados');

      int updatedCount = 0;

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Si no tiene el campo isPaid o es null, agregarlo
        if (!data.containsKey('isPaid') || data['isPaid'] == null) {
          await _firestore.collection('services').doc(doc.id).update({
            'isPaid': false,
          });
          
          updatedCount++;
          print('✓ Actualizado servicio ${doc.id}: ${data['title']}');
        }
      }

      print('\n=== Actualización completada ===');
      print('Servicios actualizados: $updatedCount');
      
    } catch (e) {
      print('Error durante la actualización: $e');
      rethrow;
    }
  }
}

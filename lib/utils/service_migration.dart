import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de migración para actualizar servicios existentes
/// Este script recalcula finalPrice, adminCommission y technicianCommission
/// para todos los servicios completados que tienen valores incorrectos
class ServiceMigrationScript {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateServices() async {
    try {
      print('Iniciando migración de servicios...');
      
      // Obtener todos los servicios completados o pagados
      QuerySnapshot servicesSnapshot = await _firestore
          .collection('services')
          .where('status', whereIn: ['completed', 'paid'])
          .get();

      print('Encontrados ${servicesSnapshot.docs.length} servicios para revisar');

      int updatedCount = 0;
      int skippedCount = 0;

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Verificar si el servicio necesita actualización
        final double storedFinalPrice = (data['finalPrice'] ?? 0.0).toDouble();
        final double basePrice = (data['basePrice'] ?? 0.0).toDouble();
        
        // Si finalPrice es 0 o igual a basePrice cuando debería ser diferente
        // (para servicios completos), necesita actualización
        bool needsUpdate = false;
        double correctFinalPrice = storedFinalPrice;
        
        if (storedFinalPrice == 0.0) {
          // Si finalPrice es 0, usar basePrice
          correctFinalPrice = basePrice;
          needsUpdate = true;
        }
        
        // Recalcular comisiones basadas en el finalPrice correcto
        double correctAdminCommission = correctFinalPrice * 0.3;
        double correctTechnicianCommission = correctFinalPrice * 0.7;
        
        double storedAdminCommission = (data['adminCommission'] ?? 0.0).toDouble();
        double storedTechnicianCommission = (data['technicianCommission'] ?? 0.0).toDouble();
        
        // Verificar si las comisiones están incorrectas (con margen de error de 1 peso)
        if ((storedAdminCommission - correctAdminCommission).abs() > 1.0 ||
            (storedTechnicianCommission - correctTechnicianCommission).abs() > 1.0) {
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          // Actualizar el servicio
          await _firestore.collection('services').doc(doc.id).update({
            'finalPrice': correctFinalPrice,
            'adminCommission': correctAdminCommission,
            'technicianCommission': correctTechnicianCommission,
          });
          
          updatedCount++;
          print('✓ Actualizado servicio ${doc.id}: ${data['title']}');
          print('  Final: \$${correctFinalPrice.toStringAsFixed(0)}, '
                'Admin: \$${correctAdminCommission.toStringAsFixed(0)}, '
                'Técnico: \$${correctTechnicianCommission.toStringAsFixed(0)}');
        } else {
          skippedCount++;
        }
      }

      print('\n=== Migración completada ===');
      print('Servicios actualizados: $updatedCount');
      print('Servicios sin cambios: $skippedCount');
      print('Total procesados: ${updatedCount + skippedCount}');
      
    } catch (e) {
      print('Error durante la migración: $e');
      rethrow;
    }
  }
}

// Para ejecutar este script, agrega esto temporalmente en tu main.dart
// o crea un botón en la pantalla de admin:
//
// Future<void> runMigration() async {
//   final migration = ServiceMigrationScript();
//   await migration.migrateServices();
// }

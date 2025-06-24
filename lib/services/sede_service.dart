import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sede.dart';

class SedeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear una nueva sede
  Future<String?> createSede({
    required String nombre,
    required double valorBaseRevision,
  }) async {
    try {
      final docRef = await _firestore.collection('sedes').add({
        'nombre': nombre,
        'valorBaseRevision': valorBaseRevision,
        'createdAt': DateTime.now().toIso8601String(),
        'activa': true,
      });

      // Actualizar el documento con su propio ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error al crear sede: $e');
      return null;
    }
  }

  // Obtener todas las sedes
  Stream<List<Sede>> getAllSedes() {
    return _firestore
        .collection('sedes')
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Sede.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Obtener sedes activas
  Stream<List<Sede>> getSedesActivas() {
    return _firestore
        .collection('sedes')
        .where('activa', isEqualTo: true)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Sede.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Obtener una sede por ID
  Future<Sede?> getSedeById(String sedeId) async {
    try {
      final doc = await _firestore.collection('sedes').doc(sedeId).get();
      if (doc.exists) {
        return Sede.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener sede: $e');
      return null;
    }
  }

  // Actualizar una sede
  Future<bool> updateSede(Sede sede) async {
    try {
      await _firestore.collection('sedes').doc(sede.id).update(sede.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar sede: $e');
      return false;
    }
  }

  // Activar/Desactivar una sede
  Future<bool> toggleSedeStatus(String sedeId, bool activa) async {
    try {
      await _firestore.collection('sedes').doc(sedeId).update({
        'activa': activa,
      });
      return true;
    } catch (e) {
      print('Error al cambiar estado de sede: $e');
      return false;
    }
  }

  // Eliminar una sede (solo si no tiene técnicos asignados)
  Future<bool> deleteSede(String sedeId) async {
    try {
      // Verificar si hay técnicos asignados a esta sede
      final techniciansQuery = await _firestore
          .collection('users')
          .where('sedeId', isEqualTo: sedeId)
          .where('isAdmin', isEqualTo: false)
          .get();

      if (techniciansQuery.docs.isNotEmpty) {
        throw Exception('No se puede eliminar la sede porque tiene técnicos asignados');
      }

      await _firestore.collection('sedes').doc(sedeId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar sede: $e');
      return false;
    }
  }

  // Obtener técnicos por sede
  Stream<List<Map<String, dynamic>>> getTechniciansBySede(String sedeId) {
    return _firestore
        .collection('users')
        .where('sedeId', isEqualTo: sedeId)
        .where('isAdmin', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Asignar técnico a sede
  Future<bool> assignTechnicianToSede(String technicianId, String sedeId) async {
    try {
      await _firestore.collection('users').doc(technicianId).update({
        'sedeId': sedeId,
      });
      return true;
    } catch (e) {
      print('Error al asignar técnico a sede: $e');
      return false;
    }
  }

  // Remover técnico de sede
  Future<bool> removeTechnicianFromSede(String technicianId) async {
    try {
      await _firestore.collection('users').doc(technicianId).update({
        'sedeId': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      print('Error al remover técnico de sede: $e');
      return false;
    }
  }
}

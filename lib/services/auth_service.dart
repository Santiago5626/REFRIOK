import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión
  Future<app_user.User?> signIn(String email, String password) async {
    try {
      // Primero intentar autenticación con Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        return null;
      }

      // Si es el admin y es su primer inicio de sesión
      if (email == 'josedavidlobo4@gmail.com') {
        // Verificar si existe en Firestore
        DocumentSnapshot adminDoc =
            await _firestore.collection('users').doc(result.user!.uid).get();

        if (!adminDoc.exists) {
          // Crear usuario admin en Firestore
          await _firestore.collection('users').doc(result.user!.uid).set({
            'id': result.user!.uid,
            'username': 'admin',
            'name': 'Administrador',
            'email': email,
            'isAdmin': true,
            'isBlocked': false,
            'lastPaymentDate': DateTime.now().toIso8601String(),
            'totalEarnings': 0,
            'completedServices': 0,
            'createdAt': DateTime.now().toIso8601String(),
          });

          return app_user.User.fromMap({
            'id': result.user!.uid,
            'username': 'admin',
            'name': 'Administrador',
            'email': email,
            'isAdmin': true,
            'isBlocked': false,
            'lastPaymentDate': DateTime.now().toIso8601String(),
            'totalEarnings': 0,
            'completedServices': 0,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Para usuarios normales, verificar si existen en Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      if (!userDoc.exists) {
        // Si no existe en Firestore, cerrar sesión y mostrar error
        await _auth.signOut();
        throw 'Usuario no registrado en el sistema. Contacte al administrador.';
      }

      // Crear objeto User con los datos de Firestore
      app_user.User user = app_user.User.fromMap({
        'id': userDoc.id,
        ...userDoc.data() as Map<String, dynamic>,
      });

      // Verificar si el usuario debe ser bloqueado
      if (user.shouldBeBlocked() && !user.isAdmin) {
        await _updateUserBlockStatus(user.id, true);
        user = user.copyWith(isBlocked: true);
      }

      return user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        print('Error en inicio de sesión: ${e.code} - ${e.message}');
        switch (e.code) {
          case 'user-not-found':
            throw 'No existe una cuenta con este correo electrónico';
          case 'wrong-password':
            throw 'Contraseña incorrecta';
          case 'invalid-email':
            throw 'El correo electrónico no es válido';
          case 'user-disabled':
            throw 'Esta cuenta ha sido deshabilitada';
          case 'operation-not-allowed':
            throw 'La autenticación por correo y contraseña no está habilitada';
          case 'too-many-requests':
            throw 'Demasiados intentos fallidos. Por favor, intente más tarde';
          case 'network-request-failed':
            throw 'Error de conexión. Por favor, verifique su conexión a internet';
          case 'invalid-credential':
            throw 'Credenciales inválidas. Verifique su correo y contraseña';
          default:
            throw e.message ?? 'Error de autenticación desconocido';
        }
      }
      print('Error inesperado en inicio de sesión: $e');
      if (e is String) {
        rethrow;
      }
      throw 'Error inesperado al iniciar sesión';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      // Limpiar completamente la sesión de Firebase Auth
      await _auth.signOut();

      // Establecer persistencia temporal para evitar problemas de caché
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
      } catch (e) {
        // Ignorar errores de persistencia en algunas plataformas
        print('Advertencia: No se pudo establecer persistencia de sesión: $e');
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Obtener datos del usuario actual
  Future<app_user.User?> getCurrentUserData() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          return app_user.User.fromMap({
            'id': userDoc.id,
            ...userDoc.data() as Map<String, dynamic>,
          });
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Actualizar estado de bloqueo del usuario
  Future<void> _updateUserBlockStatus(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': isBlocked,
      });
    } catch (e) {
      print('Error al actualizar estado de bloqueo: $e');
    }
  }

  // Verificar bloqueo automático (llamar diariamente a las 10 PM)
  Future<void> checkAndBlockOverdueUsers() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Obtener usuarios que no han pagado desde ayer
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('isBlocked', isEqualTo: false)
          .get();

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        app_user.User user = app_user.User.fromMap({
          'id': userDoc.id,
          ...userDoc.data() as Map<String, dynamic>,
        });

        if (user.shouldBeBlocked()) {
          await _updateUserBlockStatus(user.id, true);
        }
      }
    } catch (e) {
      print('Error al verificar usuarios vencidos: $e');
    }
  }

  // Registrar pago y desbloquear usuario
  Future<void> registerPayment(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastPaymentDate': DateTime.now().toIso8601String(),
        'isBlocked': false,
      });
    } catch (e) {
      print('Error al registrar pago: $e');
    }
  }

  // Crear nuevo usuario (solo para administradores)
  Future<String?> createUser({
    required String email,
    required String password,
    required String name,
    bool isAdmin = false,
  }) async {
    try {
      // Verificar que el usuario actual sea admin
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'No hay usuario autenticado';
      }

      // Obtener datos del admin actual
      DocumentSnapshot adminDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!adminDoc.exists) {
        throw 'Usuario admin no encontrado en Firestore';
      }

      Map<String, dynamic> adminData = adminDoc.data() as Map<String, dynamic>;

      if (adminData['isAdmin'] != true) {
        throw 'Solo los administradores pueden crear usuarios';
      }

      // Verificar si el email ya existe en Firestore
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw 'Ya existe un usuario con este correo electrónico';
      }

      // Guardar el usuario admin actual para restaurar la sesión
      String adminEmail = currentUser.email!;
      String adminPassword = 'Liam1234#'; // Contraseña del admin

      // Crear el usuario en Firebase Auth
      UserCredential newUserCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (newUserCredential.user == null) {
        throw 'Error al crear usuario en Firebase Auth';
      }

      // Crear el documento en Firestore con el UID de Firebase Auth
      await _firestore
          .collection('users')
          .doc(newUserCredential.user!.uid)
          .set({
        'id': newUserCredential.user!.uid,
        'name': name,
        'email': email,
        'isAdmin': isAdmin,
        'isBlocked': false,
        'lastPaymentDate': DateTime.now().toIso8601String(),
        'totalEarnings': 0,
        'completedServices': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Cerrar sesión del nuevo usuario
      await _auth.signOut();

      // Restaurar la sesión del admin
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      return newUserCredential.user!.uid;
    } catch (e) {
      print('Error al crear usuario: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw 'La contraseña debe tener al menos 6 caracteres';
          case 'email-already-in-use':
            throw 'Ya existe una cuenta con este correo electrónico en Firebase Auth';
          case 'invalid-email':
            throw 'El correo electrónico no es válido';
          default:
            throw e.message ?? 'Error al crear usuario en Firebase Auth';
        }
      }
      rethrow;
    }
  }

  // Cambiar contraseña creando nuevo usuario
  Future<bool> changePassword(String email, String newPassword) async {
    try {
      // Buscar el usuario por email en Firestore
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Usuario no encontrado';
      }

      // Obtener los datos del usuario
      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Guardar el usuario actual para restaurar la sesión
      User? currentAdmin = _auth.currentUser;

      // Crear un nuevo usuario con la nueva contraseña
      UserCredential newUserCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: newPassword,
      );

      // Actualizar el documento en Firestore con el nuevo UID
      await _firestore
          .collection('users')
          .doc(newUserCredential.user!.uid)
          .set({
        ...userData,
        'id': newUserCredential.user!.uid,
      });

      // Eliminar el documento anterior
      await _firestore.collection('users').doc(userDoc.id).delete();

      // Cerrar sesión del nuevo usuario
      await _auth.signOut();

      // Restaurar la sesión del admin
      if (currentAdmin != null) {
        await _auth.signInWithEmailAndPassword(
          email: currentAdmin.email!,
          password: 'Liam1234#',
        );
      }

      return true;
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            throw 'La contraseña debe tener al menos 6 caracteres';
          case 'email-already-in-use':
            throw 'Ya existe una cuenta con este correo electrónico';
          default:
            throw e.message ?? 'Error al cambiar contraseña';
        }
      }
      return false;
    }
  }

  // Inhabilitar/Habilitar usuario
  Future<bool> toggleUserStatus(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': isBlocked,
      });
      return true;
    } catch (e) {
      print('Error al cambiar estado del usuario: $e');
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(String userId) async {
    try {
      // Guardar el admin actual para restaurar la sesión después
      User? currentAdmin = _auth.currentUser;
      String adminEmail = currentAdmin?.email ?? '';

      // Obtener datos del usuario a eliminar
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw 'Usuario no encontrado';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Eliminar documento de Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Intentar eliminar el usuario de Firebase Auth
      try {
        // Iniciar sesión como el usuario a eliminar
        await _auth.signInWithEmailAndPassword(
          email: userData['email'],
          password: 'temporal123', // Esto fallará, pero es esperado
        );
      } catch (signInError) {
        print(
            'Error esperado al intentar iniciar sesión como usuario a eliminar: $signInError');
      }

      // Intentar eliminar la cuenta de Firebase Auth
      try {
        List<String> providers = await Future.value(
            (await _auth.fetchSignInMethodsForEmail(userData['email'])));
        if (providers.isNotEmpty) {
          // El usuario existe en Firebase Auth, intentar eliminarlo
          User? userToDelete = _auth.currentUser;
          if (userToDelete != null) {
            await userToDelete.delete();
          }
        }
      } catch (authError) {
        print(
            'Error al intentar eliminar usuario de Firebase Auth: $authError');
      }

      // Restaurar la sesión del admin
      if (adminEmail.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: 'Liam1234#',
        );
      }

      return true;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }

  // Obtener lista de usuarios
  Future<List<app_user.User>> getUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      return snapshot.docs
          .map((doc) => app_user.User.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  // Obtener usuario por ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return app_user.User.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por ID: $e');
      return null;
    }
  }

  // Obtener lista de técnicos (usuarios no admin)
  Stream<List<app_user.User>> getTechnicians() {
    return _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_user.User.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Obtener todos los técnicos (método Future para la pantalla de pagos)
  Future<List<app_user.User>> getAllTechnicians() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => app_user.User.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error al obtener técnicos: $e');
      return [];
    }
  }
}

const admin = require('firebase-admin');
const serviceAccount = require('../service-account-key.json');

// Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

async function setupAdmin() {
  try {
    // Crear usuario en Authentication
    const userRecord = await auth.createUser({
      email: 'josedavidlobo4@gmail.com',
      password: 'Liam1234#',
      emailVerified: true,
    });

    // Crear documento del usuario en Firestore
    await db.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      username: 'admin',
      name: 'Administrador',
      email: 'josedavidlobo4@gmail.com',
      isAdmin: true,
      isBlocked: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
      totalEarnings: 0,
      completedServices: 0,
    });

    console.log('Usuario administrador creado exitosamente:', userRecord.uid);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('El usuario ya existe, actualizando permisos...');
      
      // Obtener el usuario existente
      const userRecord = await auth.getUserByEmail('josedavidlobo4@gmail.com');
      
      // Actualizar documento en Firestore
      await db.collection('users').doc(userRecord.uid).set({
        id: userRecord.uid,
        username: 'admin',
        name: 'Administrador',
        email: 'josedavidlobo4@gmail.com',
        isAdmin: true,
        isBlocked: false,
        lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
        totalEarnings: 0,
        completedServices: 0,
      }, { merge: true });

      console.log('Permisos de administrador actualizados:', userRecord.uid);
    } else {
      console.error('Error al crear usuario administrador:', error);
    }
  }
}

setupAdmin()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error en la ejecución:', error);
    process.exit(1);
  });

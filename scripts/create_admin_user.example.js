const admin = require('firebase-admin');

// Obtener la configuración del archivo google-services.json
const serviceAccount = require('../android/app/google-services.json');

// Inicializar Firebase Admin SDK con la configuración del archivo
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: serviceAccount.project_info.project_id,
    clientEmail: serviceAccount.client[0].client_info.client_email,
    privateKey: serviceAccount.client[0].client_info.mobilesdk_app_id
  }),
  projectId: serviceAccount.project_info.project_id
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createAdminUser() {
  try {
    // Crear usuario en Firebase Auth
    const userRecord = await auth.createUser({
      uid: 'YOUR-ADMIN-UID',
      email: 'admin@example.com',
      password: 'YOUR-SECURE-PASSWORD',
      displayName: 'Administrador'
    });

    console.log('Usuario creado exitosamente:', userRecord.uid);

    // Crear documento en Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      username: 'admin',
      name: 'Administrador',
      email: 'admin@example.com',
      isAdmin: true,
      isBlocked: false,
      lastPaymentDate: new Date().toISOString(),
      totalEarnings: 0,
      completedServices: 0
    });

    console.log('Documento de usuario creado en Firestore');
    console.log('Usuario administrador configurado exitosamente');

  } catch (error) {
    if (error.code === 'auth/uid-already-exists') {
      console.log('El usuario ya existe, actualizando información...');
      
      // Actualizar usuario existente
      await auth.updateUser('YOUR-ADMIN-UID', {
        email: 'admin@example.com',
        password: 'YOUR-SECURE-PASSWORD',
        displayName: 'Administrador'
      });

      // Actualizar documento en Firestore
      await firestore.collection('users').doc('YOUR-ADMIN-UID').set({
        id: 'YOUR-ADMIN-UID',
        username: 'admin',
        name: 'Administrador',
        email: 'admin@example.com',
        isAdmin: true,
        isBlocked: false,
        lastPaymentDate: new Date().toISOString(),
        totalEarnings: 0,
        completedServices: 0
      }, { merge: true });

      console.log('Usuario administrador actualizado exitosamente');
    } else {
      console.error('Error al crear usuario administrador:', error);
    }
  }

  process.exit(0);
}

createAdminUser();

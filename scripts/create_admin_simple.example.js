const admin = require('firebase-admin');

// Obtener la configuración del archivo google-services.json
const serviceAccount = require('../android/app/google-services.json');

// Inicializar Firebase Admin SDK con la configuración del archivo
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: 'YOUR-PROJECT-ID',
    clientEmail: 'YOUR-CLIENT-EMAIL',
    privateKey: 'YOUR-PRIVATE-KEY'
  }),
  projectId: 'YOUR-PROJECT-ID'
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
    console.error('Error al crear usuario administrador:', error);
  }

  process.exit(0);
}

createAdminUser();

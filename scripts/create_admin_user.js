const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK con configuración manual
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'tech-service-app-e9ade'
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createAdminUser() {
  try {
    // Crear usuario en Firebase Auth
    const userRecord = await auth.createUser({
      uid: 'AxuMwpT71pM49Uv8gOjoOHPgNbW2',
      email: 'josedavidlobo4@gmail.com',
      password: 'Liam1234#',
      displayName: 'Administrador'
    });

    console.log('Usuario creado exitosamente:', userRecord.uid);

    // Crear documento en Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      username: 'admin',
      name: 'Administrador',
      email: 'josedavidlobo4@gmail.com',
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
      await auth.updateUser('AxuMwpT71pM49Uv8gOjoOHPgNbW2', {
        email: 'josedavidlobo4@gmail.com',
        password: 'Liam1234#',
        displayName: 'Administrador'
      });

      // Actualizar documento en Firestore
      await firestore.collection('users').doc('AxuMwpT71pM49Uv8gOjoOHPgNbW2').set({
        id: 'AxuMwpT71pM49Uv8gOjoOHPgNbW2',
        username: 'admin',
        name: 'Administrador',
        email: 'josedavidlobo4@gmail.com',
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

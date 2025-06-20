const admin = require('firebase-admin');

// Configuración simplificada para crear el usuario admin
const serviceAccount = {
  "type": "service_account",
  "project_id": "tech-service-app-e9ade",
  "private_key_id": "dummy",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKB\nxIuOAiNQM4+ur5yFjEp6z6FGF/zco2Sif1xYloBCOjM2oD8EGnwlkY+x+7LCcnqD\nQPIH1/givGnzagtHiO8Oekn5rAoFXybpSQUvwz4SfKBXRw5K+Ixf5p2VXpZXgcCx\nkS+YqzJdcEcTO0qRTwVxWQXuuSiQfKQJOtTvHI0D+6xBmyEpMPiGqvn4lwXBBSWz\n40aDskAcAFjuMy9AgMBAAECggEBALc2lQACC7cGdVAoXvzOKiEn2xJRSDC46bGZ\nRFXgjyMla5Q+gQdpUBQoQzSgLIe6WZLgSAcMzaXebvwlwI+mG2Q+Zx+bx8CpVB7y\nOtIjyWbEQcGUBYmMl2fVKAAGdmIgqkCEzCQF0+ZWnuZ+mlBiigHzggggWQKBgQDv\nT0yin69jzj5W4WBXROg0Q0yDwN2Q+k1xELoupfplXkydscQNBwCSBCHrNZ28LGOC\nG3Xt+SWn+7x+JqeRBdTfBHVaQjNpdsKz7QHaVIjzxyOQC/kxkVo+fxK8V+/+lV6V\nwQKBgQDMwgt2BZQs4WOwbSMe9VhPFpb4VlcCZ4R8SW+WaqU+HWvQchEfQMYR\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-qqw8h@tech-service-app-e9ade.iam.gserviceaccount.com",
  "client_id": "dummy",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
};

// Intentar inicializar con credenciales mínimas
try {
  admin.initializeApp({
    projectId: 'tech-service-app-e9ade'
  });
} catch (error) {
  console.log('Error al inicializar Firebase Admin:', error.message);
  console.log('Necesitas configurar las credenciales de Firebase Admin SDK');
  console.log('Por favor, ve a la consola de Firebase y descarga el archivo de credenciales de servicio');
  process.exit(1);
}

const auth = admin.auth();
const firestore = admin.firestore();

async function createAdminUser() {
  try {
    console.log('Intentando crear usuario administrador...');
    
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
      
      try {
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
      } catch (updateError) {
        console.error('Error al actualizar usuario:', updateError);
      }
    } else {
      console.error('Error al crear usuario administrador:', error);
      console.log('Código de error:', error.code);
      console.log('Mensaje:', error.message);
    }
  }

  process.exit(0);
}

createAdminUser();

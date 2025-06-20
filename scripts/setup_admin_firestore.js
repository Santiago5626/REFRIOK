const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
const serviceAccount = {
  "type": "service_account",
  "project_id": "tech-service-app-e9ade",
  "private_key_id": "dummy",
  "private_key": "-----BEGIN PRIVATE KEY-----\nDUMMY_KEY\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk@tech-service-app-e9ade.iam.gserviceaccount.com",
  "client_id": "dummy",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
};

// Usar el emulador de Firestore para desarrollo
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'tech-service-app-e9ade'
});

const db = admin.firestore();

async function setupAdminInFirestore() {
  try {
    console.log('Configurando usuario admin en Firestore...');
    
    // UID del usuario admin que acabamos de crear
    const adminUID = 'mjSQpd4SYchjb66snu1lY41OoHn2';
    
    // Crear documento del admin en Firestore
    await db.collection('users').doc(adminUID).set({
      id: adminUID,
      username: 'admin',
      name: 'Administrador',
      email: 'josedavidlobo4@gmail.com',
      isAdmin: true,
      isBlocked: false,
      lastPaymentDate: new Date().toISOString(),
      totalEarnings: 0,
      completedServices: 0,
      createdAt: new Date().toISOString(),
    });
    
    console.log('✅ Usuario admin configurado en Firestore exitosamente!');
    
  } catch (error) {
    console.error('❌ Error al configurar admin en Firestore:', error);
  }
}

setupAdminInFirestore()
  .then(() => {
    console.log('Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en la ejecución:', error);
    process.exit(1);
  });

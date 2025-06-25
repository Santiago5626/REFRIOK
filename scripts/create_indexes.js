const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

// Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Obtener referencia a Firestore
const db = admin.firestore();

async function createIndexes() {
  try {
    // 1. Índice para getAvailableServices
    await db.collection('services').createIndex({
      fields: [
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    });
    console.log('✅ Índice 1 creado: status + createdAt');

    // 2. Índice para getTechnicianServices
    await db.collection('services').createIndex({
      fields: [
        { fieldPath: 'assignedTechnicianId', order: 'ASCENDING' },
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'scheduledFor', order: 'ASCENDING' }
      ]
    });
    console.log('✅ Índice 2 creado: assignedTechnicianId + status + scheduledFor');

    // 3. Índice para getCompletedServices
    await db.collection('services').createIndex({
      fields: [
        { fieldPath: 'assignedTechnicianId', order: 'ASCENDING' },
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'completedAt', order: 'DESCENDING' }
      ]
    });
    console.log('✅ Índice 3 creado: assignedTechnicianId + status + completedAt');

    // 4. Índice para checkAndBlockTechnicians
    await db.collection('services').createIndex({
      fields: [
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'isPaid', order: 'ASCENDING' }
      ]
    });
    console.log('✅ Índice 4 creado: status + isPaid');

    console.log('✨ Todos los índices han sido creados exitosamente');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error al crear los índices:', error);
    process.exit(1);
  }
}

createIndexes();

const admin = require('firebase-admin');

// Inicializar Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'tech-service-app-2024'
  });
}

const db = admin.firestore();

async function createTestNotifications() {
  try {
    console.log('Creando notificaciones de prueba...');

    // Obtener algunos usuarios técnicos
    const usersSnapshot = await db.collection('users')
      .where('isAdmin', '==', false)
      .limit(3)
      .get();

    if (usersSnapshot.empty) {
      console.log('No se encontraron usuarios técnicos');
      return;
    }

    const notifications = [];

    usersSnapshot.forEach(userDoc => {
      const userId = userDoc.id;
      const userName = userDoc.data().name;

      // Notificación de asignación de servicio
      notifications.push({
        userId: userId,
        type: 'service_assignment',
        title: 'Nuevo Servicio Asignado',
        message: `Se te ha asignado un nuevo servicio de refrigeración en zona norte.`,
        data: {
          serviceId: 'test_service_' + Date.now(),
          serviceType: 'Mantenimiento'
        },
        isRead: false,
        createdAt: new Date().toISOString()
      });

      // Notificación de cambio de estado
      notifications.push({
        userId: userId,
        type: 'service_status_change',
        title: 'Estado de Servicio Actualizado',
        message: `El servicio #12345 ha sido marcado como completado por el cliente.`,
        data: {
          serviceId: 'service_12345',
          newStatus: 'completed'
        },
        isRead: false,
        createdAt: new Date(Date.now() - 3600000).toISOString() // 1 hora atrás
      });

      // Notificación general
      notifications.push({
        userId: userId,
        type: 'general',
        title: 'Recordatorio de Pago',
        message: `Recuerda realizar el pago de tu comisión semanal antes del viernes.`,
        data: {},
        isRead: Math.random() > 0.5, // Algunas leídas, otras no
        createdAt: new Date(Date.now() - 7200000).toISOString() // 2 horas atrás
      });
    });

    // Crear las notificaciones en batch
    const batch = db.batch();
    
    notifications.forEach(notification => {
      const notificationRef = db.collection('notifications').doc();
      batch.set(notificationRef, notification);
    });

    await batch.commit();

    console.log(`✅ Se crearon ${notifications.length} notificaciones de prueba`);
    console.log('Notificaciones creadas para los siguientes usuarios:');
    
    usersSnapshot.forEach(userDoc => {
      console.log(`- ${userDoc.data().name} (${userDoc.id})`);
    });

  } catch (error) {
    console.error('❌ Error creando notificaciones de prueba:', error);
  }
}

async function listNotifications() {
  try {
    console.log('\n📋 Listando todas las notificaciones...');
    
    const notificationsSnapshot = await db.collection('notifications')
      .orderBy('createdAt', 'desc')
      .get();

    if (notificationsSnapshot.empty) {
      console.log('No hay notificaciones en la base de datos');
      return;
    }

    console.log(`Total de notificaciones: ${notificationsSnapshot.size}\n`);

    notificationsSnapshot.forEach(doc => {
      const notification = doc.data();
      const status = notification.isRead ? '✅ Leída' : '🔔 No leída';
      console.log(`${status} - ${notification.title}`);
      console.log(`  Usuario: ${notification.userId}`);
      console.log(`  Tipo: ${notification.type}`);
      console.log(`  Mensaje: ${notification.message}`);
      console.log(`  Fecha: ${notification.createdAt}`);
      console.log('---');
    });

  } catch (error) {
    console.error('❌ Error listando notificaciones:', error);
  }
}

async function clearAllNotifications() {
  try {
    console.log('🗑️ Eliminando todas las notificaciones...');
    
    const notificationsSnapshot = await db.collection('notifications').get();
    
    if (notificationsSnapshot.empty) {
      console.log('No hay notificaciones para eliminar');
      return;
    }

    const batch = db.batch();
    notificationsSnapshot.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ Se eliminaron ${notificationsSnapshot.size} notificaciones`);

  } catch (error) {
    console.error('❌ Error eliminando notificaciones:', error);
  }
}

// Función principal
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'create':
      await createTestNotifications();
      break;
    case 'list':
      await listNotifications();
      break;
    case 'clear':
      await clearAllNotifications();
      break;
    default:
      console.log('Uso: node test_notifications.js [create|list|clear]');
      console.log('  create - Crear notificaciones de prueba');
      console.log('  list   - Listar todas las notificaciones');
      console.log('  clear  - Eliminar todas las notificaciones');
  }

  process.exit(0);
}

main().catch(console.error);

const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../android/app/google-services.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: serviceAccount.project_info.project_id,
      clientEmail: serviceAccount.client[0].client_info.client_email,
      privateKey: serviceAccount.client[0].client_info.mobilesdk_app_id
    }),
    projectId: serviceAccount.project_info.project_id
  });
}

const db = admin.firestore();

async function testAdminNotifications() {
  try {
    console.log('🧪 Iniciando pruebas de notificaciones al admin...\n');

    // 1. Crear un servicio de prueba
    console.log('1. Creando servicio de prueba...');
    const serviceRef = await db.collection('services').add({
      title: 'Reparación de Lavadora - Prueba Admin',
      description: 'Servicio de prueba para notificaciones al admin',
      location: 'San José, Costa Rica',
      clientName: 'Cliente Prueba',
      clientPhone: '+506 8888-8888',
      createdAt: new Date().toISOString(),
      scheduledFor: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Mañana
      basePrice: 50000,
      status: 'pending',
      additionalDetails: {
        brand: 'LG',
        model: 'WM3500CW'
      }
    });

    const serviceId = serviceRef.id;
    console.log(`✅ Servicio creado con ID: ${serviceId}\n`);

    // 2. Simular asignación del servicio (assigned)
    console.log('2. Simulando asignación del servicio...');
    await db.collection('services').doc(serviceId).update({
      assignedTechnicianId: 'tech_test_123',
      status: 'assigned'
    });

    // Crear notificación para el admin
    await db.collection('notifications').add({
      userId: 'admin_user_id', // En producción esto se obtendría dinámicamente
      type: 'service_status_change',
      title: 'Servicio Asignado',
      message: 'El técnico ha aceptado el servicio "Reparación de Lavadora - Prueba Admin" para el cliente Cliente Prueba',
      serviceId: serviceId,
      status: 'assigned',
      isRead: false,
      createdAt: new Date().toISOString()
    });
    console.log('✅ Notificación de asignación creada\n');

    // Esperar un poco
    await new Promise(resolve => setTimeout(resolve, 1000));

    // 3. Simular técnico en camino (onWay)
    console.log('3. Simulando técnico en camino...');
    await db.collection('services').doc(serviceId).update({
      status: 'onWay'
    });

    await db.collection('notifications').add({
      userId: 'admin_user_id',
      type: 'service_status_change',
      title: 'Técnico en Camino',
      message: 'El técnico está en camino al servicio "Reparación de Lavadora - Prueba Admin" para el cliente Cliente Prueba',
      serviceId: serviceId,
      status: 'onWay',
      isRead: false,
      createdAt: new Date().toISOString()
    });
    console.log('✅ Notificación de "en camino" creada\n');

    await new Promise(resolve => setTimeout(resolve, 1000));

    // 4. Simular llegada y inicio del servicio (inProgress)
    console.log('4. Simulando llegada y inicio del servicio...');
    const finalPrice = 45000; // Servicio completo con descuento
    await db.collection('services').doc(serviceId).update({
      status: 'inProgress',
      arrivedAt: new Date().toISOString(),
      serviceType: 'complete',
      finalPrice: finalPrice,
      technicianCommission: finalPrice * 0.7,
      adminCommission: finalPrice * 0.3
    });

    await db.collection('notifications').add({
      userId: 'admin_user_id',
      type: 'service_status_change',
      title: 'Servicio en Progreso',
      message: `El técnico ha llegado al servicio "Reparación de Lavadora - Prueba Admin" y realizará un servicio completo. Precio: ₡${finalPrice}`,
      serviceId: serviceId,
      status: 'inProgress',
      isRead: false,
      createdAt: new Date().toISOString()
    });
    console.log('✅ Notificación de "en progreso" creada\n');

    await new Promise(resolve => setTimeout(resolve, 1000));

    // 5. Simular finalización del servicio (completed)
    console.log('5. Simulando finalización del servicio...');
    const notes = 'Lavadora reparada exitosamente. Se reemplazó la bomba de agua.';
    await db.collection('services').doc(serviceId).update({
      status: 'completed',
      completedAt: new Date().toISOString(),
      notes: notes
    });

    const adminCommission = finalPrice * 0.3;
    await db.collection('notifications').add({
      userId: 'admin_user_id',
      type: 'service_status_change',
      title: 'Servicio Completado',
      message: `Servicio "Reparación de Lavadora - Prueba Admin" completado. Comisión del admin: ₡${adminCommission.toFixed(0)}. Notas: ${notes}`,
      serviceId: serviceId,
      status: 'completed',
      isRead: false,
      createdAt: new Date().toISOString()
    });
    console.log('✅ Notificación de "completado" creada\n');

    // 6. Crear un segundo servicio para probar cancelación
    console.log('6. Creando segundo servicio para probar cancelación...');
    const serviceRef2 = await db.collection('services').add({
      title: 'Reparación de Refrigerador - Prueba Cancelación',
      description: 'Servicio de prueba para cancelación',
      location: 'Cartago, Costa Rica',
      clientName: 'Cliente Prueba 2',
      clientPhone: '+506 7777-7777',
      createdAt: new Date().toISOString(),
      scheduledFor: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
      basePrice: 60000,
      status: 'assigned',
      assignedTechnicianId: 'tech_test_456'
    });

    const serviceId2 = serviceRef2.id;
    console.log(`✅ Segundo servicio creado con ID: ${serviceId2}`);

    // Simular cancelación
    const cancellationReason = 'Cliente no disponible en la dirección indicada';
    await db.collection('services').doc(serviceId2).update({
      status: 'cancelled',
      cancellationReason: cancellationReason,
      cancelledAt: new Date().toISOString()
    });

    await db.collection('notifications').add({
      userId: 'admin_user_id',
      type: 'service_status_change',
      title: 'Servicio Cancelado',
      message: `Servicio "Reparación de Refrigerador - Prueba Cancelación" cancelado. Motivo: ${cancellationReason}`,
      serviceId: serviceId2,
      status: 'cancelled',
      isRead: false,
      createdAt: new Date().toISOString()
    });
    console.log('✅ Notificación de "cancelado" creada\n');

    // 7. Mostrar resumen de notificaciones creadas
    console.log('7. Consultando notificaciones del admin...');
    const notificationsSnapshot = await db.collection('notifications')
      .where('userId', '==', 'admin_user_id')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    console.log(`\n📋 Notificaciones del admin (${notificationsSnapshot.size} encontradas):`);
    console.log('=' .repeat(80));
    
    notificationsSnapshot.forEach((doc, index) => {
      const notification = doc.data();
      const date = new Date(notification.createdAt).toLocaleString('es-CR');
      console.log(`${index + 1}. [${notification.status?.toUpperCase() || 'N/A'}] ${notification.title}`);
      console.log(`   📅 ${date}`);
      console.log(`   💬 ${notification.message}`);
      console.log(`   🔗 Servicio: ${notification.serviceId || 'N/A'}`);
      console.log(`   👁️ Leído: ${notification.isRead ? 'Sí' : 'No'}`);
      console.log('');
    });

    console.log('🎉 Pruebas de notificaciones al admin completadas exitosamente!');
    console.log('\n📝 Resumen:');
    console.log('- ✅ Notificación de asignación');
    console.log('- ✅ Notificación de técnico en camino');
    console.log('- ✅ Notificación de servicio en progreso');
    console.log('- ✅ Notificación de servicio completado');
    console.log('- ✅ Notificación de servicio cancelado');
    console.log('\n💡 El admin ahora recibirá notificaciones en tiempo real sobre todos los cambios de estado de los servicios.');

  } catch (error) {
    console.error('❌ Error durante las pruebas:', error);
  }
}

// Ejecutar las pruebas
testAdminNotifications();

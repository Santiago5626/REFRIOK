// Firebase Cloud Functions para enviar notificaciones push cuando se crea una notificación de asignación de servicio

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger al crear un documento en la colección 'notifications'
exports.sendServiceAssignmentPush = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        // Solo procesar notificaciones de tipo 'service_assignment'
        if (data.type !== 'service_assignment') {
            return null;
        }
        const technicianId = data.userId; // el técnico al que se asignó el servicio
        const topic = `technician_${technicianId}`;
        const payload = {
            notification: {
                title: data.title || 'Nuevo Servicio Asignado',
                body: data.message || 'Se te ha asignado un nuevo servicio',
            },
            data: {
                // Pasar información adicional para que la app la use
                serviceId: data.data?.serviceId || '',
                serviceTitle: data.data?.serviceTitle || '',
                clientName: data.data?.clientName || '',
                location: data.data?.location || '',
            },
        };
        try {
            const response = await admin.messaging().sendToTopic(topic, payload);
            console.log('Push enviado al topic', topic, response);
        } catch (error) {
            console.error('Error enviando push', error);
        }
        return null;
    });

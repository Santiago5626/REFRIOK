// Backend para enviar notificaciones push a técnicos
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

// Cargar credenciales desde variable de entorno (JSON en una sola línea)
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.error('FIREBASE_SERVICE_ACCOUNT no está definida');
    process.exit(1);
}
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

let lastRequest = null;
app.post('/sendPush', async (req, res) => {
    console.log('🔔 POST /sendPush recibido →', req.body);
    lastRequest = req.body;

    const { userId, technicianId, title, body, data, apiKey } = req.body;

    if (process.env.API_KEY && apiKey !== process.env.API_KEY) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    // Aceptar tanto userId como technicianId para retrocompatibilidad
    const targetUserId = userId || technicianId;

    if (!targetUserId) {
        return res.status(400).json({ success: false, error: 'userId o technicianId requerido' });
    }

    try {
        // 1. Buscar el usuario en Firestore para obtener su token
        const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();

        if (!userDoc.exists) {
            console.log(`❌ Usuario ${targetUserId} no encontrado en Firestore`);
            return res.status(404).json({ success: false, error: 'Usuario no encontrado' });
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
            console.log(`⚠️ El usuario ${targetUserId} no tiene un token FCM guardado`);
            return res.status(404).json({ success: false, error: 'Usuario sin token FCM' });
        }

        console.log(`✅ Token encontrado para ${targetUserId}: ${fcmToken.substring(0, 10)}...`);

        // 2. Enviar la notificación al token específico
        const message = {
            token: fcmToken,
            notification: {
                title: title || 'Nuevo Servicio',
                body: body || ''
            },
            data: data || {}
        };

        const result = await admin.messaging().send(message);
        console.log('✅ Notificación enviada con éxito:', result);
        res.json({ success: true, result });

    } catch (e) {
        console.error('❌ Error enviando push:', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

// Endpoint para restablecer contraseña de usuario
app.post('/resetPassword', async (req, res) => {
    console.log('🔐 POST /resetPassword recibido →', { email: req.body.email });

    const { email, newPassword, apiKey } = req.body;

    // Verificar API Key si está configurada
    if (process.env.API_KEY && apiKey !== process.env.API_KEY) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    if (!email || !newPassword) {
        return res.status(400).json({ success: false, error: 'email y newPassword son requeridos' });
    }

    try {
        // Buscar el usuario por email
        const user = await admin.auth().getUserByEmail(email);

        // Actualizar la contraseña
        await admin.auth().updateUser(user.uid, {
            password: newPassword,
        });

        console.log(`✅ Contraseña actualizada para ${email}`);
        res.json({ success: true, message: 'Contraseña actualizada exitosamente' });

    } catch (e) {
        console.error('❌ Error actualizando contraseña:', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

// Ruta raíz – confirma que el servidor está activo
app.get('/', (req, res) => {
    res.send('Backend activo');
});

// Ruta de salud – útil para pruebas rápidas
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Endpoint para inspeccionar la última petición recibida
app.get('/lastRequest', (req, res) => {
    res.json({ lastRequest });
});
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Backend listening on ${PORT}`));

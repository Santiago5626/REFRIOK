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
    console.log('🔔 POST /sendPush recibido →', req.body);
    const { technicianId, title, body, data, apiKey } = req.body;
    // Opcional: proteger con una clave sencilla
    if (process.env.API_KEY && apiKey !== process.env.API_KEY) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    if (!technicianId) {
        return res.status(400).json({ success: false, error: 'technicianId requerido' });
    }
    const topic = `technician_${technicianId}`;
    const payload = {
        notification: { title: title || 'Nuevo Servicio', body: body || '' },
        data: data || {},
    };
    try {
        const result = await admin.messaging().sendToTopic(topic, payload);
        res.json({ success: true, result });
    } catch (e) {
        console.error('Error enviando push', e);
        res.status(500).json({ success: false, error: e.message });
    }
});

// Ruta raíz – confirma que el servidor está activo
app.get('/', (req, res) => {
    res.send('✅ Backend activo');
});

// Ruta de salud – útil para pruebas rápidas
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Endpoint para inspeccionar la última petición recibida
app.get('/lastRequest', (req, res) => {
    res.json({ lastRequest });
});
app.listen(PORT, () => console.log(`🚀 Backend listening on ${PORT}`));

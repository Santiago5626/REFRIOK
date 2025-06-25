# Instrucciones para Crear Índices de Firestore

## Estado Actual
✅ Firebase CLI instalado
✅ Archivos de configuración creados
🔄 Proceso de login en curso

## Pasos para Completar

### 1. Completar Login de Firebase
- El comando `npx firebase login` está ejecutándose
- Se abrirá tu navegador para autenticarte con Google
- Autoriza el acceso a Firebase CLI

### 2. Inicializar Proyecto (si es necesario)
```bash
npx firebase init firestore
```
- Selecciona tu proyecto REFRIOK
- Usa los archivos existentes cuando pregunte

### 3. Desplegar Índices
```bash
npx firebase deploy --only firestore:indexes
```

### 4. Desplegar Reglas (opcional)
```bash
npx firebase deploy --only firestore:rules
```

## Índices que se Crearán

1. **services** (status + createdAt)
   - Para: `getAvailableServices()` - Servicios pendientes ordenados por fecha

2. **services** (assignedTechnicianId + status + scheduledFor)
   - Para: `getTechnicianServices()` - Servicios asignados a técnico específico

3. **services** (assignedTechnicianId + status + completedAt)
   - Para: `getCompletedServices()` - Historial de servicios completados

4. **services** (status + isPaid)
   - Para: `checkAndBlockTechnicians()` - Servicios completados no pagados

5. **users** (isAdmin)
   - Para consultas de administradores

## Verificación

Después del despliegue:
1. Ve a Firebase Console > Firestore > Índices
2. Verifica que todos los índices aparezcan como "Creando" o "Activo"
3. Los índices pueden tardar unos minutos en estar completamente disponibles

## Solución de Problemas

Si hay errores:
- Asegúrate de estar en el directorio correcto (donde está firebase.json)
- Verifica que tengas permisos de administrador en el proyecto Firebase
- Si el proyecto no está inicializado, ejecuta `npx firebase init`

## Archivos Creados

- `firestore.indexes.json` - Definición de índices
- `firestore.rules` - Reglas de seguridad
- `firebase.json` - Configuración del proyecto
- `deploy-firestore.bat` - Script alternativo para Windows

Una vez completado, todas las funciones del panel de administración deberían funcionar correctamente.

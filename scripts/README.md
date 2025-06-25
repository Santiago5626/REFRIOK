# Script para Crear Índices de Firestore

Este script crea automáticamente todos los índices necesarios para las consultas de la aplicación REFRIOK.

## Configuración

### 1. Obtener el archivo de credenciales de Firebase

1. Ve a la [Consola de Firebase](https://console.firebase.google.com/)
2. Selecciona tu proyecto REFRIOK
3. Ve a **Configuración del Proyecto** (ícono de engranaje)
4. Pestaña **Cuentas de servicio**
5. Haz clic en **Generar nueva clave privada**
6. Descarga el archivo JSON y guárdalo como `service-account-key.json` en la carpeta `scripts/`

### 2. Instalar dependencias

```bash
cd scripts
npm install
```

### 3. Ejecutar el script

```bash
npm run create-indexes
```

## Índices que se crean

El script crea los siguientes índices compuestos:

1. **services**: `status` (ASC) + `createdAt` (DESC)
   - Para: Obtener servicios pendientes ordenados por fecha

2. **services**: `assignedTechnicianId` (ASC) + `status` (ASC) + `scheduledFor` (ASC)
   - Para: Obtener servicios asignados a un técnico específico

3. **services**: `assignedTechnicianId` (ASC) + `status` (ASC) + `completedAt` (DESC)
   - Para: Obtener historial de servicios completados por técnico

4. **services**: `status` (ASC) + `isPaid` (ASC)
   - Para: Verificar servicios completados no pagados

## Estructura de archivos

```
scripts/
├── create_indexes.js          # Script principal
├── package.json              # Dependencias de Node.js
├── service-account-key.json  # Credenciales de Firebase (no incluido en git)
└── README.md                 # Este archivo
```

## Notas importantes

- El archivo `service-account-key.json` contiene credenciales sensibles y NO debe subirse a git
- Los índices pueden tardar unos minutos en estar completamente disponibles
- Si ya existen algunos índices, el script los omitirá automáticamente

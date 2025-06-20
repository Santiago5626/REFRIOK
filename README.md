# Tech Service App

Una aplicación Flutter para la gestión de servicios técnicos con Firebase como backend.

## Características

### 🔐 Sistema de Autenticación
- Login seguro con Firebase Auth
- Gestión de usuarios con roles (Admin/Técnico)
- Sistema de bloqueo automático por falta de pago
- Restablecimiento de contraseñas

### 👨‍💼 Panel de Administración
- **Gestión de Servicios**: Ver, crear y administrar servicios técnicos
- **Gestión de Usuarios**: Crear, bloquear, desbloquear y eliminar usuarios
- **Control de Pagos**: Registro de pagos y desbloqueo de usuarios

### 🛠️ Gestión de Servicios
- Creación de servicios con información detallada del cliente
- Estados de servicio: Pendiente, Asignado, En Camino, En Progreso, Completado, Cancelado
- Cálculo automático de precios y comisiones
- Programación de servicios con fecha y hora

### 💰 Sistema de Pagos y Comisiones
- Cálculo automático de comisiones para administradores
- Seguimiento de ganancias totales por técnico
- Control de pagos diarios para evitar bloqueos

## Configuración

### Credenciales de Administrador
- **Email**: josedavidlobo4@gmail.com
- **Contraseña**: Liam1234#

### Firebase Configuration
La aplicación está configurada con el proyecto Firebase:
- **Project ID**: tech-service-app-e9ade
- **App ID**: 1:557548135367:web:641d2d1e48a036d99fafe2

## Instalación y Ejecución

### Prerrequisitos
- Flutter SDK (versión 3.0 o superior)
- Dart SDK
- Navegador web moderno (Chrome, Edge, Firefox)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd tech_service_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome
   ```
   o para Edge:
   ```bash
   flutter run -d edge
   ```

## Uso de la Aplicación

### Primer Acceso (Administrador)
1. Abrir la aplicación en el navegador
2. Usar las credenciales de administrador:
   - Email: `josedavidlobo4@gmail.com`
   - Contraseña: `Liam1234#`
3. El sistema creará automáticamente la cuenta de administrador en el primer login

### Panel de Administración
El panel tiene tres secciones principales:

#### 📋 Servicios
- Ver todos los servicios creados
- Información detallada de cada servicio
- Estados y progreso de los servicios

#### ➕ Crear Servicio
- Formulario completo para crear nuevos servicios
- Campos: título, descripción, ubicación, cliente, teléfono, precio, fecha/hora
- Validación de datos

#### 👥 Usuarios
- Lista de todos los usuarios del sistema
- Crear nuevos usuarios (técnicos o administradores)
- Bloquear/desbloquear usuarios
- Restablecer contraseñas
- Eliminar usuarios (excepto administradores)

### Gestión de Usuarios
- **Crear Usuario**: Botón "Crear Usuario" para agregar nuevos técnicos
- **Menú de Acciones**: Clic en los tres puntos para acceder a:
  - Restablecer contraseña
  - Bloquear/desbloquear usuario
  - Eliminar usuario

## Estructura del Proyecto

```
lib/
├── models/
│   ├── user.dart           # Modelo de usuario
│   └── service.dart        # Modelo de servicio
├── services/
│   ├── auth_service.dart   # Servicio de autenticación
│   └── service_management_service.dart # Gestión de servicios
├── screens/
│   ├── login_screen.dart   # Pantalla de login
│   ├── home_screen.dart    # Pantalla principal (técnicos)
│   ├── admin_panel.dart    # Panel de administración
│   └── profile_screen.dart # Perfil de usuario
└── main.dart              # Punto de entrada de la aplicación
```

## Funcionalidades Técnicas

### Firebase Integration
- **Authentication**: Manejo de usuarios y sesiones
- **Firestore**: Base de datos NoSQL para usuarios y servicios
- **Security Rules**: Reglas de seguridad configuradas

### Estado de la Aplicación
- Gestión de estado con StatefulWidget
- Streams para actualizaciones en tiempo real
- Validación de formularios

### Responsive Design
- Interfaz adaptable para diferentes tamaños de pantalla
- Material Design components
- Navegación intuitiva

## Reglas de Negocio

### Sistema de Bloqueo
- Los usuarios se bloquean automáticamente si no han pagado en las últimas 24 horas
- Los administradores nunca se bloquean
- El bloqueo se verifica en cada login

### Cálculo de Precios
- **Revisión**: Precio base
- **Servicio Completo**: Precio base × 1.5
- **Comisión Admin**: 20% del precio final

### Roles de Usuario
- **Administrador**: Acceso completo al panel de administración
- **Técnico**: Acceso a servicios asignados y perfil personal

## Troubleshooting

### Problemas Comunes

1. **Error de autenticación**
   - Verificar que las credenciales sean correctas
   - Asegurarse de que Firebase esté configurado correctamente

2. **No se cargan los datos**
   - Verificar conexión a internet
   - Revisar las reglas de Firestore

3. **Error al crear usuario administrador**
   - El sistema crea automáticamente el admin en el primer login
   - No es necesario configuración adicional

## Soporte

Para soporte técnico o preguntas sobre la aplicación, contactar al administrador del sistema.

---

**Desarrollado con Flutter y Firebase**

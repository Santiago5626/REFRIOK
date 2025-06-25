# REFRIOK - Sistema de Gestión de Servicios Técnicos

Aplicación web desarrollada con Flutter para la gestión de servicios técnicos de refrigeración, con Firebase como backend.

## 🌟 Características Principales

### Sistema de Usuarios
- Roles diferenciados (Administrador/Técnico)
- Gestión de perfiles y permisos
- Sistema de bloqueo automático
- Recuperación de contraseñas

### Gestión de Servicios
- Creación y seguimiento de servicios técnicos
- Estados del servicio (Pendiente, Asignado, En Camino, etc.)
- Asignación de técnicos
- Programación de fechas y horarios

### Panel Administrativo
- Gestión completa de usuarios
- Control de pagos y comisiones
- Reportes y estadísticas
- Administración de sedes

### Sistema de Pagos
- Cálculo automático de comisiones
- Seguimiento de pagos
- Control de ganancias por técnico
- Sistema de bloqueo por falta de pago

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK (3.0 o superior)
- Dart SDK
- Navegador web moderno
- Git
- Proyecto Firebase configurado

### Pasos de Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/santiago5626/REFRIOK.git
cd REFRIOK
```

2. Configurar Firebase:
```bash
# Copiar el archivo de ejemplo
cp lib/firebase_options.example.dart lib/firebase_options.dart

# Editar el archivo con tus credenciales de Firebase
# Reemplazar YOUR-API-KEY, YOUR-PROJECT-ID, etc. con los valores reales
```

3. Instalar dependencias:
```bash
flutter pub get
```

4. Ejecutar la aplicación:
```bash
flutter run -d chrome  # Para Chrome
flutter run -d edge    # Para Edge
```

### Configuración de Firebase

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilitar Authentication y Firestore
3. Configurar las reglas de seguridad de Firestore
4. Obtener las credenciales del proyecto y actualizar `lib/firebase_options.dart`

## 📱 Uso de la Aplicación

### Panel de Administración

#### Gestión de Servicios
- Crear y asignar servicios
- Seguimiento en tiempo real
- Historial completo

#### Gestión de Usuarios
- Alta y baja de técnicos
- Control de accesos
- Asignación a sedes

#### Control de Pagos
- Registro de pagos
- Cálculo de comisiones
- Control de bloqueos

### Panel de Técnicos
- Vista de servicios asignados
- Actualización de estados
- Historial personal
- Registro de ganancias

## 🏗️ Estructura del Proyecto

```
lib/
├── models/          # Modelos de datos
├── screens/         # Interfaces de usuario
├── services/        # Lógica de negocio
└── widgets/         # Componentes reutilizables
```

## 🔒 Seguridad

- Autenticación segura con Firebase
- Reglas de Firestore configuradas
- Protección de rutas
- Validación de permisos

## 💼 Reglas de Negocio

### Sistema de Comisiones
- 70% para técnicos
- 30% para administración

### Control de Pagos
- Verificación diaria de pagos
- Bloqueo automático a las 10 PM
- Sistema de desbloqueo manual

## 🛠️ Tecnologías Utilizadas

- Flutter Web
- Firebase Authentication
- Cloud Firestore
- Material Design

## 🤝 Contribución

1. Fork el proyecto
2. Cree su rama de características
3. Commit sus cambios
4. Push a la rama
5. Abra un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - vea el archivo [LICENSE](LICENSE) para más detalles.

## ✨ Agradecimientos

- Equipo de desarrollo
- Contribuidores
- Comunidad Flutter

---

**Desarrollado con ❤️ usando Flutter y Firebase**

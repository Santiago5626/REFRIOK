const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword } = require('firebase/auth');

// Configuración de Firebase (usando la misma del proyecto)
const firebaseConfig = {
  apiKey: 'AIzaSyAdUfoq0JA5OI7LSJWRXPsdYTVCsp-KNKo',
  authDomain: 'tech-service-app-e9ade.firebaseapp.com',
  projectId: 'tech-service-app-e9ade',
  storageBucket: 'tech-service-app-e9ade.firebasestorage.app',
  messagingSenderId: '557548135367',
  appId: '1:557548135367:web:641d2d1e48a036d99fafe2'
};

// Inicializar Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

async function createAdminUser() {
  try {
    console.log('Creando usuario administrador...');
    
    const userCredential = await createUserWithEmailAndPassword(
      auth,
      'josedavidlobo4@gmail.com',
      'Liam1234#'
    );
    
    console.log('Usuario administrador creado exitosamente:', userCredential.user.uid);
    console.log('Email:', userCredential.user.email);
    
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      console.log('El usuario ya existe en Firebase Auth');
    } else {
      console.error('Error al crear usuario administrador:', error.code, error.message);
    }
  }
}

createAdminUser()
  .then(() => {
    console.log('Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en la ejecución:', error);
    process.exit(1);
  });

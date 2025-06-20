const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword, deleteUser } = require('firebase/auth');

// Configuración de Firebase
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

async function verifyAdminLogin() {
  try {
    console.log('Verificando login del admin...');
    
    const userCredential = await signInWithEmailAndPassword(
      auth,
      'josedavidlobo4@gmail.com',
      'Liam1234#'
    );
    
    console.log('✅ Login exitoso!');
    console.log('UID:', userCredential.user.uid);
    console.log('Email:', userCredential.user.email);
    console.log('Email verificado:', userCredential.user.emailVerified);
    
    // Cerrar sesión
    await auth.signOut();
    console.log('Sesión cerrada');
    
  } catch (error) {
    console.error('❌ Error en login:', error.code, error.message);
    
    if (error.code === 'auth/user-not-found') {
      console.log('El usuario no existe en Firebase Auth');
    } else if (error.code === 'auth/wrong-password') {
      console.log('Contraseña incorrecta');
    } else if (error.code === 'auth/invalid-credential') {
      console.log('Credenciales inválidas - puede que el usuario no exista o la contraseña sea incorrecta');
    }
  }
}

verifyAdminLogin()
  .then(() => {
    console.log('Verificación completada');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en la verificación:', error);
    process.exit(1);
  });

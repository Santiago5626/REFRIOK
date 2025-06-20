const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, deleteUser } = require('firebase/auth');

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

async function resetAdminUser() {
  try {
    console.log('Intentando crear usuario administrador...');
    
    // Intentar crear el usuario directamente
    const userCredential = await createUserWithEmailAndPassword(
      auth,
      'josedavidlobo4@gmail.com',
      'Liam1234#'
    );
    
    console.log('✅ Usuario administrador creado exitosamente!');
    console.log('UID:', userCredential.user.uid);
    console.log('Email:', userCredential.user.email);
    
    // Verificar que podemos hacer login
    await auth.signOut();
    console.log('Probando login...');
    
    const loginCredential = await signInWithEmailAndPassword(
      auth,
      'josedavidlobo4@gmail.com',
      'Liam1234#'
    );
    
    console.log('✅ Login verificado exitosamente!');
    console.log('UID del login:', loginCredential.user.uid);
    
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      console.log('⚠️ El usuario ya existe. Intentando hacer login para verificar...');
      
      try {
        const loginCredential = await signInWithEmailAndPassword(
          auth,
          'josedavidlobo4@gmail.com',
          'Liam1234#'
        );
        
        console.log('✅ Login exitoso con usuario existente!');
        console.log('UID:', loginCredential.user.uid);
        
      } catch (loginError) {
        console.error('❌ Error en login con usuario existente:', loginError.code);
        console.log('El usuario existe pero la contraseña no coincide.');
        console.log('Esto sugiere que el usuario fue creado con una contraseña diferente.');
        
        // Sugerir solución manual
        console.log('\n🔧 SOLUCIÓN SUGERIDA:');
        console.log('1. Ve a Firebase Console > Authentication');
        console.log('2. Busca el usuario josedavidlobo4@gmail.com');
        console.log('3. Elimínalo manualmente');
        console.log('4. Ejecuta este script nuevamente');
      }
    } else {
      console.error('❌ Error inesperado:', error.code, error.message);
    }
  }
}

resetAdminUser()
  .then(() => {
    console.log('\nProceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en la ejecución:', error);
    process.exit(1);
  });

const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc } = require('firebase/firestore');

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
const db = getFirestore(app);

async function createAdminInFirestore() {
  try {
    console.log('Iniciando sesión como admin...');
    
    // Iniciar sesión como admin
    const userCredential = await signInWithEmailAndPassword(
      auth,
      'josedavidlobo4@gmail.com',
      'Liam1234#'
    );
    
    console.log('✅ Login exitoso! UID:', userCredential.user.uid);
    
    // Crear documento del admin en Firestore
    const adminData = {
      id: userCredential.user.uid,
      username: 'admin',
      name: 'Administrador',
      email: 'josedavidlobo4@gmail.com',
      isAdmin: true,
      isBlocked: false,
      lastPaymentDate: new Date().toISOString(),
      totalEarnings: 0,
      completedServices: 0,
      createdAt: new Date().toISOString(),
    };
    
    console.log('Creando documento en Firestore...');
    await setDoc(doc(db, 'users', userCredential.user.uid), adminData);
    
    console.log('✅ Usuario admin configurado en Firestore exitosamente!');
    console.log('Datos del admin:', adminData);
    
    // Cerrar sesión
    await auth.signOut();
    console.log('Sesión cerrada');
    
  } catch (error) {
    console.error('❌ Error:', error.code, error.message);
  }
}

createAdminInFirestore()
  .then(() => {
    console.log('Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en la ejecución:', error);
    process.exit(1);
  });

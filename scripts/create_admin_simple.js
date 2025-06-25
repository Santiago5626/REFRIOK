const admin = require('firebase-admin');

// Initialize Firebase Admin with the service account credentials
const serviceAccount = {
  "type": "service_account",
  "project_id": "tech-service-app-e9ade",
  "private_key_id": "d003e85a0fc51781c3e7cd332e362210a631544d",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC6vDpxp9NzSHXV\npnEAaeR52mdFvB8bOLz6nr/CQ/9q6caErOhxPelr16kPFAY2kJ/t3jrixyKGMwFd\nlCotDE84UN1zbwM7PSTH3ydNTQQhW3ggqtvMmaoe+FH+ueTcl3my15Wx426T75u3\n2nuroS73ya4xh+ublDJN6KXWme5pTUwu+z86yQu+QmWcdvSluRTaYWn/yr/FnJXI\ndqFItDS5/OgMYoOx1uNonZ7SNVttce3ijbCmeJykQI5QZhTe0UpDzs1jAPuJtamr\nn66wp3UzPLK9UftOXUMnTqzvzNG2J5xF8IUzY2Tbnf8UlJ9b/XJOIAPK2/xygP6u\n5ZFE6PChAgMBAAECggEAEsFuI1VGdTlNcJCfn/mC08RehBARlcPco1WHkCURRfVG\nFbRiQmGEDOtj1RpfR2K+VX9xLa7vpkgANpx3of+vA0qH+5ymV/BbveGJioeWRx1v\nUuSmYAX9ItAxOCMGvCtQs2hY5j2gMSarXsuIiWQOmh+9KcdroDxB0zZvVb8vRY8s\ncYX9CgBwEw3TvjYIh+cykZesWIFBlclzpgDj3skU8yyu5qzsFLv+dK6kI8Qg2rG8\nb2Yn6iME54UprZPUKg83ezKnmP0g6aenNM58L7b3wwB2MzRytas9iajFxBXk7d5G\nClRw7kKKZtfwxgZsC/blEgomwUvJdjEDifV2NuX9wwKBgQDrdPS1cpbmSeRJsGPj\n/s/74WheLF7kh46jXa8mfLqWP4a4JNijrR7awPJRq/nDcq/53893yCIx7XiDMSX0\nLM8sU0auHtyIIXmdqf4LUzR2PatdhvDdT4+RXIwxe62/r1Pv6nEnHTaaf53eUx9a\noVg1HxhONXteeAR4t0n9C3s/AwKBgQDLBw1DkJAuiTKUGAeuFdGbxWnVHmYxu/tq\n+x8lF/hOmxEMUx4yA5aPiqIcTkyufCABih58D46D+N/CXfs+Cv7ZOPX/RdNKBCBm\nmsHcD3KCvhm3Ow9aJ7gBNhsyDWdtMkeXaRwvctB+705pNgG9boTDfw8lPdoBXYD8\nn+2N8uk+iwKBgQCH9bH0MGXoNlTHJD6aAaJxbJhKgM6OoaQAu3EPBUjsx2PwYv5h\njO7bHD0QYgDIFip9W/o9zWfJcrl6799dnp5GlxOiKZnoVYQXQXi7a2FIwZV5XRkq\nge2B33HohOUwYXpTeAm8r0a/cd9j6JWbTL1Vd04eow1I4H6cgiIMJxwUpwKBgQC5\nPUbh1X1nqDAopMAlGq0zdew40dKmIAClvFfPTU510c+9Mf0D3vg5IWEFeH9IV+IP\n5Ygo4zzBtonZ2kvIcNnTMcBo17mO97LkSuEDumhdV7s4zb8VH9Yn7MjlYwtxuwVM\n5U8dD6GhnxAouGjgAH1LrZsQ/Jzyz/BHDlf9QpuDPwKBgBo55bgcJSMCqYohzUpJ\nAI0hiCD7VsAO0N38mYTQ4qEiJamu5Rv8OtWlW/6uLhI0M+lcmuFe2NzKXLZ07IKb\n+uWxClwYOodw1zVoBZrFF7OGxbWi/TIE1TA+9l1L51XmjWF8LVnaP/3NiYAmlpk9\nP5joGZMHzOWp6HB0ZDalbK+N\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@tech-service-app-e9ade.iam.gserviceaccount.com",
  "client_id": "115035903911983396271",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40tech-service-app-e9ade.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

// Initialize Firebase Admin with the service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createAdminUser() {
  try {
    console.log('Creando usuario administrador...');
    
    // Crear usuario en Firebase Auth
    const userRecord = await auth.createUser({
      email: 'josedavidlobo4@gmail.com',
      password: 'Liam1234#',
      displayName: 'Administrador'
    });

    console.log('Usuario creado exitosamente:', userRecord.uid);

    // Crear documento en Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      id: userRecord.uid,
      username: 'admin',
      name: 'Administrador',
      email: 'josedavidlobo4@gmail.com',
      isAdmin: true,
      isBlocked: false,
      lastPaymentDate: new Date().toISOString(),
      totalEarnings: 0,
      completedServices: 0,
      createdAt: new Date().toISOString()
    });

    console.log('Documento de usuario creado en Firestore');
    console.log('Usuario administrador configurado exitosamente');
    console.log('UID:', userRecord.uid);

  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('El email ya existe, buscando usuario...');
      
      try {
        const userRecord = await auth.getUserByEmail('josedavidlobo4@gmail.com');
        console.log('Usuario encontrado:', userRecord.uid);
        
        // Actualizar documento en Firestore
        await firestore.collection('users').doc(userRecord.uid).set({
          id: userRecord.uid,
          username: 'admin',
          name: 'Administrador',
          email: 'josedavidlobo4@gmail.com',
          isAdmin: true,
          isBlocked: false,
          lastPaymentDate: new Date().toISOString(),
          totalEarnings: 0,
          completedServices: 0,
          createdAt: new Date().toISOString()
        }, { merge: true });

        console.log('Usuario administrador actualizado exitosamente');
        console.log('UID:', userRecord.uid);
      } catch (updateError) {
        console.error('Error al actualizar usuario:', updateError);
      }
    } else {
      console.error('Error al crear usuario administrador:', error);
    }
  }

  process.exit(0);
}

createAdminUser();

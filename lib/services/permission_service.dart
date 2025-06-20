import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Verificar si ya tenemos el permiso
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    // Si no tenemos el permiso, solicitarlo
    status = await Permission.storage.request();
    if (status.isDenied) {
      // Mostrar diálogo explicando por qué necesitamos el permiso
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permiso necesario'),
            content: const Text(
                'Necesitamos acceso al almacenamiento para guardar las facturas generadas.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return status.isGranted;
  }
}

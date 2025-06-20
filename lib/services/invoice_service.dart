import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;

class InvoiceService {
  static Future<File> generateInvoice(Service service, app_user.User technician) async {
    // Verificar que estamos en una plataforma móvil
    if (kIsWeb) {
      throw UnsupportedError('La generación de facturas no está soportada en web. Use la aplicación móvil.');
    }
    final pdf = pw.Document();

    // Formato para números
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CR',
      symbol: '₡',
      decimalDigits: 0,
    );

    // Formato para fechas
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Header(
                level: 0,
                child: pw.Text('Factura de Servicio Técnico',
                    style: pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),

              // Información del servicio
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Detalles del Servicio',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('ID: ${service.id}'),
                    pw.Text('Título: ${service.title}'),
                    pw.Text('Descripción: ${service.description}'),
                    pw.Text('Tipo: ${service.serviceType == ServiceType.revision ? "Revisión" : "Servicio Completo"}'),
                    pw.Text('Fecha: ${dateFormat.format(service.completedAt ?? DateTime.now())}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Información del cliente
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Información del Cliente',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Nombre: ${service.clientName}'),
                    pw.Text('Teléfono: ${service.clientPhone}'),
                    pw.Text('Ubicación: ${service.location}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Información del técnico
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Técnico Asignado',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Nombre: ${technician.name}'),
                    pw.Text('ID: ${technician.id}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Detalles del pago
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Detalles del Pago',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Precio Base: ${currencyFormat.format(service.basePrice)}'),
                    pw.Text('Precio Final: ${currencyFormat.format(service.finalPrice)}'),
                    pw.Divider(),
                    pw.Text('Comisión Técnico (70%): ${currencyFormat.format(service.technicianCommission)}'),
                    pw.Text('Comisión Admin (30%): ${currencyFormat.format(service.adminCommission)}'),
                  ],
                ),
              ),

              // Pie de página
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Factura generada el ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF en el directorio de documentos para Android
    Directory output;
    try {
      if (Platform.isAndroid) {
        // Para Android, usar el directorio de documentos externos
        output = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      } else {
        // Para iOS u otras plataformas
        output = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Fallback al directorio temporal
      output = await getTemporaryDirectory();
    }
    
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'factura_${service.id}_$timestamp.pdf';
    final file = File('${output.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    
    print('Factura generada en: ${file.path}');
    return file;
  }
}

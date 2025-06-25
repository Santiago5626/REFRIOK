import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/service.dart';

class InvoiceService {
  Future<File> generateInvoice(Service service) async {
    final pdf = pw.Document();
    
    // Cargar el logo
    final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();
    final logo = pw.MemoryImage(logoData);

    // Calcular fecha de garantía (3 meses desde la fecha del servicio)
    final serviceDate = service.createdAt;
    final warrantyDate = serviceDate.add(const Duration(days: 90));
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado con logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 150),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FACTURA DE SERVICIO',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                      pw.Text('No. Servicio: ${service.id}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Información del cliente
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DATOS DEL CLIENTE',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Nombre: ${service.clientName}'),
                    pw.Text('Dirección: ${service.location}'),
                    pw.Text('Teléfono: ${service.clientPhone}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Detalles del servicio
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DETALLES DEL SERVICIO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tipo: ${service.serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'}'),
                    pw.Text('Descripción: ${service.description}'),
                    if (service.additionalDetails != null && service.additionalDetails!.isNotEmpty) ...[
                      if (service.additionalDetails!['diagnosis'] != null)
                        pw.Text('Diagnóstico: ${service.additionalDetails!['diagnosis']}'),
                      if (service.additionalDetails!['solution'] != null)
                        pw.Text('Solución: ${service.additionalDetails!['solution']}'),
                      if (service.additionalDetails!['observations'] != null)
                        pw.Text('Observaciones: ${service.additionalDetails!['observations']}'),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Información de pago
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INFORMACIÓN DE PAGO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Precio Final: \$${service.finalPrice.toStringAsFixed(0)}'),
                    pw.Text('Estado: ${service.isPaid ? 'PAGADO' : 'PENDIENTE'}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Garantía
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GARANTÍA',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Fecha del servicio: ${DateFormat('dd/MM/yyyy').format(serviceDate)}'),
                    pw.Text('Válida hasta: ${DateFormat('dd/MM/yyyy').format(warrantyDate)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Nota importante
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  'NOTA IMPORTANTE: En caso de que el cliente establezca un acuerdo directo con el técnico por fuera de los canales oficiales de REFRIOK, la empresa no asume responsabilidad alguna por los servicios prestados, ni ofrece garantía sobre los mismos.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/factura_${service.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}

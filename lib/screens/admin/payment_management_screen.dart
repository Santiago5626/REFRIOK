import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../services/service_management_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({Key? key}) : super(key: key);

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Service>>(
        stream: _serviceService.getAllServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final services = snapshot.data ?? [];
          
          // Filtrar solo servicios completados
          final completedServices = services
              .where((service) => service.status == ServiceStatus.completed || service.status == ServiceStatus.paid)
              .toList();

          if (completedServices.isEmpty) {
            return const Center(
              child: Text(
                'No hay servicios completados',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedServices.length,
            itemBuilder: (context, index) {
              final service = completedServices[index];
              return _buildServiceCard(service);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    final bool isPaid = service.isPaid;
    final Color statusColor = isPaid ? Colors.green : Colors.orange;
    final IconData statusIcon = isPaid ? Icons.check_circle : Icons.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado de pago
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'PAGADO' : 'PENDIENTE',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información del servicio
            _buildInfoRow('Cliente:', service.clientName),
            _buildInfoRow('Ubicación:', service.location),
            if (service.completedAt != null)
              _buildInfoRow(
                'Completado:',
                DateFormat('dd/MM/yyyy HH:mm').format(service.completedAt!),
              ),
            if (service.paidAt != null)
              _buildInfoRow(
                'Pagado:',
                DateFormat('dd/MM/yyyy HH:mm').format(service.paidAt!),
              ),

            const Divider(height: 24),

            // Información financiera
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio Total',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(service.finalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comisión Admin (30%)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(service.adminCommission),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comisión Técnico (70%)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(service.technicianCommission),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Botón de acción
            if (!isPaid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsPaid(service),
                  icon: const Icon(Icons.payment),
                  label: const Text('Marcar como Pagado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Advertencia de bloqueo automático
            if (!isPaid && service.shouldBlockTechnician()) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El técnico será bloqueado automáticamente a las 10 PM si no se marca como pagado',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(Service service) async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Confirmas que has recibido el pago de la comisión para el servicio "${service.title}"?'),
            const SizedBox(height: 16),
            Text(
              'Comisión a recibir: ${_currencyFormat.format(service.adminCommission)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final success = await _serviceService.markServiceAsPaid(service.id);

        // Cerrar indicador de carga
        if (mounted) Navigator.of(context).pop();

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servicio marcado como pagado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al marcar el servicio como pagado'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Cerrar indicador de carga si está abierto
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

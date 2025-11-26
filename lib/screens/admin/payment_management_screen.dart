import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../services/service_management_service.dart';
import '../../utils/fix_ispaid_field.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Gestión de Pagos',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.build_circle_outlined, color: Color(0xFF0052CC)),
            tooltip: 'Arreglar campo isPaid',
            onPressed: _fixIsPaidField,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF4F5F7),
            ),
          ),
          const SizedBox(width: 16),
        ],
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      size: 64,
                      color: const Color(0xFF0052CC).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No hay pagos pendientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Todos los servicios están al día',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5E6C84),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
    final Color statusColor = isPaid ? const Color(0xFF36B37E) : const Color(0xFFFFAB00);
    final IconData statusIcon = isPaid ? Icons.check_circle : Icons.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0052CC)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172B4D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.clientName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5E6C84),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
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
                
                const SizedBox(height: 20),

                // Información financiera
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFinancialItem(
                        'Total',
                        service.finalPrice,
                        const Color(0xFF172B4D),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFDFE1E6)),
                      _buildFinancialItem(
                        'Admin (30%)',
                        service.adminCommission,
                        const Color(0xFF0052CC),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFDFE1E6)),
                      _buildFinancialItem(
                        'Técnico (70%)',
                        service.technicianCommission,
                        const Color(0xFF36B37E),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Detalles adicionales
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5E6C84)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        service.location,
                        style: const TextStyle(color: Color(0xFF5E6C84), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (service.completedAt != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF5E6C84)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM HH:mm').format(service.completedAt!),
                        style: const TextStyle(color: Color(0xFF5E6C84), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botón de acción (si no está pagado)
          if (!isPaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEBECF0)),
                ),
              ),
              child: Column(
                children: [
                  if (service.shouldBlockTechnician())
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5630).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5630), size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Bloqueo automático a las 10 PM si no se paga.',
                              style: TextStyle(
                                color: Color(0xFFFF5630),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsPaid(service),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Confirmar Pago de Comisión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF36B37E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5E6C84),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _markAsPaid(Service service) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas que has recibido el pago de la comisión para el servicio "${service.title}"?',
              style: const TextStyle(color: Color(0xFF172B4D)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comisión a recibir:',
                    style: TextStyle(
                      color: Color(0xFF172B4D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(service.adminCommission),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF36B37E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0052CC)),
          ),
        );

        final success = await _serviceService.markServiceAsPaid(service.id);

        if (mounted) Navigator.of(context).pop();

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servicio marcado como pagado exitosamente'),
                backgroundColor: Color(0xFF36B37E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al marcar el servicio como pagado'),
                backgroundColor: Color(0xFFFF5630),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFFF5630),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _fixIsPaidField() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0052CC)),
              SizedBox(height: 16),
              Text('Arreglando campo isPaid...'),
            ],
          ),
        ),
      );

      final fix = FixIsPaidField();
      await fix.fixServices();

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campo isPaid actualizado exitosamente'),
            backgroundColor: Color(0xFF36B37E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF5630),
          ),
        );
      }
    }
  }
}

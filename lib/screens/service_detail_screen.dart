import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import '../services/service_management_service.dart';
import '../services/auth_service.dart';
import '../services/invoice_service.dart';
import '../utils/dialog_utils.dart';
import '../theme/app_theme.dart';
import 'edit_service_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Service service;
  final bool isAvailable;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.isAvailable,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  app_user.User? _currentUser;
  late Service _currentService;

  @override
  void initState() {
    super.initState();
    _currentService = widget.service;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!widget.isAvailable &&
        !_currentUser!.isAdmin &&
        widget.service.assignedTechnicianId != _currentUser!.id) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tienes acceso a este servicio',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo moderno
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Detalles del Servicio',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        actions: [
          if (_currentService.status == ServiceStatus.completed ||
              _currentService.status == ServiceStatus.paid)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Descargar Factura',
              onPressed: _downloadInvoice,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF4F5F7),
                foregroundColor: const Color(0xFF172B4D),
              ),
            ),
          const SizedBox(width: 8),
          if (_currentUser?.isAdmin == true &&
              _currentService.status != ServiceStatus.completed &&
              _currentService.status != ServiceStatus.paid)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditServiceScreen(service: _currentService),
                  ),
                );

                if (updated == true) {
                  final updatedService = await _serviceService.getServiceById(_currentService.id);
                  if (updatedService != null) {
                    setState(() {
                      _currentService = updatedService;
                    });
                  }
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF4F5F7),
                foregroundColor: const Color(0xFF172B4D),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerta de Comisión Pendiente
            if (_currentService.status == ServiceStatus.completed && !_currentService.isPaid)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAE6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFAB00)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFAB00).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFAB00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comisión Pendiente',
                            style: TextStyle(
                              color: Color(0xFF172B4D),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Debes pagar la comisión al administrador.',
                            style: TextStyle(
                              color: const Color(0xFF172B4D).withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Mostrar estado solo si NO está completado con deuda pendiente
            if (!(_currentService.status == ServiceStatus.completed && !_currentService.isPaid)) ...[
              _buildStatusHeader(),
              const SizedBox(height: 20),
            ],

            _buildInfoCard(),
            const SizedBox(height: 20),
            if (_currentUser!.isAdmin ||
                widget.isAvailable ||
                _currentService.assignedTechnicianId == _currentUser!.id) ...[
              _buildClientCard(),
              const SizedBox(height: 20),
              _buildLocationCard(),
              const SizedBox(height: 20),
              if (!widget.isAvailable) _buildPriceCard(),
              const SizedBox(height: 30),
            ],
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = _getStatusColor(_currentService.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(_currentService.status), color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Actual',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(_currentService.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFF0052CC)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem('Título', _currentService.title),
          const SizedBox(height: 12),
          _buildDetailItem('Descripción', _currentService.description),
          const SizedBox(height: 12),
          _buildDetailItem('Programado', _formatDateTime(_currentService.scheduledFor)),
        ],
      ),
    );
  }

  Widget _buildClientCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF0052CC)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cliente',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentService.clientName,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentService.clientPhone,
                      style: const TextStyle(color: Color(0xFF5E6C84)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _callClient,
                icon: const Icon(Icons.phone),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF36B37E).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF36B37E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5630).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF5630)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentService.location,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openMaps,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.near_me, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF36B37E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_money, color: Color(0xFF36B37E)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detalles Financieros',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentService.serviceType != null) ...[
            _buildDetailItem('Tipo', _currentService.serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'),
            const SizedBox(height: 12),
            _buildDetailItem('Precio Final', '\$${_currentService.finalPrice.toStringAsFixed(0)}', isBold: true),
            const SizedBox(height: 12),
            if (_currentUser!.isAdmin)
              _buildDetailItem('Comisión Admin (30%)', '\$${_currentService.adminCommission.toStringAsFixed(0)}', color: const Color(0xFF0052CC))
            else
              _buildDetailItem('Tu Ganancia (70%)', '\$${_currentService.technicianCommission.toStringAsFixed(0)}', color: const Color(0xFF36B37E)),
          ] else ...[
            _buildDetailItem('Precio Base', '\$${_currentService.basePrice.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            if (_currentUser!.isAdmin)
              Text(
                'Ganancia estimada (30%): \$${(_currentService.basePrice * 0.3).toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF5E6C84), fontSize: 14),
              )
            else
              Text(
                'Ganancia estimada (70%): \$${(_currentService.basePrice * 0.7).toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF5E6C84), fontSize: 14),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5E6C84),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF172B4D),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_currentUser == null) return const SizedBox.shrink();

    if (widget.isAvailable) {
      if (_currentUser!.isAdmin) {
        return _buildButton(
          'Asignar a Técnico',
          Icons.person_add_outlined,
          AppTheme.primaryBlue,
          _showAssignTechnicianDialog,
        );
      } else {
        return _buildButton(
          'Aceptar Servicio',
          Icons.check_circle_outline,
          AppTheme.successText,
          _acceptService,
        );
      }
    }

    if (!_currentUser!.isAdmin) {
      switch (_currentService.status) {
        case ServiceStatus.assigned:
          return _buildButton(
            'Marcar En Camino',
            Icons.directions_car_outlined,
            AppTheme.primaryBlue,
            _markOnWay,
          );
        case ServiceStatus.onWay:
          return _buildButton(
            'Marcar Llegada',
            Icons.location_on_outlined,
            Colors.orange,
            _markArrived,
          );
        case ServiceStatus.inProgress:
          return _buildButton(
            'Completar Servicio',
            Icons.task_alt,
            AppTheme.successText,
            () {
              if (_currentService.serviceType == ServiceType.revision) {
                _showCompleteServiceDialogForRevision();
              } else {
                _showCompleteServiceDialogForComplete();
              }
            },
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(_isLoading ? 'Procesando...' : text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ... (Keep existing helper methods: _acceptService, _markOnWay, _markArrived, etc.)
  // I will copy the logic methods here to ensure they are preserved.

  Future<void> _acceptService() async {
    setState(() => _isLoading = true);
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    bool success = await _serviceService.acceptService(widget.service.id, currentUser.id);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      await showAnimatedDialog(context, DialogType.success, 'Servicio aceptado exitosamente');
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error al aceptar el servicio');
    }
  }

  Future<void> _markOnWay() async {
    setState(() => _isLoading = true);
    bool success = await _serviceService.markOnWay(_currentService.id);

    if (success) {
      _refreshService();
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error al actualizar estado');
    }
  }

  Future<void> _markArrived() async {
    _showServiceTypeDialog();
  }

  void _showServiceTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tipo de Servicio'),
          content: const Text('¿Qué tipo de servicio vas a realizar?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markArrivedWithType(ServiceType.revision);
              },
              child: Text('Solo Revisión (\$${widget.service.basePrice.toStringAsFixed(0)})'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markArrivedWithType(ServiceType.complete);
              },
              child: const Text('Servicio Completo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markArrivedWithType(ServiceType serviceType) async {
    setState(() => _isLoading = true);
    bool success = await _serviceService.markArrivedWithServiceType(widget.service.id, serviceType);

    if (success) {
      _refreshService(message: 'Marcado como llegado - ${serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'}');
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error al actualizar estado');
    }
  }

  Future<void> _refreshService({String? message}) async {
    try {
      final updatedService = await _serviceService.getServiceById(_currentService.id);
      if (updatedService != null) {
        setState(() {
          _currentService = updatedService;
          _isLoading = false;
        });
        if (message != null && mounted) {
          await showAnimatedDialog(context, DialogType.success, message);
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCompleteServiceDialogForComplete() {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Completar Servicio'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingrese el valor del servicio completo:'),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '\$',
                  hintText: 'Valor del servicio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (priceController.text.isNotEmpty) {
                  try {
                    double finalPrice = double.parse(priceController.text);
                    _completeService(ServiceType.complete, finalPrice: finalPrice);
                  } catch (e) {
                    showAnimatedDialog(context, DialogType.error, 'Ingrese un valor numérico válido');
                  }
                } else {
                  showAnimatedDialog(context, DialogType.error, 'Debe ingresar el valor del servicio');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Completar'),
            ),
          ],
        );
      },
    );
  }

  void _showCompleteServiceDialogForRevision() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Completar Servicio'),
          content: const Text('¿Estás seguro de completar este servicio?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeService(ServiceType.revision);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Completar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeService(ServiceType serviceType, {double? finalPrice}) async {
    setState(() => _isLoading = true);
    bool success = false;

    try {
      if (serviceType == ServiceType.complete && finalPrice != null) {
        success = await _serviceService.completeServiceWithPrice(_currentService.id, finalPrice);
      } else {
        success = await _serviceService.completeService(_currentService.id, serviceType);
      }

      if (success) {
        _refreshService(message: 'Servicio completado');
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        showAnimatedDialog(context, DialogType.error, 'Error al completar el servicio');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error: $e');
    }
  }

  Future<void> _callClient() async {
    final Uri phoneUri = Uri.parse('tel:${widget.service.clientPhone}');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'No se puede realizar la llamada');
    }
  }

  Future<void> _openMaps() async {
    final String query = Uri.encodeComponent(widget.service.location);
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else {
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'No se puede abrir el mapa');
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
      );

      final invoiceService = InvoiceService();
      final file = await invoiceService.generateInvoice(widget.service);

      if (mounted) Navigator.pop(context);

      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done) {
        if (!mounted) return;
        showAnimatedDialog(context, DialogType.error, 'Error al abrir la factura');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error al generar la factura');
    }
  }

  void _showAssignTechnicianDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<app_user.User>>(
          future: _serviceService.getAvailableTechnicians(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final technicians = snapshot.data ?? [];

            if (technicians.isEmpty) {
              return AlertDialog(
                title: const Text('Sin Técnicos'),
                content: const Text('No hay técnicos disponibles.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Asignar Técnico'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: technicians.length,
                  itemBuilder: (context, index) {
                    final technician = technicians[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: technician.isBlocked ? AppTheme.errorText : AppTheme.successText,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(technician.name),
                      subtitle: Text(
                        technician.isBlocked ? 'Bloqueado' : 'Disponible',
                        style: TextStyle(
                          color: technician.isBlocked ? AppTheme.errorText : AppTheme.successText,
                        ),
                      ),
                      enabled: !technician.isBlocked,
                      onTap: technician.isBlocked
                          ? null
                          : () {
                              Navigator.pop(context);
                              _assignServiceToTechnician(technician.id);
                            },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignServiceToTechnician(String technicianId) async {
    setState(() => _isLoading = true);
    try {
      bool success = await _serviceService.assignService(_currentService.id, technicianId);
      if (success) {
        _refreshService(message: 'Servicio asignado correctamente');
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        showAnimatedDialog(context, DialogType.error, 'Error al asignar el servicio');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, 'Error: $e');
    }
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return AppTheme.warningText;
      case ServiceStatus.assigned:
        return AppTheme.primaryBlue;
      case ServiceStatus.onWay:
        return Colors.purple;
      case ServiceStatus.inProgress:
        return Colors.amber[800]!;
      case ServiceStatus.completed:
        return AppTheme.successText;
      case ServiceStatus.cancelled:
        return AppTheme.errorText;
      case ServiceStatus.paid:
        return Colors.teal;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Icons.pending_outlined;
      case ServiceStatus.assigned:
        return Icons.assignment_ind_outlined;
      case ServiceStatus.onWay:
        return Icons.directions_car_outlined;
      case ServiceStatus.inProgress:
        return Icons.build_outlined;
      case ServiceStatus.completed:
        return Icons.check_circle_outline;
      case ServiceStatus.cancelled:
        return Icons.cancel_outlined;
      case ServiceStatus.paid:
        return Icons.paid_outlined;
    }
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'Pendiente';
      case ServiceStatus.assigned:
        return 'Asignado';
      case ServiceStatus.onWay:
        return 'En Camino';
      case ServiceStatus.inProgress:
        return 'En Progreso';
      case ServiceStatus.completed:
        return 'Completado';
      case ServiceStatus.cancelled:
        return 'Cancelado';
      case ServiceStatus.paid:
        return 'Pagado';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

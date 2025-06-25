import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import '../models/service.dart';
import '../models/user.dart' as app_user;
import '../services/service_management_service.dart';
import '../services/auth_service.dart';
import '../services/invoice_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _acceptService() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    bool success = await _serviceService.acceptService(
      widget.service.id,
      currentUser.id,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio aceptado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al aceptar el servicio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markOnWay() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await _serviceService.markOnWay(widget.service.id);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marcado como en camino'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markArrived() async {
    // Mostrar diálogo para elegir tipo de servicio
    _showServiceTypeDialog();
  }

  void _showServiceTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tipo de Servicio'),
          content: const Text('¿Qué tipo de servicio vas a realizar?'),
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markArrivedWithType(ServiceType serviceType) async {
    setState(() {
      _isLoading = true;
    });

    bool success = await _serviceService.markArrivedWithServiceType(
      widget.service.id,
      serviceType,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Marcado como llegado - ${serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeService(ServiceType serviceType,
      {double? finalPrice}) async {
    setState(() {
      _isLoading = true;
    });

    bool success = await _serviceService.completeService(
      widget.service.id,
      serviceType,
      finalPrice: finalPrice,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio completado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al completar servicio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompleteServiceDialog() {
    if (widget.service.serviceType == ServiceType.complete) {
      // Para servicios completos, mostrar diálogo de precio
      final priceController = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Completar Servicio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ingrese el valor del servicio completo:'),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '\$',
                    hintText: 'Valor del servicio',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (priceController.text.isNotEmpty) {
                    try {
                      double finalPrice = double.parse(priceController.text);
                      _completeService(ServiceType.complete,
                          finalPrice: finalPrice);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese un valor numérico válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debe ingresar el valor del servicio'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Completar'),
              ),
            ],
          );
        },
      );
    } else {
      // Para servicios de revisión, mostrar diálogo normal
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Completar Servicio'),
            content: const Text('¿Estás seguro de completar este servicio?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completeService(ServiceType.revision);
                },
                child: const Text('Completar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _callClient() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.service.clientPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede realizar la llamada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMaps() async {
    final String query = Uri.encodeComponent(widget.service.location);
    final Uri mapsUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir el mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Generando factura...'),
              ],
            ),
          );
        },
      );

      // Generar la factura
      final invoiceService = InvoiceService();
      final file = await invoiceService.generateInvoice(widget.service);

      // Cerrar el diálogo de carga
      if (mounted) Navigator.pop(context);

      // Abrir el archivo PDF
      final result = await OpenFile.open(file.path);
      
      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir la factura: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura generada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar la factura: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si es un servicio asignado y el usuario no es el técnico asignado ni admin
    if (!widget.isAvailable &&
        !_currentUser!.isAdmin &&
        widget.service.assignedTechnicianId != _currentUser!.id) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
        ),
        body: const Center(
          child: Text(
            'No tienes acceso a los detalles de este servicio',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.title),
        actions: [
          if (widget.service.status == ServiceStatus.completed || 
              widget.service.status == ServiceStatus.paid)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Descargar Factura',
              onPressed: _downloadInvoice,
            ),
          if (_currentUser?.isAdmin == true &&
              widget.service.status != ServiceStatus.completed)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditServiceScreen(service: widget.service),
                  ),
                );

                if (updated == true) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            // Solo mostrar detalles del cliente y ubicación si es el técnico asignado o admin
            if (_currentUser!.isAdmin ||
                widget.isAvailable ||
                widget.service.assignedTechnicianId == _currentUser!.id) ...[
              _buildClientCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              if (!widget.isAvailable) _buildPriceCard(),
              const SizedBox(height: 24),
            ],
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Servicio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Descripción:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.service.description),
            const SizedBox(height: 12),
            Text(
              'Programado para:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(_formatDateTime(widget.service.scheduledFor)),
            if (!widget.isAvailable) ...[
              const SizedBox(height: 12),
              Text(
                'Estado:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  _getStatusText(widget.service.status),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: _getStatusColor(widget.service.status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.service.clientName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.service.clientPhone,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: _callClient,
                  icon: const Icon(Icons.call),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.service.location,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.service.serviceType != null) ...[
              Text(
                'Tipo de servicio: ${widget.service.serviceType == ServiceType.revision ? 'Revisión' : 'Servicio Completo'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Precio final: \$${widget.service.finalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu ganancia (70%): \$${widget.service.technicianCommission.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ] else ...[
              Text(
                'Precio base: \$${widget.service.basePrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisión: \$${widget.service.basePrice.toStringAsFixed(0)} (Tu ganancia: \$${(widget.service.basePrice * 0.7).toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si es un servicio disponible (pendiente)
    if (widget.isAvailable) {
      if (_currentUser!.isAdmin) {
        // Los administradores pueden asignar servicios a técnicos
        return _buildAssignServiceButton();
      } else {
        // Los técnicos no pueden aceptar servicios, se les asignan
        return const SizedBox.shrink();
      }
    }

    // Si no es admin, mostrar botones según el estado del servicio
    if (!_currentUser!.isAdmin) {
      switch (widget.service.status) {
        case ServiceStatus.assigned:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _markOnWay,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Marcar como En Camino',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          );

        case ServiceStatus.onWay:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _markArrived,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Marcar Llegada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          );

        case ServiceStatus.inProgress:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _showCompleteServiceDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Completar Servicio',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          );

        default:
          return const SizedBox.shrink();
      }
    }

    // Los administradores solo ven información, no botones de acción para servicios asignados
    return const SizedBox.shrink();
  }

  Widget _buildAssignServiceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showAssignTechnicianDialog,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Asignar a Técnico',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
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

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Error al cargar técnicos: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            final technicians = snapshot.data ?? [];

            if (technicians.isEmpty) {
              return AlertDialog(
                title: const Text('Sin Técnicos'),
                content:
                    const Text('No hay técnicos disponibles en este momento.'),
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
                        backgroundColor:
                            technician.isBlocked ? Colors.red : Colors.green,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(technician.name),
                      subtitle: Text(
                        technician.isBlocked ? 'Bloqueado' : 'Disponible',
                        style: TextStyle(
                          color:
                              technician.isBlocked ? Colors.red : Colors.green,
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
    setState(() {
      _isLoading = true;
    });

    bool success = await _serviceService.acceptService(
      widget.service.id,
      technicianId,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio asignado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al asignar el servicio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange;
      case ServiceStatus.assigned:
        return Colors.blue;
      case ServiceStatus.onWay:
        return Colors.purple;
      case ServiceStatus.inProgress:
        return Colors.amber;
      case ServiceStatus.completed:
        return Colors.green;
      case ServiceStatus.cancelled:
        return Colors.red;
      case ServiceStatus.paid:
        return Colors.green[700] ?? Colors.green;
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/service.dart';
import '../services/service_management_service.dart';

class EditServiceScreen extends StatefulWidget {
  final Service service;

  const EditServiceScreen({
    super.key,
    required this.service,
  });

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceManagementService _serviceService = ServiceManagementService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _basePriceController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.service.title);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _locationController = TextEditingController(text: widget.service.location);
    _clientNameController =
        TextEditingController(text: widget.service.clientName);
    _clientPhoneController =
        TextEditingController(text: widget.service.clientPhone);
    _basePriceController = TextEditingController(
        text: widget.service.basePrice.toStringAsFixed(0));

    _selectedDate = DateTime(
      widget.service.scheduledFor.year,
      widget.service.scheduledFor.month,
      widget.service.scheduledFor.day,
    );
    _selectedTime = TimeOfDay(
      hour: widget.service.scheduledFor.hour,
      minute: widget.service.scheduledFor.minute,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione fecha y hora'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledFor = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final basePrice = double.parse(_basePriceController.text);

      final success = await _serviceService.updateService(
        serviceId: widget.service.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        scheduledFor: scheduledFor,
        basePrice: basePrice,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Servicio actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
              context, true); // Retornar true para indicar que se actualizó
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar el servicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Servicio'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _updateService,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del estado
                    if (widget.service.status != ServiceStatus.pending)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este servicio está ${_getStatusText(widget.service.status)}. Los cambios pueden afectar el flujo de trabajo.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título del Servicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese un título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ubicación
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese la ubicación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Información del cliente
                    const Text(
                      'Información del Cliente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nombre del cliente
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el nombre del cliente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono del cliente
                    TextFormField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono del Cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el teléfono del cliente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha y hora
                    const Text(
                      'Programación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Seleccionar fecha',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime != null
                                        ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Seleccionar hora',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Precio base
                    TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Base',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '\$',
                        helperText:
                            'Si es mayor a \$30.000, se considerará servicio completo',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el precio base';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Por favor ingrese un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Información de comisiones
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de Comisiones',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Revisión: \$30.000 fijo'),
                          const Text('• Servicio completo: Precio base'),
                          const Text('• Técnico: 70% del precio final'),
                          const Text('• Administrador: 30% del precio final'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón de actualizar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateService,
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
                                'Actualizar Servicio',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'pendiente';
      case ServiceStatus.assigned:
        return 'asignado';
      case ServiceStatus.onWay:
        return 'en camino';
      case ServiceStatus.inProgress:
        return 'en progreso';
      case ServiceStatus.completed:
        return 'completado';
      case ServiceStatus.cancelled:
        return 'cancelado';
    }
  }
}

import 'package:flutter/material.dart';
import '../services/service_management_service.dart';
import '../services/sede_service.dart';
import '../models/sede.dart';
import '../utils/dialog_utils.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final SedeService _sedeService = SedeService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressObservationsController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _basePriceController = TextEditingController();
  
  String? _selectedCity;
  String? _selectedSedeId;
  double? _selectedSedeBasePrice;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _addressObservationsController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Servicio'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
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
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título del Servicio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la descripción';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Sede>>(
                        stream: _sedeService.getSedesActivas(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Ciudad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              items: const [],
                              onChanged: null,
                            );
                          }

                          final sedes = snapshot.data ?? [];
                          if (sedes.isEmpty) {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Ciudad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                                helperText: 'No hay sedes disponibles',
                              ),
                              items: const [],
                              onChanged: null,
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: const InputDecoration(
                              labelText: 'Ciudad',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            items: sedes.map((Sede sede) {
                              return DropdownMenuItem<String>(
                                value: sede.nombre,
                                child: Text('${sede.nombre} - \$${sede.valorBaseRevision.toStringAsFixed(0)}'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCity = newValue;
                                if (newValue != null) {
                                  final sedeSeleccionada = sedes.firstWhere(
                                    (sede) => sede.nombre == newValue,
                                  );
                                  _selectedSedeId = sedeSeleccionada.id;
                                  _selectedSedeBasePrice = sedeSeleccionada.valorBaseRevision;
                                  _basePriceController.text = sedeSeleccionada.valorBaseRevision.toStringAsFixed(0);
                                } else {
                                  _selectedSedeId = null;
                                  _selectedSedeBasePrice = null;
                                  _basePriceController.clear();
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor seleccione una ciudad';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          helperText: 'Ingrese la dirección específica (calle, carrera, número)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la dirección';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressObservationsController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones de la Dirección (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                          helperText: 'Detalles adicionales como apartamento, piso, referencias, etc.',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre del cliente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono del Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el teléfono';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _basePriceController,
                        decoration: InputDecoration(
                          labelText: 'Precio Base',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                          prefixText: '\$',
                          helperText: _selectedSedeBasePrice != null 
                              ? 'Precio base de la sede: \$${_selectedSedeBasePrice!.toStringAsFixed(0)}'
                              : 'Seleccione una ciudad para ver el precio base',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio base es requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un precio válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createService,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            'Crear Servicio',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir la ubicación completa incluyendo observaciones si existen
      String fullLocation = '${_selectedCity}, ${_addressController.text}';
      if (_addressObservationsController.text.isNotEmpty) {
        fullLocation += ' - ${_addressObservationsController.text}';
      }

      final serviceId = await _serviceService.createService(
        title: _titleController.text,
        description: _descriptionController.text,
        location: fullLocation,
        clientName: _clientNameController.text,
        clientPhone: _clientPhoneController.text,
        scheduledFor: DateTime.now().add(const Duration(hours: 1)), // Programar para 1 hora después
        basePrice: double.tryParse(_basePriceController.text) ?? _selectedSedeBasePrice ?? 30000,
        sedeId: _selectedSedeId,
      );

      if (!mounted) return;
      
      if (serviceId != null) {
        await showAnimatedDialog(context, DialogType.success, 'Servicio creado exitosamente');
        Navigator.pop(context, true);
      } else {
        showAnimatedDialog(context, DialogType.error, 'Error al crear servicio');
      }
    } catch (e) {
      if (!mounted) return;
      showAnimatedDialog(context, DialogType.error, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

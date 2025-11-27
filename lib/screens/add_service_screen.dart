import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/service_management_service.dart';
import '../services/sede_service.dart';
import '../models/sede.dart';
import '../utils/dialog_utils.dart';
import '../theme/app_theme.dart';

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

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  }

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Agregar Servicio',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172B4D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                title: 'Información del Servicio',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título del Servicio',
                    icon: Icons.title,
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Descripción',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Ubicación',
                icon: Icons.location_on_outlined,
                children: [
                  StreamBuilder<List<Sede>>(
                    stream: _sedeService.getSedesActivas(),
                    builder: (context, snapshot) {
                      final sedes = snapshot.data ?? [];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: const TextStyle(color: Color(0xFF5E6C84)),
                            prefixIcon: const Icon(Icons.location_city, color: Color(0xFF0052CC)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0052CC), width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5E6C84)),
                          dropdownColor: Colors.white,
                          items: sedes.map((Sede sede) {
                            return DropdownMenuItem<String>(
                              value: sede.nombre,
                              child: Text(
                                '${sede.nombre} - \$${sede.valorBaseRevision.toStringAsFixed(0)}',
                                style: const TextStyle(color: Color(0xFF172B4D)),
                              ),
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
                          validator: (value) => value == null ? 'Seleccione una ciudad' : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Dirección',
                    icon: Icons.map_outlined,
                    helperText: 'Calle, carrera, número, etc.',
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressObservationsController,
                    label: 'Observaciones (Opcional)',
                    icon: Icons.note_alt_outlined,
                    helperText: 'Apartamento, torre, referencias...',
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Programación',
                icon: Icons.calendar_today,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xFF0052CC)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fecha',
                                      style: TextStyle(
                                        color: Color(0xFF5E6C84),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                                      style: const TextStyle(
                                        color: Color(0xFF172B4D),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF0052CC)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hora',
                                      style: TextStyle(
                                        color: Color(0xFF5E6C84),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(
                                        color: Color(0xFF172B4D),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Información del Cliente',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _clientNameController,
                    label: 'Nombre del Cliente',
                    icon: Icons.person,
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _clientPhoneController,
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Precio',
                icon: Icons.attach_money,
                children: [
                  _buildTextField(
                    controller: _basePriceController,
                    label: 'Precio Base',
                    icon: Icons.payments_outlined,
                    prefixText: '\$ ',
                    keyboardType: TextInputType.number,
                    helperText: _selectedSedeBasePrice != null 
                        ? 'Base sede: \$${_selectedSedeBasePrice!.toStringAsFixed(0)}'
                        : 'Seleccione ciudad para ver base',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (double.tryParse(value!) == null) return 'Precio inválido';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0052CC).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Crear Servicio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0052CC), size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF172B4D),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF5E6C84)),
        helperText: helperText,
        helperStyle: const TextStyle(color: Color(0xFF5E6C84)),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xFF172B4D),
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF0052CC)),
        filled: true,
        fillColor: const Color(0xFFF4F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0052CC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5630), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5630), width: 1.5),
        ),
      ),
      validator: validator,
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
        scheduledFor: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
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
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppTheme.primaryBlue,
              headerForegroundColor: Colors.white,
              confirmButtonStyle: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: AppTheme.primaryBlue,
              dayPeriodTextColor: AppTheme.primaryBlue,
              dialHandColor: AppTheme.primaryBlue,
              dialBackgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              confirmButtonStyle: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
}

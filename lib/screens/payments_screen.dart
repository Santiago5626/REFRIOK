import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/currency_formatter.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  List<User> _technicians = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await _authService.getAllTechnicians();
      setState(() {
        _technicians = technicians;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar técnicos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _technicians.isEmpty
              ? const Center(
                  child: Text(
                    'No hay técnicos registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTechnicians,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _technicians.length,
                    itemBuilder: (context, index) {
                      final technician = _technicians[index];
                      return _buildTechnicianCard(technician);
                    },
                  ),
                ),
    );
  }

  Widget _buildTechnicianCard(User technician) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: technician.isBlocked ? Colors.red : Colors.green,
          child: Icon(
            technician.isBlocked ? Icons.block : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          technician.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${technician.email}'),
            Text(
              'Estado: ${technician.isBlocked ? 'Bloqueado' : 'Activo'}',
              style: TextStyle(
                color: technician.isBlocked ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (technician.lastPaymentDate != null)
              Text(
                'Último pago: ${_formatDate(technician.lastPaymentDate!)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de comisiones
                FutureBuilder<double>(
                  future: _paymentService.getPendingCommissions(technician.id),
                  builder: (context, snapshot) {
                    final pendingAmount = snapshot.data ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comisiones Pendientes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCurrency(pendingAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showMarkPaymentDialog(technician),
                        icon: const Icon(Icons.payment),
                        label: const Text('Marcar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (technician.isBlocked)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _unblockTechnician(technician),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Desbloquear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Historial de pagos
                const Text(
                  'Historial de Pagos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _paymentService.getTechnicianPayments(technician.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final payments = snapshot.data ?? [];
                    
                    if (payments.isEmpty) {
                      return const Text(
                        'No hay pagos registrados',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    
                    return Column(
                      children: payments.take(3).map((payment) {
                        final paymentDate = DateTime.parse(payment['paymentDate']);
                        final amount = (payment['amount'] ?? 0.0).toDouble();
                        
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.payment, color: Colors.green),
                          title: Text(formatCurrency(amount)),
                          subtitle: Text(_formatDate(paymentDate)),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkPaymentDialog(User technician) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar Pago - ${technician.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<double>(
              future: _paymentService.getPendingCommissions(technician.id),
              builder: (context, snapshot) {
                final pendingAmount = snapshot.data ?? 0;
                amountController.text = pendingAmount.toStringAsFixed(0);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comisiones pendientes: ${formatCurrency(pendingAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Monto pagado',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                await _markPayment(technician, amount);
              }
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPayment(User technician, double amount) async {
    try {
      final success = await _paymentService.markCommissionPaid(technician.id, amount);
      
      if (success) {
        await _loadTechnicians(); // Recargar la lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pago de ${technician.name} marcado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al marcar el pago'),
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
    }
  }

  Future<void> _unblockTechnician(User technician) async {
    try {
      final success = await _paymentService.unblockTechnician(technician.id);
      
      if (success) {
        await _loadTechnicians(); // Recargar la lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${technician.name} desbloqueado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al desbloquear técnico'),
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
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

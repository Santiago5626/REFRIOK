import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/payment_service.dart';


class ProfileScreen extends StatefulWidget {
  final User initialUser;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    required this.initialUser,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data ?? widget.initialUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA), // Fondo más claro
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildModernHeader(user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildWalletCard(user),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Estadísticas'),
                      const SizedBox(height: 15),
                      _buildStatsGrid(user),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Mi Cuenta'),
                      const SizedBox(height: 15),
                      _buildMenuOptions(context, user),
                      const SizedBox(height: 30),
                      if (widget.onSignOut != null) _buildLogoutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<User?> _getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.initialUser.id)
        .snapshots()
        .map((doc) => doc.exists ? User.fromMap({'id': doc.id, ...doc.data()!}) : null);
  }

  Widget _buildModernHeader(User user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Fondo con gradiente y forma curva
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0052CC), // Azul oscuro
                Color(0xFF2684FF), // Azul más claro
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
        ),
        // Contenido del header (Nombre y Rol)
        Positioned(
          top: 60,
          child: Column(
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isAdmin ? 'Administrador' : 'Técnico Certificado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Avatar superpuesto
        Positioned(
          bottom: -40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052CC),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(User user) {
    return FutureBuilder<double>(
      future: _paymentService.getPendingEarnings(user.id),
      builder: (context, snapshot) {
        double pendingEarnings = snapshot.data ?? 0.0;
        double totalEarnings = user.totalEarnings;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF172B4D), // Azul muy oscuro (Navy)
                Color(0xFF091E42), // Casi negro
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF091E42).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Billetera Virtual',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Ganancias Totales',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${(totalEarnings + pendingEarnings).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildWalletStat('Pagado', totalEarnings, Colors.greenAccent),
                  Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                  _buildWalletStat('Pendiente', pendingEarnings, Colors.orangeAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(User user) {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'Servicios',
            user.completedServices.toString(),
            Icons.check_circle_outline,
            const Color(0xFFE3FCEF), // Fondo verde suave
            const Color(0xFF006644), // Texto verde oscuro
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FutureBuilder<double>(
            future: _paymentService.getPendingCommissions(user.id),
            builder: (context, snapshot) {
              double debt = snapshot.data ?? 0.0;
              bool hasDebt = debt > 0;
              return _buildModernStatCard(
                'Deuda',
                hasDebt ? '\$${debt.toStringAsFixed(0)}' : 'Al día',
                hasDebt ? Icons.warning_amber_rounded : Icons.thumb_up_alt_outlined,
                hasDebt ? const Color(0xFFFFEBE6) : const Color(0xFFDEEBFF), // Rojo suave o Azul suave
                hasDebt ? const Color(0xFFBF2600) : const Color(0xFF0747A6), // Rojo oscuro o Azul oscuro
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color bgColor, Color contentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: contentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: 'Historial de Pagos',
            subtitle: 'Revisa tus transacciones pasadas',
            color: Colors.purple,
            onTap: () => _showPaymentInfoDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.support_agent_rounded,
            title: 'Centro de Ayuda',
            subtitle: 'Contacta con soporte técnico',
            color: Colors.blue,
            onTap: () => _showSupportDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
            color: Colors.grey,
            onTap: () {}, // Placeholder
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 76),
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: widget.onSignOut,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFEBE6),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, color: Color(0xFFBF2600), size: 20),
          SizedBox(width: 8),
          Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Color(0xFFBF2600),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF172B4D),
        letterSpacing: -0.5,
      ),
    );
  }

  // --- Dialogs (Reused logic, updated style) ---

  void _showPaymentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_outlined, color: Colors.purple, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sistema de Pagos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDialogInfoRow('Comisión Técnico', '70%'),
            _buildDialogInfoRow('Comisión Admin', '30%'),
            const SizedBox(height: 24),
            const Text(
              'Recuerda pagar tus comisiones antes de las 10 PM para evitar bloqueos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/logo.png'), // Fallback if no image
              backgroundColor: Colors.blue,
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Soporte Técnico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jose David Lobo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('+57 324 440 6860'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('8:00 AM - 8:00 PM'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

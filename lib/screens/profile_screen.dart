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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)));
        }

        final user = snapshot.data ?? widget.initialUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildModernHeader(user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildWalletCard(user),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Estadísticas'),
                      const SizedBox(height: 16),
                      _buildStatsGrid(user),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Mi Cuenta'),
                      const SizedBox(height: 16),
                      _buildMenuOptions(context, user),
                      const SizedBox(height: 32),
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
        Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0052CC), // Azul principal
                Color(0xFF2684FF), // Azul claro
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
        ),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  user.isAdmin ? 'Administrador' : 'Técnico Certificado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172B4D).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
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
                Color(0xFF172B4D), // Navy
                Color(0xFF091E42), // Darker Navy
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF172B4D).withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Billetera Virtual',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Ganancias Totales',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${(totalEarnings + pendingEarnings).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildWalletStat('Pagado', totalEarnings, const Color(0xFF36B37E)),
                  Container(height: 30, width: 1, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 24)),
                  _buildWalletStat('Pendiente', pendingEarnings, const Color(0xFFFFAB00)),
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
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
            const Color(0xFF36B37E),
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
                hasDebt ? const Color(0xFFFF5630) : const Color(0xFF0052CC),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5E6C84),
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
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: 'Historial de Pagos',
            subtitle: 'Revisa tus transacciones pasadas',
            color: const Color(0xFF6554C0),
            onTap: () => _showPaymentInfoDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.support_agent_rounded,
            title: 'Centro de Ayuda',
            subtitle: 'Contacta con soporte técnico',
            color: const Color(0xFF0052CC),
            onTap: () => _showSupportDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
            color: const Color(0xFF5E6C84),
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
      borderRadius: BorderRadius.circular(24),
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E6C84),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFDFE1E6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 76),
      child: Divider(height: 1, color: Color(0xFFF4F5F7)),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: widget.onSignOut,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFEBE6),
        foregroundColor: const Color(0xFFBF2600),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Cerrar Sesión',
            style: TextStyle(
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
      ),
    );
  }

  void _showPaymentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6554C0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_outlined, color: Color(0xFF6554C0), size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sistema de Pagos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF172B4D)),
            ),
            const SizedBox(height: 24),
            _buildDialogInfoRow('Comisión Técnico', '70%'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFEBECF0)),
            ),
            _buildDialogInfoRow('Comisión Admin', '30%'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Recuerda pagar tus comisiones antes de las 10 PM para evitar bloqueos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5E6C84), fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF0052CC), fontWeight: FontWeight.bold)),
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
          Text(label, style: const TextStyle(color: Color(0xFF5E6C84), fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF172B4D), fontSize: 15)),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF0052CC),
              child: Icon(Icons.support_agent, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Soporte Técnico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF172B4D)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jose David Lobo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0052CC)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: Color(0xFF5E6C84)),
                      SizedBox(width: 12),
                      Text('+57 324 440 6860', style: TextStyle(color: Color(0xFF172B4D), fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 18, color: Color(0xFF5E6C84)),
                      SizedBox(width: 12),
                      Text('8:00 AM - 8:00 PM', style: TextStyle(color: Color(0xFF172B4D), fontWeight: FontWeight.w500)),
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
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
        ],
      ),
    );
  }
}

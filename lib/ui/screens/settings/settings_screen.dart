import 'package:flutter/material.dart';

import '../../../data/auth/auth_service.dart';
import '../../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _savingName = false;
  bool _savingEmail = false;
  bool _savingPassword = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cerrar sesión: $e')));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Introduce un nombre.');
      return;
    }
    setState(() => _savingName = true);
    try {
      await _auth.updateDisplayName(name);
      _toast('Nombre actualizado.');
    } catch (e) {
      _toast('No se pudo actualizar el nombre: $e');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();
    final password = _emailPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Introduce el nuevo correo y tu contraseña actual.');
      return;
    }
    setState(() => _savingEmail = true);
    try {
      await _auth.updateEmail(currentPassword: password, newEmail: email);
      _toast('Correo actualizado.');
    } catch (e) {
      _toast('No se pudo actualizar el correo: $e');
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _toast('Rellena todos los campos de contraseña.');
      return;
    }
    if (next != confirm) {
      _toast('Las contraseñas no coinciden.');
      return;
    }
    if (next.length < 8) {
      _toast('La nueva contraseña debe tener al menos 8 caracteres.');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await _auth.updatePassword(currentPassword: current, newPassword: next);
      _toast('Contraseña actualizada.');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      _toast('No se pudo actualizar la contraseña: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _auth.currentUser?.email ?? 'Sin email';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(theme, 'Perfil'),
              _ProfileCard(
                theme: theme,
                nameController: _nameController,
                emailController: _emailController,
                emailPasswordController: _emailPasswordController,
                onSaveName: _savingName ? null : _saveName,
                onSaveEmail: _savingEmail ? null : _saveEmail,
                savingName: _savingName,
                savingEmail: _savingEmail,
              ),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Cambiar contraseña'),
              _PasswordCard(
                theme: theme,
                currentController: _currentPasswordController,
                newController: _newPasswordController,
                confirmController: _confirmPasswordController,
                onSave: _savingPassword ? null : _savePassword,
                saving: _savingPassword,
              ),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Sesión'),
              _SessionCard(
                theme: theme,
                email: email,
                onSignOut: _signingOut ? null : _signOut,
                signingOut: _signingOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.theme,
    required this.nameController,
    required this.emailController,
    required this.emailPasswordController,
    required this.onSaveName,
    required this.onSaveEmail,
    required this.savingName,
    required this.savingEmail,
  });

  final ThemeData theme;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController emailPasswordController;
  final VoidCallback? onSaveName;
  final VoidCallback? onSaveEmail;
  final bool savingName;
  final bool savingEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actualiza tu nombre y correo asociado a la cuenta.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _textFieldWithButton(
            controller: nameController,
            label: 'Nombre',
            icon: Icons.person_outline,
            buttonLabel: 'Guardar',
            onPressed: onSaveName,
            loading: savingName,
          ),
          const SizedBox(height: 10),
          _textFieldWithButton(
            controller: emailController,
            label: 'Correo',
            icon: Icons.email_outlined,
            buttonLabel: 'Guardar',
            onPressed: onSaveEmail,
            loading: savingEmail,
          ),
          const SizedBox(height: 8),
          Text(
            'Para cambiar el correo, introduce tu contraseña actual:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: emailPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textFieldWithButton({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(buttonLabel),
        ),
      ],
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({
    required this.theme,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.onSave,
    required this.saving,
  });

  final ThemeData theme;
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige una contraseña segura y no la reutilices.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currentController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Repite la nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.save_alt),
            label: const Text('Guardar contraseña'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mínimo 8 caracteres, mezcla mayúsculas, minúsculas y números.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.theme,
    required this.email,
    required this.onSignOut,
    required this.signingOut,
  });

  final ThemeData theme;
  final String email;
  final VoidCallback? onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cierra la sesión activa para volver a la pantalla de inicio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: signingOut
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

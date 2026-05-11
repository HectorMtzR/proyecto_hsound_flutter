import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/greca_divider.dart';

/// Pantalla de configuración y ajustes de la cuenta.
///
/// Permite al usuario alternar preferencias visuales o funcionales (como el
/// modo offline simulado), acceder a los créditos de la aplicación y
/// cerrar de forma segura su sesión en el sistema.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool offlineMode = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _SectionHeader(label: 'PREFERENCIAS', textStyle: textTheme.labelLarge),
          SwitchListTile(
            title: Text('Modo offline', style: textTheme.titleSmall),
            subtitle: Text('Simula la desconexión de red', style: textTheme.labelSmall),
            value: offlineMode,
            onChanged: (val) {
              setState(() => offlineMode = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Modo offline activado' : 'Modo offline desactivado')),
              );
            },
          ),
          const GrecaDivider(
            size: GrecaSize.micro,
            opacity: 0.4,
            tint: AppColors.brandOrange,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),

          _SectionHeader(label: 'ACERCA DE', textStyle: textTheme.labelLarge),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.brandTurquoise),
            title: Text('Información del sistema', style: textTheme.titleSmall),
            trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            onTap: () => context.push('/info'),
          ),
          const GrecaDivider(
            size: GrecaSize.micro,
            opacity: 0.4,
            tint: AppColors.brandOrange,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),

          _SectionHeader(label: 'CUENTA', textStyle: textTheme.labelLarge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('CERRAR SESIÓN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 2),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Cerrar Sesión', style: textTheme.titleLarge),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MockRepository>().logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextStyle? textStyle;
  const _SectionHeader({required this.label, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Text(
        label,
        style: textStyle?.copyWith(color: AppColors.brandOrange, letterSpacing: 1.2),
      ),
    );
  }
}

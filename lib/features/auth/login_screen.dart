import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/greca_divider.dart';

/// Pantalla de autenticación principal de la aplicación.
///
/// Permite a los usuarios iniciar sesión en una cuenta existente o
/// registrar una nueva. Maneja la validación local básica y gestiona
/// los estados de carga y errores de red durante la comunicación con el backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Define si la vista actual es para Iniciar Sesión (true) o Registro (false).
  bool isLogin = true;

  /// Indica si hay una petición asíncrona en proceso para mostrar el indicador de carga.
  bool isLoading = false;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);
    final repo = context.read<MockRepository>();

    try {
      if (isLogin) {
        await repo.login(emailCtrl.text.trim(), passCtrl.text.trim());
      } else {
        if (nameCtrl.text.trim().isEmpty) {
          throw Exception('Por favor ingresa tu nombre');
        }
        await repo.register(emailCtrl.text.trim(), passCtrl.text.trim(), nameCtrl.text.trim());
      }
    } catch (e) {
      final String errorString = e.toString();
      String userMessage = 'Ocurrió un error inesperado.';

      if (errorString.contains('network-request-failed') || errorString.contains('SocketException')) {
        userMessage = 'Sin conexión a internet. Revisa tu red y vuelve a intentarlo.';
      } else {
        userMessage = errorString.replaceAll('Exception: ', '').split(']').last.trim();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HSound',
                style: textTheme.displayLarge?.copyWith(color: AppColors.brandOrange),
              ),
              const SizedBox(height: AppSpacing.sm),
              const GrecaDivider(
                size: GrecaSize.small,
                opacity: 0.7,
                tint: AppColors.brandOrange,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (!isLogin) ...[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tu Nombre (ej. Hector)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Contraseña (mínimo 6 caracteres)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE'),
                      ),
                    ),

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

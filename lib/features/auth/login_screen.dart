import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

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

  /// Procesa el formulario, valida los datos e interactúa con el repositorio.
  ///
  /// Intercepta errores de Firebase y de red para proveer retroalimentación
  /// visual al usuario mediante un [SnackBar].
  Future<void> _submit() async {
    // Cierra el teclado virtual de la pantalla
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

      // Validación de conectividad (Modo Offline)
      if (errorString.contains('network-request-failed') || errorString.contains('SocketException')) {
        userMessage = 'Sin conexión a internet. Revisa tu red y vuelve a intentarlo.';
      } else {
        // Limpiamos prefijos técnicos para mostrar un mensaje amigable
        userMessage = errorString.replaceAll('Exception: ', '').split(']').last.trim();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage), 
            backgroundColor: Colors.black87,
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
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'HSound', 
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 40),
              
              if (!isLogin) ...[
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true, 
                    fillColor: Colors.white24, 
                    hintText: 'Tu Nombre (ej. Hector)', 
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true, 
                  fillColor: Colors.white24, 
                  hintText: 'Correo electrónico', 
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true, 
                  fillColor: Colors.white24, 
                  hintText: 'Contraseña (mínimo 6 caracteres)', 
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, 
                        minimumSize: const Size(double.infinity, 50)
                      ),
                      onPressed: _submit,
                      child: Text(
                        isLogin ? 'Iniciar sesión' : 'Registrarse', 
                        style: const TextStyle(color: Colors.white, fontSize: 16)
                      ),
                    ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
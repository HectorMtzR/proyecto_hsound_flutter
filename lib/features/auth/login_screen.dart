import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Estados para controlar la vista
  bool isLogin = true; 
  bool isLoading = false;

  // Controladores de texto
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController(); // Necesario para el registro

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  // Función principal que se comunica con Firebase
  Future<void> _submit() async {
    // Escondemos el teclado
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
      // Nota: Si Firebase responde con éxito, 'currentUser' se actualiza.
      // El 'app_router.dart' detecta este cambio automáticamente y te lanza a '/home'.
    } catch (e) {
      // Si hay error (ej. contraseña corta, correo ya existe), lo mostramos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')), 
          backgroundColor: Colors.black87
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: Center(
        child: SingleChildScrollView( // Evita que el teclado tape los inputs
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('HSound', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              
              // Solo mostramos el campo de Nombre si estamos en modo "Registro"
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
              
              // Mostramos la rueda de carga o el botón dependiendo del estado
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
              
              // Botón para alternar entre modos
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
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
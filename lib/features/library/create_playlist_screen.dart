import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart'; 

/// Pantalla para la creación de una nueva lista de reproducción.
///
/// Permite al usuario asignar un nombre y seleccionar una imagen desde
/// la galería del dispositivo. Tras crearla exitosamente en el backend,
/// redirige automáticamente a la vista de detalles de la nueva playlist.
class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final nameCtrl = TextEditingController();
  File? selectedImage;
  bool isUploading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  /// Abre la galería del dispositivo para que el usuario seleccione una imagen.
  /// 
  /// Aplica compresión para optimizar el tamaño de la subida a la nube.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );
    
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  /// Inicia el proceso de validación y creación de la playlist.
  /// 
  /// Se comunica con el repositorio para subir la portada y guardar los
  /// metadatos. Si es exitoso, navega reemplazando la ruta actual por 
  /// la vista de la nueva playlist.
  Future<void> _createPlaylist() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, dale un nombre a tu playlist')),
      );
      return;
    }

    setState(() => isUploading = true);
    
    try {
      final repo = context.read<MockRepository>();
      
      // Obtenemos el ID de la nueva playlist recién creada
      final newPlaylistId = await repo.createPlaylistWithImage(
        nameCtrl.text.trim(), 
        selectedImage
      );
      
      if (mounted) {
        // Navegamos directamente a la nueva playlist usando pushReplacement
        context.pushReplacement('/library/playlist/$newPlaylistId');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Crear Playlist', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: isUploading ? null : _pickImage,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                  image: selectedImage != null 
                      ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: selectedImage == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.white54, size: 50),
                          SizedBox(height: 10),
                          Text('Elegir foto', style: TextStyle(color: Colors.white54)),
                        ],
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 40),
            
            TextField(
              controller: nameCtrl,
              enabled: !isUploading,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Nombre de la playlist',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 20),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
            ),
            
            const SizedBox(height: 60),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: isUploading ? null : _createPlaylist,
                child: isUploading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
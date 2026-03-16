import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart'; // Asegúrate de que esta ruta sea la correcta

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, // Abre la galería del teléfono
      imageQuality: 70, // Comprime la imagen
    );
    
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _createPlaylist() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, dale un nombre a tu playlist')),
      );
      return;
    }

    setState(() => isUploading = true);
    
    try {
      await context.read<MockRepository>().createPlaylistWithImage(
        nameCtrl.text.trim(), 
        selectedImage
      );
      
      // Si todo sale bien, regresamos a la pantalla anterior
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      setState(() => isUploading = false);
      if (mounted) {
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
            
            // --- FOTO DE PORTADA ---
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
            
            // --- NOMBRE DE LA PLAYLIST ---
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
            
            // --- BOTÓN CREAR ---
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
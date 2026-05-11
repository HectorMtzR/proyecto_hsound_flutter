import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';

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

      final newPlaylistId = await repo.createPlaylistWithImage(
        nameCtrl.text.trim(),
        selectedImage,
      );

      if (mounted) {
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Playlist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            GestureDetector(
              onTap: isUploading ? null : _pickImage,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.outline, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowTinted.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: selectedImage != null
                      ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.outline, size: 50),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Elegir foto',
                            style: textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            TextField(
              controller: nameCtrl,
              enabled: !isUploading,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Nombre de la playlist',
                filled: false,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : _createPlaylist,
                child: isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('CREAR PLAYLIST'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

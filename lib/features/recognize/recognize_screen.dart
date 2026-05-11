import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/data/connectivity_watcher.dart';
import '../../core/models/recognition_result.dart';
import '../../core/services/audio_capture_service.dart';
import '../../core/services/recognition/recognition_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/widgets/greca_divider.dart';

enum _RecognizeState { idle, recording, uploading, noMatch }

/// Pantalla de reconocimiento estilo Shazam.
///
/// Estados:
/// - [idle]: botón grande "Toca para escuchar".
/// - [recording]: graba 8s, el botón pulsa con la amplitud del micrófono.
/// - [uploading]: envío a la Cloud Function y espera de respuesta.
/// - [noMatch]: AudD respondió sin coincidencia; permite reintentar.
///
/// Vive fuera del ShellRoute: sin MiniPlayer ni BottomNav.
class RecognizeScreen extends StatefulWidget {
  const RecognizeScreen({super.key});

  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen>
    with SingleTickerProviderStateMixin {
  static const _captureDuration = Duration(seconds: 8);
  static const _tag = 'RecognizeScreen';

  _RecognizeState _state = _RecognizeState.idle;
  double _amplitude = 0;
  StreamSubscription<double>? _ampSub;
  late final AnimationController _progressCtrl;
  final ConnectivityWatcher _connectivity = ConnectivityWatcher();

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: _captureDuration,
    );
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTapListen() async {
    if (_state != _RecognizeState.idle && _state != _RecognizeState.noMatch) {
      return;
    }

    final online = await _connectivity.isOnline();
    if (!mounted) return;
    if (!online) {
      _showSnack('Necesitas conexión para reconocer canciones.');
      return;
    }

    final capture = context.read<AudioCaptureService>();

    final granted = await _ensurePermission(capture);
    if (!granted) return;

    setState(() {
      _state = _RecognizeState.recording;
      _amplitude = 0;
    });
    _progressCtrl
      ..reset()
      ..forward();
    _ampSub = capture.amplitudeStream().listen((value) {
      if (mounted) setState(() => _amplitude = value);
    });

    File audio;
    try {
      audio = await capture.capture(duration: _captureDuration);
    } on AudioCaptureException catch (e) {
      _ampSub?.cancel();
      _ampSub = null;
      if (!mounted) return;
      setState(() => _state = _RecognizeState.idle);
      _showSnack(e.message);
      return;
    } catch (e, s) {
      AppLogger.error('Error inesperado capturando', error: e, stack: s, tag: _tag);
      _ampSub?.cancel();
      _ampSub = null;
      if (!mounted) return;
      setState(() => _state = _RecognizeState.idle);
      _showSnack('No se pudo grabar audio.');
      return;
    }

    _ampSub?.cancel();
    _ampSub = null;
    if (!mounted) return;
    setState(() => _state = _RecognizeState.uploading);

    final service = context.read<RecognitionService>();
    RecognitionResult? result;
    try {
      result = await service.identify(audio);
    } on RecognitionException catch (e) {
      if (!mounted) return;
      setState(() => _state = _RecognizeState.idle);
      _showSnack(e.message);
      return;
    } catch (e, s) {
      AppLogger.error('Error inesperado identificando', error: e, stack: s, tag: _tag);
      if (!mounted) return;
      setState(() => _state = _RecognizeState.idle);
      _showSnack('No se pudo identificar la canción.');
      return;
    } finally {
      // Limpieza del archivo temporal — no es crítica.
      audio.delete().catchError((_) => audio);
    }

    if (!mounted) return;
    if (result == null) {
      setState(() => _state = _RecognizeState.noMatch);
      return;
    }

    context.pushReplacement('/recognize/result', extra: result);
  }

  Future<bool> _ensurePermission(AudioCaptureService capture) async {
    if (await capture.hasPermission()) return true;
    final status = await capture.requestPermission();
    if (status.isGranted) return true;
    if (!mounted) return false;
    await _showPermissionDialog(permanent: status.isPermanentlyDenied);
    return false;
  }

  Future<void> _showPermissionDialog({required bool permanent}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Necesitamos el micrófono'),
        content: Text(
          permanent
              ? 'Activa el permiso de micrófono desde los ajustes del sistema para identificar canciones.'
              : 'Sin acceso al micrófono no podemos escuchar la canción para identificarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    AppLogger.warn(message, tag: _tag);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconocer'),
      ),
      body: Column(
        children: [
          const GrecaDivider(
            size: GrecaSize.small,
            opacity: 0.6,
            tint: AppColors.brandOrange,
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ListenButton(
                      state: _state,
                      amplitude: _amplitude,
                      onTap: _onTapListen,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _StatusBlock(
                      state: _state,
                      progress: _progressCtrl,
                      textTheme: textTheme,
                      onRetry: _onTapListen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({
    required this.state,
    required this.amplitude,
    required this.onTap,
  });

  final _RecognizeState state;
  final double amplitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecording = state == _RecognizeState.recording;
    final isUploading = state == _RecognizeState.uploading;
    final pulseScale = isRecording ? 1.0 + (amplitude * 0.12) : 1.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: pulseScale,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isUploading ? null : onTap,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.brandOrange, AppColors.brandOrangeDeep],
                radius: 0.85,
              ),
              border: Border.all(
                color: AppColors.brandOrangeDeep,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandOrangeDeep.withValues(
                    alpha: isRecording ? 0.55 : 0.3,
                  ),
                  blurRadius: isRecording ? 36 : 18,
                  spreadRadius: isRecording ? 4 : 1,
                ),
              ],
            ),
            child: Center(
              child: isUploading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: AppColors.onPrimary,
                        strokeWidth: 4,
                      ),
                    )
                  : const Icon(
                      Icons.graphic_eq,
                      size: 84,
                      color: AppColors.onPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.state,
    required this.progress,
    required this.textTheme,
    required this.onRetry,
  });

  final _RecognizeState state;
  final AnimationController progress;
  final TextTheme textTheme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _RecognizeState.idle:
        return Column(
          children: [
            Text(
              'Toca para escuchar',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Acerca el teléfono a la música y déjanos\nidentificar lo que está sonando.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      case _RecognizeState.recording:
        return Column(
          children: [
            Text('Escuchando…', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: progress,
                builder: (_, _) => LinearProgressIndicator(
                  value: progress.value,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
          ],
        );
      case _RecognizeState.uploading:
        return Text('Identificando…', style: textTheme.titleMedium);
      case _RecognizeState.noMatch:
        return Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No se reconoció la canción',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Acerca más el micrófono o vuelve a\nintentarlo cuando suene más fuerte.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        );
    }
  }
}

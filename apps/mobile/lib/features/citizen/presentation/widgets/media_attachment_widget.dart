// lib/features/citizen/presentation/widgets/media_attachment_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/enhanced_report_entity.dart';

class MediaAttachmentWidget extends StatefulWidget {
  final List<File> initialFiles;
  final Function(List<File>) onFilesChanged;
  final int maxFiles;
  final int maxFileSizeMB;
  final bool allowVideos;

  const MediaAttachmentWidget({
    super.key,
    this.initialFiles = const [],
    required this.onFilesChanged,
    this.maxFiles = 5,
    this.maxFileSizeMB = 50,
    this.allowVideos = true,
  });

  @override
  State<MediaAttachmentWidget> createState() => _MediaAttachmentWidgetState();
}

class _MediaAttachmentWidgetState extends State<MediaAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();
  List<File> _attachedFiles = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _attachedFiles = List.from(widget.initialFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attached files
        if (_attachedFiles.isNotEmpty) ...[
          ...List.generate(_attachedFiles.length, (index) {
            return _buildFileItem(_attachedFiles[index], index);
          }),
          const SizedBox(height: 12),
        ],

        // Processing indicator
        if (_isProcessing)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                SizedBox(width: 12),
                Text('Comprimiendo archivo...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),

        // Add button
        if (_attachedFiles.length < widget.maxFiles && !_isProcessing)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showMediaPicker,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _attachedFiles.isEmpty
                    ? 'Adjuntar imagen o video'
                    : 'Agregar otro archivo (${_attachedFiles.length}/${widget.maxFiles})',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Adjuntar evidencia',
                style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              _buildPickerOption(
                icon: Icons.camera_alt_rounded,
                title: 'Tomar foto',
                subtitle: 'Usar la camara',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(ImageSource.camera, MediaType.image);
                },
              ),
              _buildPickerOption(
                icon: Icons.photo_library_rounded,
                title: 'Elegir de galeria',
                subtitle: 'Seleccionar imagen existente',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(ImageSource.gallery, MediaType.image);
                },
              ),
              if (widget.allowVideos) ...[
                _buildPickerOption(
                  icon: Icons.videocam_rounded,
                  title: 'Grabar video',
                  subtitle: 'Maximo 2 minutos',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMedia(ImageSource.camera, MediaType.video);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.video_library_rounded,
                  title: 'Video de galeria',
                  subtitle: 'Seleccionar video existente',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMedia(ImageSource.gallery, MediaType.video);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(title, style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildFileItem(File file, int index) {
    final isVideo = _isVideoFile(file.path);
    final fileName = path.basename(file.path);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Preview
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.border,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isVideo
                  ? const Icon(Icons.videocam_rounded, color: AppTheme.textSecondary)
                  : Image.file(file, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.textTertiary)),
            ),
          ),
          const SizedBox(width: 10),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (context, snapshot) {
                    final size = snapshot.data ?? 0;
                    return Text(
                      '${_formatFileSize(size)} · ${isVideo ? 'Video' : 'Imagen'}',
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
                    );
                  },
                ),
              ],
            ),
          ),

          // Preview button
          IconButton(
            icon: const Icon(Icons.visibility_rounded, size: 20),
            onPressed: () => _previewFile(file),
            color: AppTheme.primary,
            visualDensity: VisualDensity.compact,
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => _removeFile(index),
            color: AppTheme.emergency,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, MediaType type) async {
    if (_attachedFiles.length >= widget.maxFiles) {
      _showError('Maximo ${widget.maxFiles} archivos permitidos');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      XFile? pickedFile;

      if (type == MediaType.image) {
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
        );
      } else {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );
      }

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        // Check size
        final fileSize = await file.length();
        final maxSizeBytes = widget.maxFileSizeMB * 1024 * 1024;

        if (fileSize > maxSizeBytes) {
          _showError('El archivo es demasiado grande. Maximo ${widget.maxFileSizeMB}MB.');
          return;
        }

        // Compress image
        if (type == MediaType.image) {
          file = await _compressImage(file);
        }

        setState(() => _attachedFiles.add(file));
        widget.onFilesChanged(_attachedFiles);
      }
    } catch (e) {
      _showError('Error al seleccionar archivo: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
      );

      if (result != null) {
        final compressed = File(result.path);
        final originalSize = await file.length();
        final compressedSize = await compressed.length();
        debugPrint('Image compressed: ${_formatFileSize(originalSize)} -> ${_formatFileSize(compressedSize)}');
        return compressed;
      }
    } catch (e) {
      debugPrint('Compression failed, using original: $e');
    }
    return file;
  }

  void _removeFile(int index) {
    setState(() => _attachedFiles.removeAt(index));
    widget.onFilesChanged(_attachedFiles);
  }

  void _previewFile(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPreviewScreen(file: file),
        fullscreenDialog: true,
      ),
    );
  }

  bool _isVideoFile(String filePath) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final extension = path.extension(filePath).toLowerCase();
    return videoExtensions.contains(extension);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.emergency,
      ),
    );
  }
}

// Screen para previsualizar archivos
class MediaPreviewScreen extends StatelessWidget {
  final File file;

  const MediaPreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoFile(file.path);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          path.basename(file.path),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: isVideo
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text('Vista previa de video', style: TextStyle(color: Colors.white)),
                ],
              )
            : InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
      ),
    );
  }

  bool _isVideoFile(String filePath) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final extension = path.extension(filePath).toLowerCase();
    return videoExtensions.contains(extension);
  }
}

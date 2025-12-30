// lib/features/citizen/presentation/widgets/media_attachment_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
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
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Fotos y Videos (Opcional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_attachedFiles.length}/${widget.maxFiles}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons
                if (_attachedFiles.length < widget.maxFiles && !_isProcessing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cámara',
                          icon: Icons.camera_alt,
                          onPressed: () => _pickMedia(ImageSource.camera, MediaType.image),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Galería',
                          icon: Icons.photo_library,
                          isOutlined: true,
                          onPressed: () => _pickMedia(ImageSource.gallery, MediaType.image),
                        ),
                      ),
                    ],
                  ),
                  if (widget.allowVideos) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Video',
                            icon: Icons.videocam,
                            isOutlined: true,
                            onPressed: () => _pickMedia(ImageSource.camera, MediaType.video),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'Video Galería',
                            icon: Icons.video_library,
                            isOutlined: true,
                            onPressed: () => _pickMedia(ImageSource.gallery, MediaType.video),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                
                // Processing indicator
                if (_isProcessing) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Procesando archivo...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // File list
                if (_attachedFiles.isNotEmpty) ...[
                  const Text(
                    'Archivos adjuntos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_attachedFiles.length, (index) {
                    return _buildFileItem(_attachedFiles[index], index);
                  }),
                ] else if (!_isProcessing) ...[
                  _buildEmptyState(),
                ],
                
                // Guidelines
                const SizedBox(height: 16),
                _buildGuidelines(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(File file, int index) {
    final isVideo = _isVideoFile(file.path);
    final fileName = path.basename(file.path);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Preview
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isVideo
                  ? _buildVideoPreview(file)
                  : _buildImagePreview(file),
            ),
          ),
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (context, snapshot) {
                    final size = snapshot.data ?? 0;
                    return Text(
                      '${_formatFileSize(size)} • ${isVideo ? 'Video' : 'Imagen'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                if (isVideo) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Se comprimirá automáticamente',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _previewFile(file),
                color: AppTheme.primaryColor,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _removeFile(index),
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      },
    );
  }

  Widget _buildVideoPreview(File file) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.black,
          child: const Icon(
            Icons.videocam,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.photo_camera,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No hay archivos adjuntos',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Agrega fotos o videos para proporcionar evidencia',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Consejos para mejores evidencias:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...['Toma fotos claras y bien iluminadas', 'Incluye el problema completo en la imagen', 'Los videos se comprimen automáticamente', 'Máximo ${widget.maxFileSizeMB}MB por archivo']
              .map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, MediaType type) async {
    if (_attachedFiles.length >= widget.maxFiles) {
      _showError('Máximo ${widget.maxFiles} archivos permitidos');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      XFile? pickedFile;
      
      if (type == MediaType.image) {
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
      } else {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );
      }

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        
        // Verificar tamaño
        final fileSize = await file.length();
        final maxSizeBytes = widget.maxFileSizeMB * 1024 * 1024;
        
        if (fileSize > maxSizeBytes) {
          _showError('El archivo es demasiado grande. Máximo ${widget.maxFileSizeMB}MB.');
          return;
        }
        
        // Comprimir si es imagen
        if (type == MediaType.image) {
          file = await _compressImage(file);
        }
        
        setState(() {
          _attachedFiles.add(file);
        });
        
        widget.onFilesChanged(_attachedFiles);
      }
    } catch (e) {
      _showError('Error al seleccionar archivo: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    // Image compression is handled by image_picker's imageQuality parameter
    // Return the file as-is since we already set imageQuality: 85 when picking
    return file;
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
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
        backgroundColor: AppTheme.errorColor,
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
            ? _buildVideoPlayer()
            : _buildImageViewer(),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      child: Image.file(
        file,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            color: Colors.white,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Vista previa de video',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'El video se reproducirá al enviar la denuncia',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  bool _isVideoFile(String filePath) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final extension = path.extension(filePath).toLowerCase();
    return videoExtensions.contains(extension);
  }
}
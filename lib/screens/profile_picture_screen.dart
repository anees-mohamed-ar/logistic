import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';

class ProfilePictureScreen extends StatefulWidget {
  const ProfilePictureScreen({Key? key}) : super(key: key);

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  PlatformFile? _pickedImage;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _uploadStatus = '';
  final IdController _idController = Get.find<IdController>();

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImage = result.files.single;
      });
    }
  }

  Future<bool> _uploadProfilePicture() async {
    if (_pickedImage == null || _pickedImage!.bytes == null) return false;

    final dioInstance = dio.Dio();
    final formData = dio.FormData.fromMap({
      'profileImage': dio.MultipartFile.fromBytes(
        _pickedImage!.bytes!,
        filename: _pickedImage!.name,
      ),
    });

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final response = await dioInstance.post(
        '${ApiConfig.baseUrl}/profile/profile-picture/${_idController.userId.value}',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = sent / total;
            final speed = sent / 1024; // KB uploaded
            final totalSize = total / 1024; // KB total
            setState(() {
              _uploadProgress = progress;
              _uploadStatus =
                  'Uploading: ${(progress * 100).toStringAsFixed(1)}% (${speed.toStringAsFixed(1)} KB / ${totalSize.toStringAsFixed(1)} KB)';
            });
          } else {
            setState(() {
              _uploadStatus = 'Uploading: ${sent} bytes sent';
            });
          }
        },
        options: dio.Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = 'Upload completed!';
        });
        _idController.updateProfilePictureTimestamp(); // Update global timestamp
        await Future.delayed(const Duration(seconds: 1));
        return true;
      } else {
        setState(() {
          _uploadStatus = 'Upload failed: ${response.statusCode}';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Upload error: $e';
      });
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildCurrentProfilePicture() {
    final userId = _idController.userId.value;
    final hasImage = userId.isNotEmpty;
    final imageUrl = hasImage ? '${ApiConfig.baseUrl}/profile/profile-picture/$userId?t=${_idController.profilePictureTimestamp.value}' : '';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white,
        child: hasImage
            ? ClipOval(
                child: Image.network(
                  imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackAvatar();
                  },
                ),
              )
            : _buildFallbackAvatar(),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final name = _idController.userName.value;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 48,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Picture'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Current Profile Picture
            const Text(
              'Current Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCurrentProfilePicture(),
            const SizedBox(height: 32),

            // Upload Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload New Picture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_camera_back_outlined),
                            label: const Text('Select Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2A44),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pickedImage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_pickedImage!.name}',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadProfilePicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2A44),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Upload Picture'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Upload Progress
            if (_isUploading) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _uploadProgress == 1.0
                            ? Icons.check_circle
                            : Icons.upload,
                        size: 16,
                        color: _uploadProgress == 1.0 ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _uploadProgress == 1.0
                                ? Colors.green
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (_uploadProgress > 0 && _uploadProgress < 1.0)
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logistic/api_config.dart';

class TruckAttachmentsPage extends StatefulWidget {
  final String vechileNumber;

  const TruckAttachmentsPage({Key? key, required this.vechileNumber})
    : super(key: key);

  @override
  State<TruckAttachmentsPage> createState() => _TruckAttachmentsPageState();
}

class _TruckAttachmentsPageState extends State<TruckAttachmentsPage> {
  List<Map<String, dynamic>> attachments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAttachments();
  }

  Future<void> fetchAttachments() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/truckmaster/attachments/${Uri.encodeComponent(widget.vechileNumber)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['attachments'] as List<dynamic>? ?? [];

        setState(() {
          attachments = list
              .map(
                (a) => {
                  'name': a['originalName']?.toString() ?? 'Unknown',
                  'filename': a['filename']?.toString() ?? '',
                  'size': a['size'] ?? 0,
                  'type': a['mimeType']?.toString() ?? 'unknown',
                  'uploadedAt': a['uploadDate']?.toString() ?? '',
                },
              )
              .toList();
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          attachments = [];
          isLoading = false;
          error = 'No attachments found for this truck';
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to load truck attachments';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error loading attachments: $e';
      });
    }
  }

  Future<void> previewFile(String filename) async {
    try {
      final url = '${ApiConfig.baseUrl}/truckmaster/attachments/file/$filename';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Cannot open file',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error opening file: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> downloadFile(String filename, String originalName) async {
    Directory? downloadDir;

    try {
      final url =
          '${ApiConfig.baseUrl}/truckmaster/attachments/file/$filename/download';

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format: $url');
      }

      if (Platform.isAndroid) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to download and save files to your device. '
              'Files will be saved to your Downloads folder.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          return;
        }

        PermissionStatus status = await Permission.storage.request();

        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (!status.isGranted) {
          if (mounted) {
            final permanentlyDenied = status.isPermanentlyDenied;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  permanentlyDenied
                      ? 'Storage permission is required to download files. Please enable it in app settings.'
                      : 'Storage permission is required to download files.',
                ),
                action: permanentlyDenied
                    ? SnackBarAction(
                        label: 'Settings',
                        onPressed: () async {
                          await openAppSettings();
                        },
                      )
                    : null,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          return;
        }
      }

      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');

        if (!await downloadDir.exists()) {
          final externalDir = await getExternalStorageDirectory();

          if (externalDir != null && await externalDir.exists()) {
            downloadDir = externalDir;
          } else {
            downloadDir = await getApplicationDocumentsDirectory();
          }
        }

        if (downloadDir.path.contains('app_flutter')) {
          downloadDir = Directory('${downloadDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${downloadDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      }

      final fileName = 'TRUCK_${widget.vechileNumber}_$originalName';
      final filePath = '${downloadDir.path}/$fileName';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading file...'),
              ],
            ),
          ),
        );
      }

      final dio = Dio();
      await dio.download(url, filePath);

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        final location =
            downloadDir.path.contains('Download') ||
                downloadDir.path.contains('Downloads')
            ? 'Downloads folder'
            : 'app storage';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File downloaded successfully to $location: $fileName',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) return Icons.picture_as_pdf;
    if (lowerType.contains('image') ||
        lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png')) {
      return Icons.image;
    }
    if (lowerType.contains('word') || lowerType.contains('doc')) {
      return Icons.description;
    }
    if (lowerType.contains('excel') || lowerType.contains('sheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) return Colors.red;
    if (lowerType.contains('image') ||
        lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png')) {
      return Colors.blue;
    }
    if (lowerType.contains('word') || lowerType.contains('doc')) {
      return Colors.blue.shade700;
    }
    if (lowerType.contains('excel') || lowerType.contains('sheet')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Truck Attachments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.vechileNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAttachments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E2A44)),
            SizedBox(height: 16),
            Text(
              'Loading attachments...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.orange.shade400),
              const SizedBox(height: 16),
              Text(
                'No Attachments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchAttachments,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (attachments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_file, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attachments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This truck has no attached files',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return _buildAttachmentCard(attachment);
      },
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    final name = attachment['name'] as String;
    final filename = attachment['filename'] as String;
    final size = attachment['size'] as int;
    final mimeType = attachment['type'] as String;
    final uploadedAt = attachment['uploadedAt'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getFileColor(mimeType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(mimeType),
            color: _getFileColor(mimeType),
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatFileSize(size),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (uploadedAt.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Uploaded: $uploadedAt',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => previewFile(filename),
              tooltip: 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () => downloadFile(filename, name),
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }
}

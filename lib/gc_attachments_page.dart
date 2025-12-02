import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'api_config.dart';
import 'package:logistic/services/gc_pdf_preview_service.dart';

class GCAttachmentsPage extends StatefulWidget {
  final String gcNumber;
  final String companyId;
  final String branchId;

  const GCAttachmentsPage({
    Key? key,
    required this.gcNumber,
    required this.companyId,
    required this.branchId,
  }) : super(key: key);

  @override
  State<GCAttachmentsPage> createState() => _GCAttachmentsPageState();
}

class _GCAttachmentsPageState extends State<GCAttachmentsPage> {
  List<Map<String, dynamic>> attachments = [];
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? invoiceAttachment;
  Map<String, dynamic>? ewayAttachment;

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
      final url =
          Uri.parse(
            '${ApiConfig.baseUrl}/gc/attachments/${widget.gcNumber}',
          ).replace(
            queryParameters: {
              'companyId': widget.companyId,
              if (widget.branchId.isNotEmpty) 'branchId': widget.branchId,
            },
          );

      debugPrint('🔍 Fetching general attachments from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📥 General attachments status: ${response.statusCode}');

      List<Map<String, dynamic>> loadedAttachments = [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final attachmentsList =
              data['data']['attachments'] as List<dynamic>? ?? [];

          loadedAttachments = attachmentsList
              .map(
                (attachment) => {
                  'name': attachment['originalName']?.toString() ?? 'Unknown',
                  'filename': attachment['filename']?.toString() ?? '',
                  'size': attachment['size'] ?? 0,
                  'type': attachment['mimeType']?.toString() ?? 'unknown',
                  'uploadedAt': attachment['uploadDate']?.toString() ?? '',
                  'uploadedBy': attachment['uploadedBy']?.toString() ?? '',
                },
              )
              .toList();

          debugPrint(
            '✅ Loaded ${loadedAttachments.length} general attachments',
          );
        }
      }

      // Fetch dedicated invoice and e-way attachments
      final typedUrl =
          Uri.parse(
            '${ApiConfig.baseUrl}/gc/attachments/invoice-e-way/${widget.gcNumber}',
          ).replace(
            queryParameters: {
              'companyId': widget.companyId,
              if (widget.branchId.isNotEmpty) 'branchId': widget.branchId,
            },
          );

      debugPrint('🔍 Fetching invoice/e-way attachments from: $typedUrl');

      Map<String, dynamic>? loadedInvoice;
      Map<String, dynamic>? loadedEway;

      final typedResponse = await http.get(
        typedUrl,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📥 Invoice/e-way status: ${typedResponse.statusCode}');

      if (typedResponse.statusCode == 200) {
        final typedBody =
            jsonDecode(typedResponse.body) as Map<String, dynamic>;
        final typedData = typedBody['data'] as Map<String, dynamic>?;

        if (typedBody['success'] == true && typedData != null) {
          final inv = typedData['invoiceAttachment'] as Map<String, dynamic>?;
          final eway = typedData['eWayAttachment'] as Map<String, dynamic>?;

          if (inv != null && inv.isNotEmpty) {
            loadedInvoice = {
              'name': inv['originalName']?.toString() ?? 'Invoice',
              'filename': inv['filename']?.toString() ?? '',
              'size': inv['size'] ?? 0,
              'type': inv['mimeType']?.toString() ?? 'unknown',
              'uploadedAt': inv['uploadDate']?.toString() ?? '',
              'uploadedBy': inv['uploadedBy']?.toString() ?? '',
            };
          }

          if (eway != null && eway.isNotEmpty) {
            loadedEway = {
              'name': eway['originalName']?.toString() ?? 'E-way bill',
              'filename': eway['filename']?.toString() ?? '',
              'size': eway['size'] ?? 0,
              'type': eway['mimeType']?.toString() ?? 'unknown',
              'uploadedAt': eway['uploadDate']?.toString() ?? '',
              'uploadedBy': eway['uploadedBy']?.toString() ?? '',
            };
          }
        }
      }

      setState(() {
        attachments = loadedAttachments;
        invoiceAttachment = loadedInvoice;
        ewayAttachment = loadedEway;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      debugPrint('❌ Error fetching attachments: $e');
      setState(() {
        error = 'Error loading attachments: $e';
        isLoading = false;
      });
    }
  }

  Future<void> previewFile(String filename) async {
    try {
      final url = '${ApiConfig.baseUrl}/gc/files/$filename';
      final uri = Uri.parse(url);

      debugPrint('🔍 Opening file: $url');

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
      debugPrint('❌ Error opening file: $e');
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
      final url = '${ApiConfig.baseUrl}/gc/files/$filename';

      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format: $url');
      }

      debugPrint('📥 Attempting to download attachment: $url');

      // Request storage permissions
      if (Platform.isAndroid) {
        debugPrint('Checking Android storage permission...');

        // First show explanation dialog
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
          debugPrint('User cancelled permission request');
          return;
        }

        // Directly request permission - this will show the system permission dialog
        PermissionStatus status = await Permission.storage.request();

        debugPrint('WRITE_EXTERNAL_STORAGE permission result: $status');

        // If WRITE_EXTERNAL_STORAGE is denied, try MANAGE_EXTERNAL_STORAGE for Android 11+
        if (!status.isGranted) {
          debugPrint(
            'WRITE_EXTERNAL_STORAGE denied, trying MANAGE_EXTERNAL_STORAGE...',
          );
          status = await Permission.manageExternalStorage.request();
          debugPrint('MANAGE_EXTERNAL_STORAGE permission result: $status');
        }

        debugPrint('Final permission granted: ${status.isGranted}');
        debugPrint('Final permission denied: ${status.isDenied}');
        debugPrint(
          'Final permission permanently denied: ${status.isPermanentlyDenied}',
        );

        if (!status.isGranted) {
          debugPrint('Permission not granted, showing snackbar...');
          if (mounted) {
            // Check if permanently denied
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
                    : SnackBarAction(
                        label: 'Retry',
                        onPressed: () async {
                          // Retry download after user potentially grants permission
                          await downloadFile(filename, originalName);
                        },
                      ),
                duration: const Duration(seconds: 8),
              ),
            );
          }
          return;
        } else {
          debugPrint('Permission granted, proceeding with download...');
        }
      }

      // Get download directory
      if (Platform.isAndroid) {
        // Try Downloads folder first (Android 10 and below, or with MANAGE_EXTERNAL_STORAGE)
        downloadDir = Directory('/storage/emulated/0/Download');

        if (!await downloadDir.exists()) {
          // Fallback to external storage directory
          final externalDir = await getExternalStorageDirectory();

          if (externalDir != null && await externalDir.exists()) {
            downloadDir = externalDir;
          } else {
            // Final fallback: app documents directory
            downloadDir = await getApplicationDocumentsDirectory();
          }
        }

        // Create Download subfolder in app documents if using app directory
        if (downloadDir.path.contains('app_flutter')) {
          downloadDir = Directory('${downloadDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        }
      } else {
        // iOS and other platforms
        downloadDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${downloadDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      }

      // Create full file path with GC number prefix
      final fileName = 'GC_${widget.gcNumber}_$originalName';
      final filePath = '${downloadDir.path}/$fileName';

      debugPrint('Downloading to: $filePath');

      // Show download progress dialog
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

      // Download file using Dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success message with open location button
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
            action: SnackBarAction(
              label: 'Open Location',
              onPressed: () => _openFileLocation(filePath),
            ),
            duration: const Duration(
              seconds: 5,
            ), // Keep it visible longer for action
          ),
        );
      }

      debugPrint('Successfully downloaded file: $filePath');
    } catch (e) {
      debugPrint('❌ Failed to download attachment: $e');

      // Close progress dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _previewInvoiceAttachment() async {
    final gcNumber = widget.gcNumber;
    final companyId = widget.companyId;

    try {
      final url =
          '${ApiConfig.baseUrl}/gc/attachments/invoice/file/$gcNumber?companyId=$companyId';
      final uri = Uri.parse(url);

      debugPrint('🔍 Opening invoice attachment: $url');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Cannot open invoice attachment',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening invoice attachment: $e');
      Fluttertoast.showToast(
        msg: 'Error opening invoice attachment: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _previewEwayAttachment() async {
    final gcNumber = widget.gcNumber;
    final companyId = widget.companyId;

    try {
      final url =
          '${ApiConfig.baseUrl}/gc/attachments/e-way/file/$gcNumber?companyId=$companyId';
      final uri = Uri.parse(url);

      debugPrint('🔍 Opening e-way bill attachment: $url');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Cannot open e-way bill attachment',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening e-way bill attachment: $e');
      Fluttertoast.showToast(
        msg: 'Error opening e-way bill attachment: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _downloadTypedAttachment({
    required String type,
    required String originalName,
  }) async {
    Directory? downloadDir;

    try {
      final gcNumber = widget.gcNumber;
      final companyId = widget.companyId;

      final basePath = type == 'invoice' ? 'invoice' : 'e-way';
      final url =
          '${ApiConfig.baseUrl}/gc/attachments/$basePath/file/$gcNumber?companyId=$companyId';

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format: $url');
      }

      debugPrint('📥 Attempting to download $type attachment: $url');

      // Request storage permissions (same as downloadFile)
      if (Platform.isAndroid) {
        debugPrint('Checking Android storage permission...');

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
          debugPrint('User cancelled permission request');
          return;
        }

        PermissionStatus status = await Permission.storage.request();

        debugPrint('WRITE_EXTERNAL_STORAGE permission result: $status');

        if (!status.isGranted) {
          debugPrint(
            'WRITE_EXTERNAL_STORAGE denied, trying MANAGE_EXTERNAL_STORAGE...',
          );
          status = await Permission.manageExternalStorage.request();
          debugPrint('MANAGE_EXTERNAL_STORAGE permission result: $status');
        }

        debugPrint('Final permission granted: ${status.isGranted}');

        if (!status.isGranted) {
          debugPrint('Permission not granted, showing snackbar...');
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

      // Get download directory (same logic as downloadFile)
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

      final fileName = 'GC_${widget.gcNumber}_$originalName';
      final filePath = '${downloadDir.path}/$fileName';

      debugPrint('Downloading $type attachment to: $filePath');

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
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              'Download progress ($type): '
              '${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

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
            action: SnackBarAction(
              label: 'Open Location',
              onPressed: () => _openFileLocation(filePath),
            ),
            duration: const Duration(
              seconds: 5,
            ), // Keep it visible longer for action
          ),
        );
      }

      debugPrint('Successfully downloaded $type attachment: $filePath');
    } catch (e) {
      debugPrint('❌ Failed to download $type attachment: $e');

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

  // Helper method to open file location
  Future<void> _openFileLocation(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Copy filename to clipboard for easy searching
        final fileName = filePath.split('/').last;
        await Clipboard.setData(ClipboardData(text: fileName));

        // Show brief toast that filename was copied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filename copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (Platform.isWindows) {
          // For Windows, open the folder and select the file
          await Process.run('explorer', ['/select,', filePath]);
        } else if (Platform.isAndroid) {
          // For Android, prioritize opening the Downloads folder to avoid app selection issues
          bool fileOpened = false;

          // First try to open the Downloads folder using MediaStore content URI
          try {
            final downloadsUri = Uri.parse(
              'content://com.android.externalstorage.documents/document/primary%3ADownload',
            );
            if (await canLaunchUrl(downloadsUri)) {
              await launchUrl(downloadsUri);
              fileOpened = true;
            }
          } catch (e) {
            debugPrint('Downloads folder opening failed: $e');
          }

          // If folder opening fails, try file-specific content URI (may highlight file)
          if (!fileOpened) {
            try {
              final encodedFileName = Uri.encodeComponent(fileName);
              final fileContentUri = Uri.parse(
                'content://com.android.externalstorage.documents/document/primary%3ADownload%2F$encodedFileName',
              );

              if (await canLaunchUrl(fileContentUri)) {
                await launchUrl(fileContentUri);
                fileOpened = true;
              }
            } catch (e) {
              debugPrint('File-specific content URI failed: $e');
            }
          }

          // Final fallback: show file path dialog with highlighting info
          if (!fileOpened) {
            _showFilePathDialog(filePath, showHighlightInfo: true);
          }
        } else if (Platform.isIOS) {
          // For iOS, try to open the parent directory
          final directory = file.parent;
          final uri = Uri.directory(directory.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        } else {
          // Fallback: try to open the parent directory
          final directory = file.parent;
          final uri = Uri.directory(directory.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening file location: $e');
      // Show file path dialog as fallback
      _showFilePathDialog(filePath, showHighlightInfo: false);
    }
  }

  // Helper method to show file path in a dialog
  void _showFilePathDialog(String filePath, {bool showHighlightInfo = false}) {
    if (mounted) {
      final fileName = filePath.split('/').last;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showHighlightInfo
                      ? 'Your file has been saved to this location:'
                      : 'Your file has been saved to:',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    filePath,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (showHighlightInfo) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Look for this file:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  showHighlightInfo
                      ? 'Open your file manager app, navigate to the Downloads folder, and look for the highlighted file above.'
                      : 'Please open your file manager app and navigate to this location to find your file.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
              'GC Attachments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.gcNumber,
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
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => GCPdfPreviewService.showPdfPreviewFromGCData(
              context,
              widget.gcNumber,
              companyId: widget.companyId,
              branchId: widget.branchId,
            ),
            tooltip: 'PDF Preview',
          ),
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

    final hasAnyAttachments =
        attachments.isNotEmpty ||
        invoiceAttachment != null ||
        ewayAttachment != null;

    if (!hasAnyAttachments) {
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
              'This GC has no attached files',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (invoiceAttachment != null || ewayAttachment != null) ...[
          Text(
            'Invoice & E-way Bill',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (invoiceAttachment != null)
            _buildTypedAttachmentCard(
              invoiceAttachment!,
              label: 'Invoice',
              type: 'invoice',
            ),
          if (ewayAttachment != null)
            _buildTypedAttachmentCard(
              ewayAttachment!,
              label: 'E-way Bill',
              type: 'e-way',
            ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 16),
        ],
        Text(
          'General Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Text(
            'No general attachments',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          )
        else ...[
          for (final attachment in attachments)
            _buildAttachmentCard(attachment),
        ],
      ],
    );
  }

  Widget _buildTypedAttachmentCard(
    Map<String, dynamic> attachment, {
    required String label,
    required String type,
  }) {
    final name = attachment['name'] as String;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
                'Uploaded: ${_formatDate(uploadedAt)}',
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
              onPressed: () {
                if (type == 'invoice') {
                  _previewInvoiceAttachment();
                } else {
                  _previewEwayAttachment();
                }
              },
              tooltip: 'Preview',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () =>
                  _downloadTypedAttachment(type: type, originalName: name),
              tooltip: 'Download',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
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

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    final name = attachment['name'] as String;
    final filename = attachment['filename'] as String;
    final size = attachment['size'] as int;
    final type = attachment['type'] as String;
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
            color: _getFileColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getFileIcon(type), color: _getFileColor(type), size: 28),
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
                'Uploaded: ${_formatDate(uploadedAt)}',
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
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () => downloadFile(filename, name),
              tooltip: 'Download',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

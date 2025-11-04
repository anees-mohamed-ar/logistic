import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Callback types for progress updates
typedef UploadProgressCallback = void Function(double progress, String? fileName);
typedef FileProgressCallback = void Function(String fileName, double progress);

class UploadProgressService {
  final Dio _dio = Dio();

  /// Upload GC with attachments using Dio for real-time progress tracking
  Future<Map<String, dynamic>> uploadGCWithProgress({
    required String url,
    required Map<String, dynamic> formData,
    required List<Map<String, dynamic>> files,
    required UploadProgressCallback onProgress,
    FileProgressCallback? onFileProgress,
    Map<String, String>? headers,
    String method = 'POST', // Default to POST, but allow override
  }) async {
    try {
      final formDataObj = FormData();

      // Add form fields
      formData.forEach((key, value) {
        if (value != null) {
          formDataObj.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add files
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final filePath = file['path'];
        final fileName = file['name'] ?? 'file_$i';

        if (filePath != null && filePath is String && filePath.isNotEmpty) {
          formDataObj.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                filePath,
                filename: fileName,
              ),
            ),
          );
        }
      }

      // Configure Dio options
      final options = Options(
        method: method,
        headers: headers,
        contentType: 'multipart/form-data',
      );

      debugPrint('Making Dio request to: $url');
      debugPrint('HTTP Method: $method');
      debugPrint('Headers: $headers');
      debugPrint('Number of files: ${files.length}');

      try {
        final response = await _dio.request(
          url,
          data: formDataObj,
          options: options,
          onSendProgress: (sent, total) {
            if (total != -1) {
              final overallProgress = sent / total;

              // Calculate per-file progress if we have multiple files
              if (files.isNotEmpty && onFileProgress != null) {
                final currentFileIndex = (overallProgress * files.length).floor().clamp(0, files.length - 1);
                final currentFile = files[currentFileIndex];
                final fileName = currentFile['name'] ?? 'Unknown';

                // Estimate progress for current file
                final fileProgress = (overallProgress * files.length - currentFileIndex);
                onFileProgress(fileName, fileProgress.clamp(0.0, 1.0));
              }

              onProgress(overallProgress.clamp(0.0, 1.0), null);
            }
          },
        );

        debugPrint('Dio request successful, response status: ${response.statusCode}');

        // Ensure progress reaches 100% on completion
        onProgress(1.0, null);

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': response.data,
        };
      } catch (dioError) {
        debugPrint('Dio request failed with error: $dioError');
        debugPrint('Error type: ${dioError.runtimeType}');
        if (dioError is DioException) {
          debugPrint('DioException type: ${dioError.type}');
          debugPrint('DioException message: ${dioError.message}');
          debugPrint('DioException response: ${dioError.response}');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('GC upload failed with general exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload single file with progress
  Future<Map<String, dynamic>> uploadSingleFile({
    required String url,
    required String filePath,
    required String fieldName,
    required UploadProgressCallback onProgress,
    Map<String, String>? headers,
    Map<String, dynamic>? additionalFields,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData();

      // Add additional fields if provided
      if (additionalFields != null) {
        additionalFields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Add file
      formData.files.add(
        MapEntry(
          fieldName,
          await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        ),
      );

      final options = Options(
        method: 'POST',
        headers: headers,
        contentType: 'multipart/form-data',
      );

      final response = await _dio.request(
        url,
        data: formData,
        options: options,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = sent / total;
            onProgress(progress.clamp(0.0, 1.0), fileName);
          }
        },
      );

      // Ensure progress reaches 100%
      onProgress(1.0, fileName);

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      debugPrint('Single file upload failed with DioException: ${e.message}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      return {
        'success': false,
        'error': e.message ?? 'Upload failed',
        'statusCode': e.response?.statusCode,
        'data': e.response?.data,
      };
    } catch (e) {
      debugPrint('Single file upload failed with general exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cancel any ongoing requests
  void cancelRequests() {
    _dio.close(force: true);
  }
}

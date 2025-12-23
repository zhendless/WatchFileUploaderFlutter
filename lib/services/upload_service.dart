import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class UploadResult {
  final bool success;
  final String? errorMessage;
  final int? statusCode;

  UploadResult({required this.success, this.errorMessage, this.statusCode});
}

class UploadService {
  final Dio _dio;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  UploadService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
  }

  // Upload a file to the specified URL
  Future<UploadResult> uploadFile(
    File file,
    String uploadUrl, {
    String fileFieldName = 'file',
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
    Function(int, int)? onProgress,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      try {
        // Check if file exists
        if (!await file.exists()) {
          return UploadResult(success: false, errorMessage: '文件不存在');
        }

        // Get file name
        final fileName = path.basename(file.path);

        // Create form data
        final formData = FormData.fromMap({
          fileFieldName: await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
          'power_station_person': '',
          'dispatch_center_person': '',
          'work_order_id': '',
          'work_record_id': '',
          'split_number': '10',
          ...?additionalFields,
        });

        // Perform upload
        final response = await _dio.post(
          uploadUrl,
          data: formData,
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
          onSendProgress: onProgress,
        );

        // Check response
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return UploadResult(success: true, statusCode: response.statusCode);
        } else {
          final errorMsg = '上传失败: HTTP ${response.statusCode}';

          // Don't retry on client errors (4xx)
          if (response.statusCode != null &&
              response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            return UploadResult(
              success: false,
              errorMessage: errorMsg,
              statusCode: response.statusCode,
            );
          }

          // Retry on server errors (5xx)
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay * attempts);
            continue;
          }

          return UploadResult(
            success: false,
            errorMessage: errorMsg,
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        String errorMessage;

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = '上传超时';
            break;
          case DioExceptionType.badResponse:
            errorMessage = '服务器响应错误: ${e.response?.statusCode}';
            break;
          case DioExceptionType.connectionError:
            errorMessage = '网络连接失败';
            break;
          case DioExceptionType.cancel:
            errorMessage = '上传已取消';
            return UploadResult(success: false, errorMessage: errorMessage);
          default:
            errorMessage = '上传失败: ${e.message}';
        }

        // Retry on network errors
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay * attempts);
          continue;
        }

        return UploadResult(success: false, errorMessage: errorMessage);
      } catch (e) {
        final errorMessage = '未知错误: $e';

        if (attempts < maxRetries) {
          await Future.delayed(retryDelay * attempts);
          continue;
        }

        return UploadResult(success: false, errorMessage: errorMessage);
      }
    }

    return UploadResult(success: false, errorMessage: '上传失败: 已达到最大重试次数');
  }

  // Test connection to upload URL
  Future<bool> testConnection(String uploadUrl) async {
    try {
      final response = await _dio.head(
        uploadUrl,
        options: Options(
          validateStatus: (status) => true,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}

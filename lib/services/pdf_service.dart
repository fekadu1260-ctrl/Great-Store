import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/pdf_model.dart';
import 'auth_service.dart';
import 'api_config.dart';

class PdfService {
  final AuthService _authService = AuthService();

  Future<List<PdfModel>> fetchPdfs() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/pdfs'));
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => PdfModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load PDFs');
  }

  Future<File> downloadPdfWithProgress({
    required String pdfId,
    required String fileName,
    required Function(double progress, int bytesReceived, int totalBytes) onProgress,
  }) async {
    final token = await _authService.getCustomerToken();
    if (token == null || token.isEmpty) {
      throw Exception('User authentication required. Please log in again.');
    }

    final downloadUrl = Uri.parse('${ApiConfig.baseUrl}/pdfs/$pdfId/download');
    final client = http.Client();

    try {
      final request = http.Request('GET', downloadUrl);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json, application/pdf';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status code: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int bytesReceived = 0;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName.pdf';
      final file = File(filePath);

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        bytesReceived += chunk.length;
        sink.add(chunk);

        double progress = totalBytes > 0 ? (bytesReceived / totalBytes) : 0.0;
        onProgress(progress, bytesReceived, totalBytes);
      }

      await sink.flush();
      await sink.close();

      return file;
    } finally {
      client.close();
    }
  }
}

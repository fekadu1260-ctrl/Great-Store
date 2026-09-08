import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/download_dialog.dart';
import 'pdf_viewer_screen.dart';

class MyDownloadsScreen extends StatefulWidget {
  const MyDownloadsScreen({super.key});

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen> {
  Future<void> startPdfDownload(String pdfId, String pdfTitle, String paymentId, String pdfUrl) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadDialog(pdfId: pdfId, pdfTitle: pdfTitle),
    );

    if (!mounted) return;

    if (result is File) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: ${result.path}')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            paymentId: paymentId,
            pdfUrl: pdfUrl,
          ),
        ),
      );
    } else if (result != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Download Error'),
          content: Text(result.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Downloads')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => startPdfDownload('sample_id', 'Sample PDF', 'pay_123', 'http://example.com/sample.pdf'),
          child: const Text('Download PDF'),
        ),
      ),
    );
  }
}

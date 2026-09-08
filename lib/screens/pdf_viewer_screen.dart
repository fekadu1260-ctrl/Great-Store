import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/payment_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String paymentId;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.paymentId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PaymentService paymentService = PaymentService();

  bool loading = true;
  bool approved = false;
  bool downloading = false;
  String status = 'pending';

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final result = await paymentService.checkPaymentStatus(
        widget.paymentId,
      );

      if (!mounted) return;

      final normalized = result.trim().toLowerCase();

      setState(() {
        status = normalized.isEmpty ? 'unknown' : normalized;
        approved =
            normalized == 'approved' || normalized == 'paid';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        status = 'error';
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (downloading) return;

    if (widget.pdfUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download link is not available.'),
        ),
      );
      return;
    }

    setState(() {
      downloading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(widget.pdfUrl),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed: HTTP ${response.statusCode}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();

      final file = File(
        '${directory.path}/Great_Store_Item_${widget.paymentId}.pdf',
      );

      await file.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF downloaded successfully.\n${file.path}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download failed: $e',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Item Viewer'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!approved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Item Access'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_top,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Verification Pending',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Current status: ${status.toUpperCase()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => loading = true);
                    _checkAccess();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Viewer'),
        actions: [
          IconButton(
            onPressed: downloading ? null : _downloadPdf,
            tooltip: 'Download PDF',
            icon: downloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
      ),
    );
  }
}

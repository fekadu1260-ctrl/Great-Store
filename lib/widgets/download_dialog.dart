import 'dart:io';
import 'package:flutter/material.dart';
import '../services/pdf_service.dart';

class DownloadDialog extends StatefulWidget {
  final String pdfId;
  final String pdfTitle;

  const DownloadDialog({super.key, required this.pdfId, required this.pdfTitle});

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  final PdfService _pdfService = PdfService();
  double _downloadProgress = 0.0;
  String _statusText = 'Starting download...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      File downloadedFile = await _pdfService.downloadPdfWithProgress(
        pdfId: widget.pdfId,
        fileName: widget.pdfTitle,
        onProgress: (progress, received, total) {
          setState(() {
            _downloadProgress = progress;
            if (total > 0) {
              _statusText = '${(progress * 100).toStringAsFixed(0)}% (${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB)';
            } else {
              _statusText = '${(received / 1024 / 1024).toStringAsFixed(1)} MB downloaded';
            }
          });
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(downloadedFile);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Downloading ${widget.pdfTitle}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            minHeight: 10,
          ),
          const SizedBox(height: 16),
          Text(_statusText),
        ],
      ),
    );
  }
}

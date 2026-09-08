import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pdf_model.dart';
import '../services/payment_service.dart';
import 'pdf_viewer_screen.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final PdfModel pdf;
  final String paymentId;

  const PaymentWaitingScreen({
    super.key,
    required this.pdf,
    required this.paymentId,
  });

  @override
  State<PaymentWaitingScreen> createState() =>
      _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState
    extends State<PaymentWaitingScreen> {
  final PaymentService paymentService = PaymentService();

  String status = 'pending';
  String? errorMessage;
  bool checking = false;
  Timer? timer;

  bool get approved {
    final normalized = status.trim().toLowerCase();
    return normalized == 'approved' || normalized == 'paid';
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkStatus(),
    );

    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (checking) return;

    checking = true;

    if (mounted) {
      setState(() {
        errorMessage = null;
      });
    }

    try {
      final result = await paymentService.checkPaymentStatus(
        widget.paymentId,
      );

      if (!mounted) return;

      final normalized = result.trim().toLowerCase();

      setState(() {
        status = normalized.isEmpty ? 'unknown' : normalized;
        errorMessage = null;
      });

      if (normalized == 'approved' || normalized == 'paid') {
        timer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      checking = false;
    }
  }

  void _openItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: widget.pdf.fileUrl,
          paymentId: widget.paymentId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = approved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isApproved
                    ? Icons.verified
                    : Icons.hourglass_top,
                size: 90,
              ),

              const SizedBox(height: 20),

              Text(
                isApproved
                    ? 'Payment Verified!'
                    : 'Payment Submitted',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                isApproved
                    ? 'Your payment has been verified. You can now open the Item.'
                    : 'Your payment is waiting for verification.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Text(
                'Status: ${status.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (isApproved) ...[
                const SizedBox(height: 12),

                const Text(
                  'Download access is now active.',
                  textAlign: TextAlign.center,
                ),
              ],

              if (errorMessage != null) ...[
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Text(
                    'Connection problem:\n$errorMessage',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (isApproved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openItem,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('OPEN Item'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: checking ? null : _checkStatus,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      checking
                          ? 'CHECKING...'
                          : 'CHECK VERIFICATION',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

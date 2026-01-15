// lib/ui/qr_generator_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:qr_generator_and_scanner/data/scan_history_store.dart';
import 'package:qr_generator_and_scanner/ui/theme/app_theme.dart';

const List<Color> qrColors = [
  Colors.white,
  Color(0xFFF6F6F7),
  Color(0xFFEEEEF0),
  Color(0xFFC0C0C0),
  Color(0xFFD4AF37),
  Color(0xFF1A1A1A),
];

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();

  String? _qrData;
  Color _qrColor = Colors.white;
  bool _isGeneratingPdf = false;
  bool _isDownloading = false;

  bool get _hasQr => _qrData != null && _qrData!.isNotEmpty;

  Future<Uint8List?> _captureQr({
    Duration delay = const Duration(milliseconds: 120),
  }) async {
    if (!_hasQr) return null;

    final imageBytes = await _screenshotController.capture(
      delay: delay,
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );

    return imageBytes;
  }

  Future<void> _shareQr() async {
    if (!_hasQr) return;

    final store = ScanHistoryProvider.of(context);
    unawaited(store.addGenerated(_qrData!));

    try {
      final imageBytes = await _captureQr();
      if (!mounted) return;
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR for sharing')),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              imageBytes,
              name: 'quescanner_${DateTime.now().millisecondsSinceEpoch}.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'QR Code generated with QUESCANNER\nContent: $_qrData',
          subject: 'QR Code from QUESCANNER',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing QR: $e')));
    }
  }

  Future<void> _downloadQr() async {
    if (!_hasQr) return;

    final store = ScanHistoryProvider.of(context);
    unawaited(store.addGenerated(_qrData!));

    setState(() => _isDownloading = true);

    try {
      final imageBytes = await _captureQr(
        delay: const Duration(milliseconds: 200),
      );
      if (!mounted) return;
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR for download')),
        );
        setState(() => _isDownloading = false);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quescanner_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await OpenFile.open(filePath);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR saved: $fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _generateAndPrintPdf() async {
    if (!_hasQr) return;

    final store = ScanHistoryProvider.of(context);
    unawaited(store.addGenerated(_qrData!));

    setState(() => _isGeneratingPdf = true);

    try {
      final imageBytes = await _captureQr(
        delay: const Duration(milliseconds: 200),
      );
      if (!mounted) return;
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR for PDF')),
        );
        setState(() => _isGeneratingPdf = false);
        return;
      }

      final pdf = pw.Document();
      final qrImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(32),
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'QUESCANNER - QR Code',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(16),
                    border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  ),
                  child: pw.Image(qrImage, width: 220, height: 220),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Content:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _qrData ?? '-',
                  style: const pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated by QUESCANNER - ${DateTime.now().toString()}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'QUESCANNER_QR_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF generation error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR'),
        automaticallyImplyLeading: Navigator.canPop(context),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // QR Preview Card
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _qrColor,
                    borderRadius: AppBorderRadius.xlarge,
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      width: 2,
                    ),
                    boxShadow: [AppShadows.medium],
                  ),
                  child: !_hasQr
                      ? Column(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 64,
                              color: AppColors.textTertiary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Enter content below to generate QR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : PrettyQrView.data(
                          data: _qrData!,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrSmoothSymbol(
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Input Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Enter URL, text, or contact info...',
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: AppBorderRadius.large,
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: _textController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _textController.clear();
                                        setState(() => _qrData = null);
                                      },
                                    )
                                  : null,
                            ),
                            maxLines: 4,
                            onChanged: (value) {
                              setState(() {
                                final trimmed = value.trim();
                                _qrData = trimmed.isEmpty ? null : trimmed;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter any text, URL, or data to encode',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Color Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background Color',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: qrColors.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final color = qrColors[index];
                                return GestureDetector(
                                  onTap: () => setState(() => _qrColor = color),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: AppBorderRadius.medium,
                                      border: Border.all(
                                        color: _qrColor == color
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: _qrColor == color
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [AppShadows.small],
                                    ),
                                    child: _qrColor == color
                                        ? const Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Action Buttons
                      _hasQr
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _hasQr && !_isDownloading
                                            ? _downloadQr
                                            : null,
                                        icon: _isDownloading
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.download_rounded,
                                              ),
                                        label: const Text('Save to Device'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _hasQr && !_isGeneratingPdf
                                            ? _generateAndPrintPdf
                                            : null,
                                        icon: _isGeneratingPdf
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.print_rounded),
                                        label: const Text('Print as PDF'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryDark,
                                          foregroundColor: AppColors.textInverse,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _hasQr ? _shareQr : null,
                                      icon: const Icon(Icons.share_rounded),
                                      label: const Text('Share QR Code'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 12,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'double klik untuk download instant',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _hasQr ? _shareQr : null,
                              icon: const Icon(Icons.qr_code_2_rounded),
                              label: const Text('Generate QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                              ),
                            ),
                    ],
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

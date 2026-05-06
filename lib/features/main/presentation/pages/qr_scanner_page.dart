import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';

/// Trang quét mã QR full-screen.
/// Trả về [String?] khi pop — là raw value của QR hoặc null nếu huỷ.
class QrScannerPage extends StatefulWidget {
  /// Tiêu đề hiển thị trên AppBar
  final String title;

  /// Gợi ý hiển thị bên dưới khung QR
  final String hint;

  const QrScannerPage({
    super.key,
    this.title = 'Quét mã QR',
    this.hint = 'Đưa mã QR vào khung để quét',
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _scanAnimation;

  bool _flashOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    // Animation đường quét chạy lên xuống
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _hasScanned = true;
    final value = barcode!.rawValue!;

    // ── DEBUG LOG ──────────────────────────────────────────────────
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  [QR SCANNER] Barcode detected           ║');
    debugPrint('╠══════════════════════════════════════════╣');
    debugPrint('║  Format : ${barcode.format.name}');
    debugPrint('║  Raw    : $value');
    debugPrint('╚══════════════════════════════════════════╝');
    // ───────────────────────────────────────────────────────────────

    Navigator.of(context).pop(value);
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _flashOn ? kCyan : Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera feed ──────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Overlay tối ở 4 góc ─────────────────────────────────
          _buildDimOverlay(context),

          // ── Khung QR + animation ─────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // 4 góc phát sáng Cyan
                  _buildCorner(top: 0, left: 0, rotateZ: 0),
                  _buildCorner(top: 0, right: 0, rotateZ: 90),
                  _buildCorner(bottom: 0, right: 0, rotateZ: 180),
                  _buildCorner(bottom: 0, left: 0, rotateZ: 270),

                  // Đường scan chạy lên xuống
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, _) {
                      return Positioned(
                        top: _scanAnimation.value * 248,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                kCyan.withValues(alpha: 0.8),
                                kCyan,
                                kCyan.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kCyan.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Hint text ─────────────────────────────────────────────
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: kCyan, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.hint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                  label: const Text(
                    'Huỷ quét',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Overlay tối 4 phía, chừa vùng giữa 260×260 trong suốt
  Widget _buildDimOverlay(BuildContext context) {
    const frameSize = 260.0;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final sideW = (screenW - frameSize) / 2;
    final topH = (screenH - frameSize) / 2;

    const dimColor = Color(0xBB000000);

    return Stack(
      children: [
        // Top
        Positioned(top: 0, left: 0, right: 0, height: topH,
            child: Container(color: dimColor)),
        // Bottom
        Positioned(bottom: 0, left: 0, right: 0, height: topH,
            child: Container(color: dimColor)),
        // Left
        Positioned(top: topH, left: 0, width: sideW, height: frameSize,
            child: Container(color: dimColor)),
        // Right
        Positioned(top: topH, right: 0, width: sideW, height: frameSize,
            child: Container(color: dimColor)),
      ],
    );
  }

  /// Một góc phát sáng của khung QR
  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotateZ,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotateZ * 3.14159 / 180,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: kCyan, width: 3.5),
              left: BorderSide(color: kCyan, width: 3.5),
            ),
          ),
        ),
      ),
    );
  }
}

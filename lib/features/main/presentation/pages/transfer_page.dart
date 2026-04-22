import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/transfer_out_usecase.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isTransferring = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleTransfer() async {
    if (currentUser == null) return;

    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Vui lòng nhập số điện thoại hợp lệ',
        kRose,
        Icons.error,
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Số tiền không hợp lệ',
        kRose,
        Icons.error,
      );
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    final transferUseCase = sl<TransferOutUseCase>();
    final result = await transferUseCase.call(currentUser!.uid, amount, phone);

    setState(() {
      _isTransferring = false;
    });

    result.fold(
      (failure) {
        showNotificationDialog(
          context,
          'Thất bại',
          failure.message,
          kRose,
          Icons.error_outline,
        );
      },
      (_) {
        showNotificationDialog(
          context,
          'Thành công',
          'Đã chuyển ${amount.toStringAsFixed(0)} VNĐ đến ví MoMo $phone.',
          kEmerald,
          Icons.check_circle_outline,
          onOkPressed: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Cần đăng nhập trước")));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        title: const Text(
          'Chuyển khoản (Rút tiền)',
          style: TextStyle(color: kTextPrimary),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kElectricBlue, kOceanBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Rút tiền về MoMo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tiền sẽ được chuyển ngay lập tức',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Số điện thoại nhận (MoMo)',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: kTextPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Nhập SĐT (vd: 0987654321)',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: kElectricBlue,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Số tiền chuyển',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(color: kTextPrimary),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: kElectricBlue,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isTransferring ? null : _handleTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kElectricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isTransferring
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Chuyển khoản ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: kNeonCyan, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính năng giả lập Rút tiền/Chi hộ. Tiền sẽ được trừ vào ví Firebase hiện tại.',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

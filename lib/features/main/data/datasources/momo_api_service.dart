import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class MomoApiService {
  static const String _partnerCode = 'MOMO';
  static const String _accessKey = 'F8BBA842ECF85';
  static const String _secretKey = 'K951B6PE1waDMi640xX08PD3vg6EkVlz';

  static const String _endpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create';

  /// Gửi yêu cầu tạo giao dịch đến MoMo và nhận về qrCodeUrl
  Future<String?> createPayment({
    required double amount,
    required String orderInfo,
    required String userId, // Nhận userId từ giao diện
  }) async {
    final String amountStr = amount.toInt().toString();

    // Tạo requestId và orderId duy nhất bằng timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String requestId = timestamp;
    final String orderId = timestamp;

    const String redirectUrl =
        'https://google.com.vn'; // URL sau khi thanh toán thành công (Web)

    // ipnUrl phải trỏ về Firebase Cloud Functions của bạn sau khi deploy
    const String ipnUrl =
        'https://us-central1-fintechda-cfba5.cloudfunctions.net/momoIpnWebhook';

    // Đổi thành 'payWithMethod' thay vì 'captureWallet' vì tài khoản MOMOBKUN20180529 không hỗ trợ tạo QR trực tiếp.
    const String requestType = 'captureWallet';

    // Mã hóa userId sang Base64 để truyền vào extraData (MoMo bắt buộc extraData phải là Base64 nếu có dữ liệu)
    final String extraData = base64Encode(utf8.encode(userId));

    // 1. Tạo chuỗi ký tự thô theo đúng thứ tự MoMo yêu cầu (để tạo chữ ký)
    final String rawSignature =
        'accessKey=$_accessKey'
        '&amount=$amountStr'
        '&extraData=$extraData'
        '&ipnUrl=$ipnUrl'
        '&orderId=$orderId'
        '&orderInfo=$orderInfo'
        '&partnerCode=$_partnerCode'
        '&redirectUrl=$redirectUrl'
        '&requestId=$requestId'
        '&requestType=$requestType';

    // 2. Mã hóa HMAC SHA256 với secretKey
    final List<int> key = utf8.encode(_secretKey);
    final List<int> bytes = utf8.encode(rawSignature);

    final Hmac hmac = Hmac(sha256, key);
    final Digest digest = hmac.convert(bytes);
    final String signature = digest.toString();

    // 3. Tạo body dữ liệu dạng JSON
    final Map<String, dynamic> requestBody = {
      'partnerCode': _partnerCode,
      'partnerName': 'FinTech App Test',
      'storeId': 'MomoTestStore',
      'requestId': requestId,
      'amount': amountStr,
      'orderId': orderId,
      'orderInfo': orderInfo,
      'redirectUrl': redirectUrl,
      'ipnUrl': ipnUrl,
      'lang': 'vi',
      'extraData': extraData,
      'requestType': requestType,
      'signature': signature,
    };

    // 4. Gửi HTTP POST request
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Connection': 'close',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Trả về qrCodeUrl, nếu không có sẽ trả về URL thanh toán chung
        if (responseData['qrCodeUrl'] != null) {
          return responseData['qrCodeUrl'];
        } else if (responseData['payUrl'] != null) {
          return responseData['payUrl'];
        } else {
          // In ra toàn bộ response để debug dễ hơn, bao gồm cả resultCode
          print('Lỗi từ MoMo: ${jsonEncode(responseData)}');
          return null;
        }
      } else {
        print('Lỗi HTTP: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi gọi API MoMo: $e');
      return null;
    }
  }
}

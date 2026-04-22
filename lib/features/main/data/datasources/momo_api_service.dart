import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Kết quả tạo thanh toán MoMo
class MomoPaymentResult {
  final String? qrCodeUrl;
  final String orderId;
  final String requestId;

  const MomoPaymentResult({
    required this.qrCodeUrl,
    required this.orderId,
    required this.requestId,
  });
}

class MomoApiService {
  static const String _partnerCode = 'MOMO';
  static const String _accessKey = 'F8BBA842ECF85';
  static const String _secretKey = 'K951B6PE1waDMi640xX08PD3vg6EkVlz';

  static const String _createEndpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create';
  static const String _queryEndpoint =
      'https://test-payment.momo.vn/v2/gateway/api/query';

  /// Tạo giao dịch MoMo, trả về [MomoPaymentResult] gồm qrCodeUrl và orderId
  Future<MomoPaymentResult?> createPayment({
    required double amount,
    required String orderInfo,
    required String userId,
  }) async {
    final String amountStr = amount.toInt().toString();

    // orderId và requestId duy nhất theo timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String requestId = timestamp;
    final String orderId = timestamp;

    const String redirectUrl = 'https://google.com.vn';
    const String ipnUrl =
        'https://us-central1-fintechda-cfba5.cloudfunctions.net/momoIpnWebhook';
    const String requestType = 'captureWallet';

    final String extraData = base64Encode(utf8.encode(userId));

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

    final String signature = _sign(rawSignature);

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

    try {
      final response = await http.post(
        Uri.parse(_createEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? url = data['qrCodeUrl'] ?? data['payUrl'];

        if (url == null) {
          print('MoMo create error: ${jsonEncode(data)}');
          return null;
        }

        return MomoPaymentResult(
          qrCodeUrl: url,
          orderId: orderId,
          requestId: requestId,
        );
      } else {
        print('HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('MoMo createPayment error: $e');
      return null;
    }
  }

  /// Truy vấn trạng thái giao dịch theo orderId.
  /// Trả về true nếu thanh toán thành công (resultCode == 0).
  Future<bool> queryPaymentStatus({
    required String orderId,
    required String requestId,
  }) async {
    final String rawSignature =
        'accessKey=$_accessKey'
        '&orderId=$orderId'
        '&partnerCode=$_partnerCode'
        '&requestId=$requestId';

    final String signature = _sign(rawSignature);

    final Map<String, dynamic> body = {
      'partnerCode': _partnerCode,
      'requestId': requestId,
      'orderId': orderId,
      'lang': 'vi',
      'signature': signature,
    };

    try {
      final response = await http.post(
        Uri.parse(_queryEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final int resultCode = data['resultCode'] ?? -1;
        print('MoMo query resultCode: $resultCode | message: ${data['message']}');
        // resultCode == 0: thành công
        return resultCode == 0;
      }
      return false;
    } catch (e) {
      print('MoMo queryPaymentStatus error: $e');
      return false;
    }
  }

  /// Ký HMAC-SHA256 với secretKey
  String _sign(String rawData) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(rawData);
    return Hmac(sha256, key).convert(bytes).toString();
  }
}

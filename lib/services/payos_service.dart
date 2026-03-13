import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PayosService {
  // THAY THẾ CÁC THÔNG TIN NÀY BẰNG KEY CỦA BẠN TỪ PAYOS DASHBOARD
  static const String clientId = "771c8f5a-f566-480b-bbfb-2c5e25c6492c";
  static const String apiKey = "7f76b838-cfbd-4600-90a0-93acebf9cf8c";
  static const String checksumKey = "43fafe953f23b7d2bb27dfa964cae3d3b074f988c3ea7068485b77c0943cd70b";

  static const String baseUrl = "https://api-merchant.payos.vn";

  String _generateSignature(Map<String, dynamic> data, String checksumKey) {
    // Sắp xếp các key theo alphabet
    var sortedKeys = data.keys.toList()..sort();
    
    // Tạo chuỗi data để hash
    String dataString = sortedKeys.map((key) => "$key=${data[key]}").join("&");

    // Hash HMAC-SHA256
    var key = utf8.encode(checksumKey);
    var bytes = utf8.encode(dataString);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);

    return digest.toString();
  }

  Future<void> createPaymentLink({
    required int orderCode,
    required int amount,
    required String description,
  }) async {
    final Map<String, dynamic> body = {
      "orderCode": orderCode,
      "amount": amount,
      "description": description,
      "cancelUrl": "https://your-app-return-url.com/cancel",
      "returnUrl": "https://your-app-return-url.com/success",
    };

    // Tạo signature
    String signature = _generateSignature(body, checksumKey);
    body["signature"] = signature;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v2/payment-requests"),
        headers: {
          "Content-Type": "application/json",
          "x-client-id": clientId,
          "x-api-key": apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data["code"] == "00") {
          String checkoutUrl = data["data"]["checkoutUrl"];
          final Uri url = Uri.parse(checkoutUrl);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
        } else {
          throw Exception("PayOS Error: ${data["desc"]}");
        }
      } else {
        throw Exception("Failed to create payment link: ${response.body}");
      }
    } catch (e) {
      print("Error creating payment: $e");
      rethrow;
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/prediction_response.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';  // Replace with your server IP

  Future<PredictionResponse> predictSign(Uint8List imageBytes) async {
    try {
      final String base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to predict sign: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending prediction request: $e');
    }
  }
}

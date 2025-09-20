import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logistic/models/state_model.dart';

class StateService {
  static const String baseUrl = 'http://192.168.1.166:8080/state';

  static Future<List<StateModel>> searchStates(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => StateModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load states');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }
}

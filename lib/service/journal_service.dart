import '../api_key/api_key.dart';

class JournalService {
  static const String tableName = 'journal';

  static Future<Map<String, dynamic>> getMotivationalQuotes() async {
    try {
      final api = ApiPhp(tableName: tableName, orderBy: 'date DESC');

      final response = await api.select();

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e', 'data': null};
    }
  }

  // Create a new motivational quote
  static Future<Map<String, dynamic>> createMotivationalQuote(
    Map<String, dynamic> quoteData,
  ) async {
    try {
      final formattedData = Map<String, dynamic>.from(quoteData);
      if (formattedData['date'] is DateTime) {
        formattedData['date'] = _formatDateTime(
          formattedData['date'] as DateTime,
        );
      }

      final api = ApiPhp(tableName: tableName, parameters: formattedData);

      final response = await api.insert();

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e', 'data': null};
    }
  }

  // Delete a motivational quote
  static Future<Map<String, dynamic>> deleteMotivationalQuote(
    String quoteId,
  ) async {
    try {
      final api = ApiPhp(tableName: tableName, whereClause: {'id': quoteId});

      final response = await api.delete();

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e', 'data': null};
    }
  }

  // Get distinct categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final api = ApiPhp(tableName: tableName);

      // Use selectColumns to get distinct categories
      final response = await api.selectColumns(['DISTINCT category']);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e', 'data': null};
    }
  }

  // Update a quote
  static Future<Map<String, dynamic>> updateMotivationalQuote(
    String quoteId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final api = ApiPhp(
        tableName: tableName,
        parameters: updateData,
        whereClause: {'id': quoteId},
      );

      final response = await api.update();
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e', 'data': null};
    }
  }

  // Helper method to format DateTime to MySQL format
  static String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}

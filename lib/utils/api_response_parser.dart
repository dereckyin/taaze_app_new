/// 解析後端 PaginatedResponse 或舊版純陣列格式。
class ApiResponseParser {
  static List<dynamic> extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      return (decoded['items'] ?? decoded['data'] ?? []) as List<dynamic>;
    }
    throw Exception('unexpected response format');
  }

  static int extractTotal(dynamic decoded, {required int fallback}) {
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['total'] ??
          decoded['total_count'] ??
          decoded['totalCount'];
      if (raw is int) return raw;
      if (raw != null) {
        return int.tryParse(raw.toString()) ?? fallback;
      }
    }
    if (decoded is List) {
      return decoded.length;
    }
    return fallback;
  }
}

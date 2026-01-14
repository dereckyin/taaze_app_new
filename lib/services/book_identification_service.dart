import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/identified_book.dart';
import '../utils/debug_helper.dart';
import '../config/api_config.dart';

class BookIdentificationService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 300);

  /// 識別書籍照片
  ///
  /// [imageFile] 要識別的圖片文件
  /// 返回識別結果列表
  static Future<List<IdentifiedBook>> identifyBooks(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/vision/identify-book');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 創建multipart請求
      final request = http.MultipartRequest('POST', uri);

      // 添加圖片文件（強制設置 part 的 Content-Type，避免被默認為 application/octet-stream）
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      MediaType mediaType;
      String filename;

      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mediaType = MediaType('image', 'jpeg');
          filename = 'book_image.jpg';
          break;
        case 'png':
          mediaType = MediaType('image', 'png');
          filename = 'book_image.png';
          break;
        case 'webp':
          mediaType = MediaType('image', 'webp');
          filename = 'book_image.webp';
          break;
        default:
          // 默認轉換為JPEG格式
          mediaType = MediaType('image', 'jpeg');
          filename = 'book_image.jpg';
      }

      final fileBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: mediaType,
        ),
      );

      // 發送請求
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        final identifiedBooks = responseData
            .map((json) => IdentifiedBook.fromJson(json))
            .toList();

        DebugHelper.log(
          '書籍識別成功，找到 ${identifiedBooks.length} 本書籍',
          tag: 'BookIdentificationService',
        );
        return identifiedBooks;
      } else {
        // 解析錯誤響應
        String errorMessage = '書籍識別API返回錯誤狀態碼: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (e) {
          // 如果無法解析錯誤響應，使用默認錯誤信息
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      DebugHelper.log(
        '書籍識別API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );

      // 如果API調用失敗，返回模擬識別結果
      return getMockIdentificationResults();
    }
  }

  /// 獲取模擬識別結果（當API不可用時使用）
  static List<IdentifiedBook> getMockIdentificationResults() {
    return [
      IdentifiedBook(
        prodId: '11100767446',
        eancode: '9789863792512',
        titleMain: 'RWD跨平台響應式網頁設計',
        condition: '良好',
      ),
      IdentifiedBook(
        prodId: '11100656655',
        eancode: '9789865836351',
        titleMain: '王者歸來：UNIX 王者殿堂',
        condition: '近全新',
      ),
      IdentifiedBook(
        prodId: '11100958787',
        eancode: '9789865028855',
        titleMain: '內行人才知道的系統設計面試指南',
        condition: '良好',
      ),
    ];
  }

  /// 匯入上架草稿 (自動填充模式)
  ///
  /// [selectedBooks] 選中的書籍列表
  /// 返回是否成功
  static Future<bool> importToDraft(
    List<IdentifiedBook> selectedBooks, {
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConfig.secondHandDraftAutoFillEndpoint}');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 準備請求數據：根據後端報錯，目前只需提供 org_prod_ids 列表
      final requestData = {
        'org_prod_ids': selectedBooks
            .map((book) => book.prodId ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
      };

      final headers = {
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(requestData),
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DebugHelper.log('匯入上架草稿成功', tag: 'BookIdentificationService');
        return true;
      } else {
        throw Exception('匯入上架草稿API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log(
        '匯入上架草稿API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );

      // 模擬成功響應 (測試用)
      if (kDebugMode) {
        DebugHelper.log('模擬匯入上架草稿成功', tag: 'BookIdentificationService');
        return true;
      }
      rethrow;
    }
  }

  /// 提交二手書申請 (自動填充模式)
  ///
  /// [selectedBooks] 選中的書籍列表
  /// 返回是否成功
  static Future<bool> submitSecondHandApplication({
    required List<IdentifiedBook> selectedBooks,
    String? authToken,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl${ApiConfig.secondHandDraftAutoFillEndpoint}');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 準備請求數據：根據後端報錯，目前只需提供 org_prod_ids 列表
      final requestData = {
        'org_prod_ids': selectedBooks
            .map((book) => book.prodId ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
      };

      final headers = {
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(requestData),
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DebugHelper.log('提交成功', tag: 'BookIdentificationService');
        return true;
      } else {
        throw Exception('提交API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log(
        '提交API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );

      if (kDebugMode) {
        DebugHelper.log('模擬提交成功', tag: 'BookIdentificationService');
        return true;
      }
      rethrow;
    }
  }

  /// 加入暫存 (Watchlist Auto-fill)
  ///
  /// [prodIds] 要加入暫存的書籍 ID (prod_id) 列表
  /// 返回是否成功
  static Future<bool> addToWatchlist(
    List<String> prodIds, {
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConfig.watchlistAutoFillEndpoint}');
      DebugHelper.logApiRequest('POST', uri.toString());

      final requestData = {
        'prod_ids': prodIds.where((id) => id.isNotEmpty).toList(),
      };

      final headers = {
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(requestData),
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        DebugHelper.log('加入暫存成功', tag: 'BookIdentificationService');
        return true;
      } else {
        throw Exception('加入暫存API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log(
        '加入暫存API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );

      if (kDebugMode) {
        DebugHelper.log('模擬加入暫存成功', tag: 'BookIdentificationService');
        return true;
      }
      rethrow;
    }
  }

  /// 獲取暫存清單
  ///
  /// 返回暫存清單數據列表（可能包含書籍 ID 或詳細資訊）
  static Future<List<dynamic>> getWatchlist({
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConfig.watchlistEndpoint}');
      DebugHelper.logApiRequest('GET', uri.toString());

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData;
        }
        return [];
      } else {
        throw Exception('獲取暫存清單API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log(
        '獲取暫存清單API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );
      rethrow;
    }
  }
}

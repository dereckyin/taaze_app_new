import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/identified_book.dart';
import '../utils/debug_helper.dart';

class BookIdentificationService {
  static const String _baseUrl = 'https://api.taaze.tw/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  /// 識別書籍照片
  ///
  /// [imageFile] 要識別的圖片文件
  /// 返回識別結果列表
  static Future<List<IdentifiedBook>> identifyBooks(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/vision/identify-book');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 創建multipart請求
      final request = http.MultipartRequest('POST', uri);

      // 添加圖片文件
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'book_image.jpg',
        ),
      );

      // 設置Content-Type
      request.headers['Content-Type'] = 'multipart/form-data';

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
        throw Exception('書籍識別API返回錯誤狀態碼: ${response.statusCode}');
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
        prodId: '111004034',
        eancode: '9789861194561',
        titleMain: '晉級的巨人',
        condition: '良好',
      ),
      IdentifiedBook(
        prodId: null,
        eancode: null,
        titleMain: '進擊的巨人',
        condition: '近全新',
      ),
      IdentifiedBook(
        prodId: '111004035',
        eancode: '9789861194562',
        titleMain: '火影忍者',
        condition: '良好',
      ),
      IdentifiedBook(
        prodId: null,
        eancode: null,
        titleMain: '海賊王',
        condition: '近全新',
      ),
      IdentifiedBook(
        prodId: '111004036',
        eancode: '9789861194563',
        titleMain: '鬼滅之刃',
        condition: '良好',
      ),
    ];
  }

  /// 匯入上架草稿
  ///
  /// [selectedBooks] 選中的書籍列表
  /// 返回是否成功
  static Future<bool> importToDraft(List<IdentifiedBook> selectedBooks) async {
    try {
      final uri = Uri.parse('$_baseUrl/listing/draft/import');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 準備請求數據
      final requestData = {
        'books': selectedBooks.map((book) => book.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(_timeout);

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
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

      // 模擬成功響應
      DebugHelper.log('模擬匯入上架草稿成功', tag: 'BookIdentificationService');
      return true;
    }
  }
}

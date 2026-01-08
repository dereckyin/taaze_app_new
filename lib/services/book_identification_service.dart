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
    // 開發測試用：直接返回模擬數據，以便測試後續的上架申請流程
    if (kDebugMode) {
      DebugHelper.log('測試模式：直接返回模擬識別結果', tag: 'BookIdentificationService');
      return getMockIdentificationResults();
    }

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

      // 準備請求數據：目前只需提供 org_prod_id
      final requestData = {
        'items': selectedBooks.map((book) => {
          'org_prod_id': book.prodId ?? '',
        }).toList(),
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

  /// 提交二手書申請單
  ///
  /// [selectedBooks] 選中的書籍列表
  /// [userData] 會員基本資料
  /// 返回是否成功
  static Future<bool> submitSecondHandApplication({
    required List<IdentifiedBook> selectedBooks,
    required Map<String, dynamic> userData,
    String? authToken,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl${ApiConfig.secondHandApplicationEndpoint}');
      DebugHelper.logApiRequest('POST', uri.toString());

      // 準備符合後端 schema 的數據結構
      // 優先使用傳入的 userData，若無則由後端從會員資料補齊
      final requestData = {
        'application': {
          if (userData['name'] != null && userData['name'].isNotEmpty)
            'cust_name': userData['name'],
          if (userData['phone'] != null && userData['phone'].isNotEmpty)
            'cust_mobile': userData['phone'],
          if (userData['address'] != null && userData['address'].isNotEmpty)
            'address': userData['address'],
          'delivery_type': 'A', // 預設 A (POST_OFFICE)，此為必填
          if (userData['phone'] != null && userData['phone'].isNotEmpty)
            'tel_day': userData['phone'],
        },
        'item_list': selectedBooks.map((book) {
          // 將純中文映射回後端要求的代碼 (A, B, C...)
          String conditionCode;
          switch (book.condition) {
            case '全新':
              conditionCode = 'A';
              break;
            case '近全新':
              conditionCode = 'B';
              break;
            case '良好':
              conditionCode = 'C';
              break;
            case '普通':
              conditionCode = 'D';
              break;
            case '差強人意':
              conditionCode = 'E';
              break;
            default:
              conditionCode = 'C';
          }

          return {
            'org_prod_id': book.prodId ?? '',
            'prod_rank': conditionCode,
            'prod_mark': conditionCode,
            'sale_price': book.sellingPrice ?? 0.0,
            'other_mark': book.notes ?? '',
          };
        }).toList(),
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
        DebugHelper.log('提交二手書申請單成功', tag: 'BookIdentificationService');
        return true;
      } else {
        throw Exception('提交二手書申請單API返回錯誤狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      DebugHelper.log(
        '提交二手書申請單API調用失敗: ${e.toString()}',
        tag: 'BookIdentificationService',
      );

      // 模擬成功響應（開發環境中）
      if (kDebugMode) {
        DebugHelper.log('模擬提交二手書申請單成功', tag: 'BookIdentificationService');
        return true;
      }
      rethrow;
    }
  }
}

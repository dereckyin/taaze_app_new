import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/book.dart';
import '../utils/debug_helper.dart';

class SearchService {
  static const Duration _timeout = Duration(seconds: 10);

  /// 搜尋書籍（改為使用 Taaze 的 HTML 搜尋頁面）
  static Future<SearchResultData> searchBooks({
    required String keyword,
    int page = 1,
    int pageSize = 24,
  }) async {
    if (keyword.trim().isEmpty) {
      return SearchResultData.empty();
    }

    try {
      final html = await _fetchTaazeHtml(keyword, page);
      final parsed = _parseTaazeHtml(html, page, pageSize);
      DebugHelper.log(
        'Taaze 搜尋成功：${parsed.books.length} 本 (hasMore=${parsed.hasMore})',
        tag: 'SearchService',
      );
      return parsed;
    } catch (e) {
      DebugHelper.log('搜尋API調用失敗: ${e.toString()}', tag: 'SearchService');
      throw Exception('Taaze 搜尋失敗：${e.toString()}');
    }
  }

  static Future<String> _fetchTaazeHtml(String keyword, int page) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final uri = Uri.parse(
      'https://www.taaze.tw/rwd_searchResulttest.html'
      '?keyType%5B%5D=0'
      '&keyword%5B%5D=$encodedKeyword'
      '&prodKind=0&prodCatId=0&catId=0'
      '&saleDiscStart=0&saleDiscEnd=0'
      '&salePriceStart=&salePriceEnd='
      '&publishDateStart=&publishDateEnd='
      '&prodRank=0&addMarkFlg=0&force=0'
      '&catFocus=&orgFocus=&mainCatFocus=&catNmFocus=&catIdFocus='
      '&layout=A'
      '&nowPage=$page'
      '&sort=',
    );

    DebugHelper.logApiRequest('GET', uri.toString());

    final response = await http
        .get(
          uri,
          headers: const {
            'user-agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        )
        .timeout(_timeout);

    DebugHelper.logApiResponse(
      response.statusCode,
      'Taaze HTML (${response.bodyBytes.length} bytes)',
    );

    if (response.statusCode != 200) {
      throw Exception('Taaze 搜尋失敗，狀態碼 ${response.statusCode}');
    }

    return utf8.decode(response.bodyBytes);
  }

  static SearchResultData _parseTaazeHtml(
    String html,
    int currentPage,
    int fallbackPageSize,
  ) {
    final document = html_parser.parse(html);

    final totalSize = int.tryParse(
          document.querySelector('#HIDE_TOTALSIZE')?.attributes['value'] ?? '',
        ) ??
        0;
    final pageSize = int.tryParse(
          document.querySelector('#HIDE_PAGESIZE')?.attributes['value'] ?? '',
        ) ??
        fallbackPageSize;

    final mediaNodes = document.querySelectorAll('#listView .media');
    final books = <Book>[];

    for (final node in mediaNodes) {
      final book = _bookFromMediaNode(node);
      if (book != null) {
        books.add(book);
      }
    }

    final fetchedCount = currentPage * pageSize;
    final hasMore = fetchedCount < totalSize && books.isNotEmpty;

    return SearchResultData(books: books, hasMore: hasMore);
  }

  static Book? _bookFromMediaNode(dom.Element node) {
    final relId = node.attributes['rel']?.trim() ?? '';
    final orgProdId = node.attributes['rel2']?.trim() ?? '';
    final rawTitle = node.attributes['data-TITLE_MAIN']?.trim() ??
        node.querySelector('.media-heading')?.text.trim() ??
        '';

    if (relId.isEmpty && orgProdId.isEmpty && rawTitle.isEmpty) {
      return null;
    }

    final coverNode = node.querySelector('.cover_frame');
    String? imageUrl = coverNode?.attributes['data-bg_url']?.trim() ??
        coverNode?.attributes['href']?.trim();
    if ((imageUrl == null || imageUrl.isEmpty) &&
        coverNode?.attributes['style'] != null) {
      final style = coverNode!.attributes['style']!;
      final match = RegExp(
        r'''url\(['"]?(.*?)['"]?\)''',
        caseSensitive: false,
      ).firstMatch(style);
      if (match != null) {
        imageUrl = match.group(1);
      }
    }
    imageUrl = _normalizeImageUrl(imageUrl);

    final authorText = node.querySelector('.author')?.text.trim() ?? '';
    final author = _extractValue(authorText, '作者：') ?? '未知作者';

    final publisherText =
        node.querySelector('.publisher')?.text.trim() ?? '';
    final publisher = _extractValue(publisherText, '出版社：') ?? '';

    final publishDateText =
        node.querySelector('.pubDate')?.text.trim() ?? '';
    final publishDate = _parsePublishDate(publishDateText);

    final descriptionText = node.querySelector('.prodPf')?.text.trim() ?? '';
    final description =
        descriptionText.isEmpty ? '暫無內容簡介' : descriptionText;

    final salePrice = _parsePrice(node.attributes['data-saleprice_28']);
    final listPrice = _parsePrice(node.attributes['data-listprice_28']);
    final price = salePrice ?? listPrice ?? 0;

    final category = node.attributes['data-CAT_ID'] ?? '';
    final isAvailable = (node.attributes['rel4'] ?? 'N') != 'Y';

    return Book(
      id: relId.isEmpty ? (orgProdId.isEmpty ? rawTitle : orgProdId) : relId,
      orgProdId: orgProdId.isEmpty ? relId : orgProdId,
      title: rawTitle.isEmpty ? '未命名書籍' : rawTitle,
      author: author,
      description: description,
      price: price.toDouble(),
      listPrice: listPrice,
      salePrice: salePrice,
      imageUrl: imageUrl ?? '',
      category: category,
      rating: 0,
      reviewCount: 0,
      isAvailable: isAvailable,
      publishDate: publishDate,
      isbn: node.attributes['data-suporgprodid_28'] ?? '',
      pages: 0,
      publisher: publisher,
    );
  }

  static double? _parsePrice(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static String? _extractValue(String text, String prefix) {
    if (text.isEmpty) return null;
    if (text.startsWith(prefix)) {
      return text.substring(prefix.length).trim();
    }
    return text.trim();
  }

  static DateTime _parsePublishDate(String text) {
    final cleaned = text.replaceAll('出版日期：', '').trim();
    if (cleaned.isEmpty) return DateTime.now();
    return DateTime.tryParse(cleaned) ?? DateTime.now();
  }

  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    var cleaned = url.replaceAll('&amp;', '&').trim();
    if (cleaned.startsWith('//')) {
      cleaned = 'https:$cleaned';
    }
    return cleaned;
  }

}

class SearchResultData {
  final List<Book> books;
  final bool hasMore;

  const SearchResultData({
    required this.books,
    required this.hasMore,
  });

  factory SearchResultData.empty() =>
      const SearchResultData(books: [], hasMore: false);
}


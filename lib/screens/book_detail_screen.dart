import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/book.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/watchlist_provider.dart';
import 'ai_chat_screen.dart';
import 'login_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/cached_image_widget.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _taazeBook;
  Map<String, dynamic>? _taazeRaw;
  bool _isLoadingTaaze = false;
  String? _taazeError;
  String? _podcastUrl;
  bool _isCheckingPodcast = false;
  String? _podcastError;
  bool _podcastNotFound = false;
  String? _currentPodcastLookupId;

  AudioPlayer? _audioPlayer;
  String? _loadedPodcastUrl;
  Duration? _audioDuration;
  Duration _audioPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isPlayerLoading = false;
  String? _playerError;

  bool _isAiTalkAllowed() {
    final raw = _taazeRaw;
    if (raw == null) return false;

    final saleDiscRaw = raw['saleDisc']?.toString() ?? '';
    if (saleDiscRaw.isEmpty) return false;

    final cleaned = saleDiscRaw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return false;

    final parsed = double.tryParse(cleaned);
    if (parsed == null) return false;

    final saleDiscInt = parsed.round();
    const blockedPubIds = {'1000585', '1000802', '1000144', '1000051'};
    final pubId = raw['pubId']?.toString() ?? '';

    return saleDiscInt <= 85 && !blockedPubIds.contains(pubId);
  }

  Book get _displayBook => _taazeBook ?? widget.book;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _fetchTaazeDetails(),
        _checkPodcastAvailability(),
      ]);
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchTaazeDetails(),
      _checkPodcastAvailability(),
    ]);
  }

  Future<void> _fetchTaazeDetails() async {
    final lookupId = _preferredLookupId();
    if (lookupId == null) return;

    setState(() {
      _isLoadingTaaze = true;
      _taazeError = null;
    });

    try {
      final uri = Uri.parse('https://service.taaze.tw/product/$lookupId');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('狀態碼 ${response.statusCode}');
      }
      final decoded = json.decode(utf8.decode(response.bodyBytes));

      // API 可能回傳 Map 或 List，統一萃取 book_data
      Map<String, dynamic>? bookData;
      if (decoded is Map<String, dynamic>) {
        bookData = decoded['book_data'] as Map<String, dynamic>? ?? decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        final firstMap = decoded.firstWhere(
          (e) => e is Map<String, dynamic>,
          orElse: () => null,
        );
        if (firstMap is Map<String, dynamic>) {
          bookData =
              firstMap['book_data'] as Map<String, dynamic>? ?? firstMap;
        }
      }
      bookData ??= <String, dynamic>{};
      final merged = _mergeBookWithTaazeData(_displayBook, bookData);

      if (!mounted) return;
      setState(() {
        _taazeBook = merged;
        _taazeRaw = bookData;
        _taazeError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taazeError = '書籍資訊同步失敗：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTaaze = false;
        });
      }
    }
  }

  Future<void> _checkPodcastAvailability() async {
    final lookupId = _preferredLookupId();
    if (lookupId == null) {
      await _resetAudioPlaybackState();
      return;
    }

    if (_currentPodcastLookupId != lookupId) {
      _currentPodcastLookupId = lookupId;
      await _resetAudioPlaybackState();
    }

    if (mounted) {
      setState(() {
        _isCheckingPodcast = true;
        _podcastError = null;
        _podcastNotFound = false;
      });
    }

    final uri = Uri.parse('https://service.taaze.tw/podcast/$lookupId');
    final request = http.Request('HEAD', uri)..followRedirects = false;

    try {
      final response =
          await request.send().timeout(const Duration(seconds: 8));
      await response.stream.drain();

      if (!mounted) return;

      if (response.statusCode == 404) {
        setState(() {
          _podcastUrl = null;
          _podcastError = null;
          _podcastNotFound = true;
          _loadedPodcastUrl = null;
        });
        return;
      }

      if ((response.statusCode == 301 || response.statusCode == 302) &&
          response.headers['location'] != null &&
          response.headers['location']!.isNotEmpty) {
        setState(() {
          _podcastUrl = response.headers['location'];
          _podcastError = null;
          _podcastNotFound = false;
          _loadedPodcastUrl = null;
          _playerError = null;
        });
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _podcastUrl = uri.toString();
          _podcastError = null;
          _podcastNotFound = false;
          _loadedPodcastUrl = null;
          _playerError = null;
        });
        return;
      }

      setState(() {
        _podcastError =
            '無法取得試聽檔（狀態碼 ${response.statusCode}）';
        _podcastUrl = null;
        _podcastNotFound = false;
        _loadedPodcastUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _podcastError = '試聽檔檢查失敗：$e';
        _podcastUrl = null;
        _podcastNotFound = false;
        _loadedPodcastUrl = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPodcast = false;
        });
      }
    }
  }

  String? _preferredLookupId() {
    final orgId = widget.book.orgProdId?.trim();
    if (orgId != null && orgId.isNotEmpty) {
      return orgId;
    }
    final id = widget.book.id.trim();
    if (id.isEmpty) return null;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final book = _displayBook;

    return Scaffold(
      appBar: CustomAppBar(title: '書籍詳情', showBackButton: true),
      body: Column(
        children: [
          if (_isLoadingTaaze)
            const LinearProgressIndicator(minHeight: 2),
          if (_taazeError != null)
            _buildSyncErrorBanner(context, _taazeError!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    _buildBookHeader(context, book),
                    _buildBookDetails(context, book),
                    _buildTaazeExtras(context),
                    if (_isAiTalkAllowed()) _buildAiAssistant(context, book),
                    _buildBookDescription(context, book),
                    _buildCatalogueSection(context),
            _buildReviewsSection(context),
          ],
        ),
      ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, book),
    );
  }

  Widget _buildBookHeader(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 書籍封面
          BookCoverImage(
            imageUrl: book.imageUrl,
            width: 120,
            height: 160,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),

          const SizedBox(width: 16),

          // 書籍基本資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Text(
                  '作者：${book.author}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),

                Text(
                  '出版社：${book.publisher}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),

                Text(
                  '出版日期：${_formatDate(book.publishDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),

                // 評分
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${book.rating}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${book.reviewCount} 評論)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 價格
                _buildPriceBreakdown(context, book),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(BuildContext context, Book book) {
    // 優先使用 Taaze 詳情的即時價格；抓不到時回退到 Book model
    final raw = _taazeRaw;
    final rawList = raw == null ? null : _tryParseOptionalDouble(raw['listPrice']);
    final rawSale = raw == null ? null : _tryParseOptionalDouble(raw['salePrice']);

    final double sale = rawSale ?? book.effectiveSalePrice;
    final double? list = rawList ?? book.effectiveListPrice;

    String? offLabel;
    if (list != null && list > 0 && sale > 0 && sale < list) {
      final off = (sale / list) * 10.0;
      final rounded = ((off.clamp(0.0, 10.0)) * 10).round() / 10.0;
      final text = (rounded % 1 == 0)
          ? rounded.toStringAsFixed(0)
          : rounded.toStringAsFixed(1);
      offLabel = '${text}折';
    }

    final showList = list != null && offLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showList)
          Text(
            '定價 NT\$ ${list.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  decoration: TextDecoration.lineThrough,
                ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '優惠價 NT\$ ${sale.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (offLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
                child: Text(
                  '折扣 $offLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookDetails(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('書籍資訊', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          _buildDetailRow(context, 'ISBN', book.isbn),
          _buildDetailRow(context, '頁數', '${book.pages} 頁'),
          _buildDetailRow(context, '分類', book.category),
          _buildDetailRow(context, '庫存狀態', book.isAvailable ? '有庫存' : '缺貨'),
        ],
      ),
    );
  }

  Widget _buildTaazeExtras(BuildContext context) {
    final raw = _taazeRaw;
    if (raw == null) return const SizedBox.shrink();

    final promoName = raw['mcName']?.toString() ?? '';
    final promoRange = _formatTaazeDateRange(
      raw['mcSDate']?.toString(),
      raw['mcEDate']?.toString(),
    );
    final saleDisc = raw['saleDisc']?.toString() ?? '';
    final salePrice = raw['salePrice']?.toString() ?? '';
    final listPrice = raw['listPrice']?.toString() ?? '';

    final hasPromo = promoName.isNotEmpty ||
        saleDisc.isNotEmpty ||
        salePrice.isNotEmpty ||
        listPrice.isNotEmpty;
    if (!hasPromo) return const SizedBox.shrink();

    final parsedList = _tryParseOptionalDouble(raw['listPrice']);
    final parsedSale = _tryParseOptionalDouble(raw['salePrice']);
    String? offLabel;
    if (parsedList != null &&
        parsedSale != null &&
        parsedList > 0 &&
        parsedSale > 0 &&
        parsedSale < parsedList) {
      final off = (parsedSale / parsedList) * 10.0;
      final rounded = ((off.clamp(0.0, 10.0)) * 10).round() / 10.0;
      final text = (rounded % 1 == 0)
          ? rounded.toStringAsFixed(0)
          : rounded.toStringAsFixed(1);
      offLabel = '${text}折';
    }

    final priceInfo = [
      if (listPrice.isNotEmpty) '定價 NT\$ $listPrice',
      if (salePrice.isNotEmpty) '優惠價 NT\$ $salePrice',
      if (offLabel != null) '折扣 $offLabel' else if (saleDisc.isNotEmpty) '折扣 $saleDisc%',
    ].where((text) => text.isNotEmpty).join(' ｜ ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Taaze 即時優惠',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (priceInfo.isNotEmpty)
            Text(
              priceInfo,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.orange[900]),
            ),
          if (promoName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              promoName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (promoRange.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              promoRange,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogueSection(BuildContext context) {
    final rawCatalogue = _taazeRaw?['catalogue']?.toString();
    if (rawCatalogue == null || rawCatalogue.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = rawCatalogue
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目錄精選', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...entries.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncErrorBanner(BuildContext context, String message) {
    return Material(
      color: Colors.red[50],
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.red),
        title: Text(
          message,
          style: TextStyle(color: Colors.red[900]),
        ),
        trailing: TextButton(
          onPressed: _fetchTaazeDetails,
          child: const Text('重新整理'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDescription(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('內容簡介', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            _normalizeDescription(book.description),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistant(BuildContext context, Book book) {
    final presetQuestions = [
      "AI 幫我抓這本書的重點",
      "為什麼應該買這一本書？",
      "我是一個上班族，我該用什麼角度去理解書中內容？",
      "這本書怎麼幫助我變聰明有智慧？",
      "告訴我這個作者有什麼特殊背景？"
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                '與書對話',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AI 閱讀精靈開啟全新的閱讀體驗，讓閱讀更智慧！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '每次提問後，AI 會回傳可點選的下一步建議，不需要手動輸入。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetQuestions.map((q) {
              return ActionChip(
                label: Text(q),
                onPressed: () async {
                  final token = await _requireAuthToken(context);
                  if (token == null) return;

                  final aiProvider = context.read<AiChatProvider>();
                  aiProvider.setProductContext(book.id);
                  await aiProvider.sendMessage(
                    q,
                    productId: book.id,
                    token: token,
                  );
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiChatScreen(),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildPodcastCard(context),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final token = await _requireAuthToken(context);
                if (token == null) return;

                context.read<AiChatProvider>().setProductContext(book.id);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('開啟問答'),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _requireAuthToken(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final existingToken = authProvider.authToken;
    if (existingToken != null && existingToken.isNotEmpty) {
      return existingToken;
    }

    if (!context.mounted) return null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請先登入會員才能使用 AI 對話功能。')),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    final refreshedToken = context.read<AuthProvider>().authToken;
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      return refreshedToken;
    }

    return null;
  }

  Widget _buildPodcastCard(BuildContext context) {
    if (_podcastNotFound && !_isCheckingPodcast) {
      return const SizedBox.shrink();
    }

    final hasSample = _podcastUrl != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.headset, color: Colors.pink, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podcast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                      hasSample
                          ? '播放 Taaze 提供的 Podcast'
                          : (_podcastError ??
                              (_isCheckingPodcast
                                  ? '正在檢查Podcast檔案…'
                                  : '暫無Podcast檔，可稍後再試')),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasSample
                                ? Colors.grey[700]
                                : Colors.grey[600],
                      ),
                      maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
                onPressed: hasSample
                    ? (_isPlayerLoading ? null : _togglePlayback)
                    : (_isCheckingPodcast ? null : () => _checkPodcastAvailability()),
                icon: hasSample
                    ? (_isPlayerLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isPlaying ? Icons.pause : Icons.play_arrow))
                    : (_isCheckingPodcast
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh)),
                label: Text(
                  hasSample
                      ? (_isPlayerLoading
                          ? '載入中'
                          : (_isPlaying ? '暫停' : '播放'))
                      : (_isCheckingPodcast ? '檢查中' : '重新搜尋'),
                ),
            style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasSample ? Colors.pink : Colors.grey[500],
              foregroundColor: Colors.white,
            ),
          ),
            ],
          ),
          if (hasSample) ...[
            const SizedBox(height: 12),
            _buildAudioControls(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioControls(BuildContext context) {
    final duration = _audioDuration ?? Duration.zero;
    final hasDuration = duration.inMilliseconds > 0;
    final progress = hasDuration
        ? (_audioPosition.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: progress,
          onChanged: hasDuration ? _seekToFraction : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_audioPosition),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              hasDuration ? _formatDuration(duration) : '--:--',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        if (_playerError != null) ...[
          const SizedBox(height: 6),
          Text(
            _playerError!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.red[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('讀者評論', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // 模擬評論
          _buildReviewItem(context, '張小明', '這本書內容豐富，講解詳細，非常適合初學者學習。', 5),
          _buildReviewItem(context, '李小華', '實用的技術書籍，推薦給想要學習的開發者。', 4),
          _buildReviewItem(context, '王小強', '書中的範例程式碼很完整，跟著做就能學會。', 5),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    BuildContext context,
    String name,
    String comment,
    int rating,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              ...List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 暫存按鈕
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final watchlistProvider = context.read<WatchlistProvider>();
                final messenger = ScaffoldMessenger.of(context);
                
                final bookId = book.id;
                if (bookId.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('無效的書籍 ID')),
                  );
                  return;
                }

                // 使用 WatchlistProvider 處理加入邏輯（內建登入與否的判斷）
                final success = await watchlistProvider.addToWatchlist(
                  bookId,
                  authToken: authProvider.authToken,
                );

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('已加入暫存')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('加入暫存失敗，請稍後再試')),
                  );
                }
              },
              icon: const Icon(FontAwesomeIcons.heart),
              label: const Text('暫存'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 加入購物車按鈕
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: book.isAvailable
                  ? () {
                      context.read<CartProvider>().addToCart(book);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已將《${book.title}》加入購物車'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(FontAwesomeIcons.cartPlus),
              label: Text(book.isAvailable ? '加入購物車' : '缺貨'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: book.isAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Book _mergeBookWithTaazeData(
    Book original,
    Map<String, dynamic> data,
  ) {
    final prodId = data['prodId']?.toString();
    final orgId = data['orgProdId']?.toString();
    final lookupId = orgId?.isNotEmpty == true
        ? orgId
        : (prodId?.isNotEmpty == true ? prodId : null);

    final imageUrl = lookupId != null && lookupId.isNotEmpty
        ? 'https://media.taaze.tw/showThumbnail.html?sc=$lookupId&height=400&width=310'
        : original.imageUrl;

    final description =
        _cleanTaazeText(data['prodPf']?.toString()) ?? original.description;
    final publishDate =
        _tryParseTaazeDate(data['publishDate']) ?? original.publishDate;

    return original.copyWith(
      title: _nonEmpty(data['titleMain']) ?? original.title,
      author: _nonEmpty(data['author']) ?? original.author,
      description: description,
      price: _tryParseOptionalDouble(data['salePrice']) ??
          _tryParseOptionalDouble(data['listPrice']) ??
          original.price,
      imageUrl: imageUrl,
      category: _nonEmpty(data['catName']) ??
          _nonEmpty(data['prodCatNm']) ??
          original.category,
      rating:
          _tryParseOptionalDouble(data['starLevel']) ?? original.rating,
      reviewCount:
          _tryParseOptionalInt(data['seekNum']) ?? original.reviewCount,
      isAvailable:
          ((_nonEmpty(data['outOfPrint']) ?? 'N').toUpperCase() != 'Y'),
      publishDate: publishDate,
      isbn: _nonEmpty(data['isbn']) ?? original.isbn,
      pages: _tryParseOptionalInt(data['pages']) ?? original.pages,
      publisher: _nonEmpty(data['pubNmMain']) ?? original.publisher,
      orgProdId: orgId ?? original.orgProdId ?? prodId ?? original.id,
    );
  }

  String? _cleanTaazeText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _stripHtmlTags(
      value
          .replaceAll('<br>', '\n')
          .replaceAll('\\r', '\n')
          .replaceAll('\r', '\n'),
    ).trim();
  }

  DateTime? _tryParseTaazeDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.length == 8 && RegExp(r'^\d{8}$').hasMatch(text)) {
      final year = int.tryParse(text.substring(0, 4));
      final month = int.tryParse(text.substring(4, 6));
      final day = int.tryParse(text.substring(6, 8));
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(text);
  }

  String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _formatTaazeDateRange(String? start, String? end) {
    final startDate = _tryParseTaazeDate(start);
    final endDate = _tryParseTaazeDate(end);
    if (startDate == null && endDate == null) return '';
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
    if (startDate != null) return '自 ${_formatDate(startDate)} 起';
    return '至 ${_formatDate(endDate!)} 止';
  }

  int? _tryParseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _tryParseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _normalizeDescription(String description) {
    if (description.trim().isEmpty) {
      return '暫無內容簡介';
    }
    return _stripHtmlTags(description);
  }

  String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  Future<void> _resetAudioPlaybackState() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}

    if (!mounted) {
      _podcastUrl = null;
      _loadedPodcastUrl = null;
      _audioDuration = null;
      _audioPosition = Duration.zero;
      _isPlaying = false;
      _isPlayerLoading = false;
      _playerError = null;
      _podcastError = null;
      _podcastNotFound = false;
      return;
    }

    setState(() {
      _podcastUrl = null;
      _loadedPodcastUrl = null;
      _audioDuration = null;
      _audioPosition = Duration.zero;
      _isPlaying = false;
      _isPlayerLoading = false;
      _playerError = null;
      _podcastError = null;
      _podcastNotFound = false;
    });
  }

  Future<void> _ensureAudioPlayer() async {
    if (_audioPlayer != null) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    final player = AudioPlayer();

    player.playerStateStream.listen((state) {
      if (!mounted) return;
      final buffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      setState(() {
        _isPlayerLoading = buffering;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _audioPosition = _audioDuration ?? Duration.zero;
        } else {
          _isPlaying = state.playing && !buffering;
        }
      });
    });

    player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _audioPosition = position;
      });
    });

    player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _audioDuration = duration;
      });
    });

    _audioPlayer = player;
  }

  Future<void> _startPlayback() async {
    final url = _podcastUrl;
    if (url == null) return;
    await _ensureAudioPlayer();

    try {
      if (mounted) {
        setState(() {
          _isPlayerLoading = true;
          _playerError = null;
        });
      }

      if (_loadedPodcastUrl != url) {
        final duration = await _audioPlayer!.setUrl(url);
        if (mounted) {
          setState(() {
            _audioDuration = duration;
            _audioPosition = Duration.zero;
          });
        }
        _loadedPodcastUrl = url;
      }

      await _audioPlayer!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _playerError = '播放失敗：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlayerLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_podcastUrl == null || _isPlayerLoading) return;
    await _ensureAudioPlayer();

    if (_isPlaying) {
      await _audioPlayer?.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      await _startPlayback();
    }
  }

  void _seekToFraction(double value) {
    final duration = _audioDuration;
    if (duration == null || _audioPlayer == null) return;
    final clamped = value.clamp(0.0, 1.0);
    final targetMillis = (duration.inMilliseconds * clamped).round();
    final position = Duration(milliseconds: targetMillis);
    _audioPlayer!.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      final h = hours.toString().padLeft(2, '0');
      return '$h:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

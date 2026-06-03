import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../models/book.dart';
import '../services/podcast_progress_service.dart';
import 'cached_image_widget.dart';

/// 聽書專區列表：書封／書名在上，Podcast 播放器在下。
class PodcastHubBookTile extends StatelessWidget {
  final Book book;
  final int? savedProgressMs;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onProgressUpdated;

  const PodcastHubBookTile({
    super.key,
    required this.book,
    this.savedProgressMs,
    this.onOpenDetail,
    this.onProgressUpdated,
  });

  String? get _lookupId {
    final org = book.orgProdId?.trim();
    if (org != null && org.isNotEmpty) return org;
    final id = book.id.trim();
    return id.isEmpty ? null : id;
  }

  String get _progressBookId => book.orgProdId ?? book.id;

  static String formatProgressLabel(int? ms) {
    if (ms == null || ms <= 0) return '';
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '續聽 ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressLabel = formatProgressLabel(savedProgressMs);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookCover(imageUrl: book.imageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.podcasts_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Podcast 試聽',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (book.author.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            book.author,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (progressLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              progressLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onOpenDetail != null)
                    IconButton(
                      onPressed: onOpenDetail,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '書籍詳情',
                    ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          PodcastInlinePlayer(
            lookupId: _lookupId,
            progressBookId: _progressBookId,
            onProgressSaved: onProgressUpdated,
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String imageUrl;

  const _BookCover({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl.isNotEmpty
            ? BookCoverImage(
                imageUrl: imageUrl,
                width: 72,
                height: 96,
                fit: BoxFit.cover,
              )
            : ColoredBox(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 36,
                  color: Colors.grey.shade500,
                ),
              ),
      ),
    );
  }
}

class PodcastInlinePlayer extends StatefulWidget {
  final String? lookupId;
  final String progressBookId;
  final VoidCallback? onProgressSaved;

  const PodcastInlinePlayer({
    super.key,
    required this.lookupId,
    required this.progressBookId,
    this.onProgressSaved,
  });

  @override
  State<PodcastInlinePlayer> createState() => _PodcastInlinePlayerState();
}

class _PodcastInlinePlayerState extends State<PodcastInlinePlayer> {
  String? _podcastUrl;
  bool _isChecking = true;
  bool _notFound = false;
  String? _checkError;

  AudioPlayer? _player;
  String? _loadedUrl;
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _playerError;
  DateTime? _lastProgressSave;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  @override
  void didUpdateWidget(PodcastInlinePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lookupId != widget.lookupId) {
      _resetAndCheck();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _resetAndCheck() async {
    await _player?.stop();
    _player?.dispose();
    _player = null;
    _loadedUrl = null;
    if (!mounted) return;
    setState(() {
      _podcastUrl = null;
      _duration = null;
      _position = Duration.zero;
      _isPlaying = false;
      _isLoading = false;
      _playerError = null;
      _notFound = false;
    });
    await _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final lookupId = widget.lookupId;
    if (lookupId == null) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _notFound = true;
        });
      }
      return;
    }

    setState(() {
      _isChecking = true;
      _checkError = null;
      _notFound = false;
    });

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
          _notFound = true;
          _checkError = null;
        });
        return;
      }

      if ((response.statusCode == 301 || response.statusCode == 302) &&
          response.headers['location']?.isNotEmpty == true) {
        setState(() {
          _podcastUrl = response.headers['location'];
          _notFound = false;
        });
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _podcastUrl = uri.toString();
          _notFound = false;
        });
        return;
      }

      setState(() {
        _checkError = '無法取得試聽檔（${response.statusCode}）';
        _podcastUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkError = '試聽檢查失敗';
        _podcastUrl = null;
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _ensurePlayer() async {
    if (_player != null) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    final player = AudioPlayer();

    player.playerStateStream.listen((state) {
      if (!mounted) return;
      final buffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      setState(() {
        _isLoading = buffering;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _position = _duration ?? Duration.zero;
        } else {
          _isPlaying = state.playing && !buffering;
        }
      });
    });

    player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      final now = DateTime.now();
      if (_lastProgressSave == null ||
          now.difference(_lastProgressSave!) > const Duration(seconds: 3)) {
        _lastProgressSave = now;
        PodcastProgressService.savePosition(widget.progressBookId, position);
        widget.onProgressSaved?.call();
      }
    });

    player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    _player = player;
  }

  Future<void> _togglePlayback() async {
    final url = _podcastUrl;
    if (url == null || _isLoading) return;
    await _ensurePlayer();

    if (_isPlaying) {
      await _player?.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _playerError = null;
      });

      if (_loadedUrl != url) {
        final duration = await _player!.setUrl(url);
        final saved =
            await PodcastProgressService.loadPosition(widget.progressBookId);
        if (mounted) {
          setState(() {
            _duration = duration;
            _position = saved ?? Duration.zero;
          });
        }
        if (saved != null && saved > Duration.zero) {
          await _player!.seek(saved);
        }
        _loadedUrl = url;
      }

      await _player!.play();
    } catch (e) {
      if (mounted) setState(() => _playerError = '播放失敗');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seek(double value) {
    final duration = _duration;
    if (duration == null || _player == null) return;
    final clamped = value.clamp(0.0, 1.0);
    final ms = (duration.inMilliseconds * clamped).round();
    _player!.seek(Duration(milliseconds: ms));
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasUrl = _podcastUrl != null;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isChecking)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_notFound)
            Text(
              '此書暫無 Podcast 試聽',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            )
          else if (_checkError != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _checkError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _checkAvailability,
                  child: const Text('重試'),
                ),
              ],
            )
          else if (hasUrl) ...[
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _togglePlayback,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_isLoading
                      ? '載入中'
                      : (_isPlaying ? '暫停' : '播放')),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _format(_position),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey[700],
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' / ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  _duration != null && _duration!.inMilliseconds > 0
                      ? _format(_duration!)
                      : '--:--',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey[700],
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: (_duration != null && _duration!.inMilliseconds > 0)
                    ? (_position.inMilliseconds / _duration!.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (_duration != null && _duration!.inMilliseconds > 0)
                    ? _seek
                    : null,
              ),
            ),
            if (_playerError != null)
              Text(
                _playerError!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red[700]),
              ),
          ],
        ],
      ),
    );
  }
}

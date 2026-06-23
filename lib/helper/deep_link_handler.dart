// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  static const _methodChannel = MethodChannel('com.kreen.app/deep_link');

  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final _AppLifecycleObserver _observer = _AppLifecycleObserver(this);

  StreamSubscription? _linkSubscription;
  Uri? _pendingUri;
  Uri? _lastProcessedUri;
  bool _isNavigating = false;
  bool _isProcessing = false;

  Map<String, dynamic> vote = {};
  Map<String, dynamic> event = {};

  bool get isNavigating => _isNavigating || _isProcessing;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(_observer);

    // Native MethodChannel — paling reliable
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLink') {
        final url = call.arguments as String?;
        debugPrint('=== NATIVE CHANNEL: $url ===');
        if (url != null) {
          final uri = Uri.tryParse(url);
          if (uri != null && uri != _lastProcessedUri) {
            _lastProcessedUri = uri;
            _handleLink(uri);
          }
        }
      }
    });

    // Ambil pending dari native
    try {
      final pendingUrl = await _methodChannel.invokeMethod<String>('getPendingLink');
      if (pendingUrl != null) {
        debugPrint('=== NATIVE PENDING: $pendingUrl ===');
        _pendingUri = Uri.tryParse(pendingUrl);
      }
    } catch (e) {
      debugPrint('getPendingLink error: $e');
    }

    // Stream sebagai backup
    _subscribeLinkStream();

    // Cold start
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('Deep link cold start: $initialUri');
      _pendingUri = initialUri;
    }
  }

  void _subscribeLinkStream() {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('=== STREAM EMIT: $uri ===');
        if (uri != _lastProcessedUri) {
          _lastProcessedUri = uri;
          _handleLink(uri);
        }
      },
      onError: (e) {
        debugPrint('STREAM ERROR: $e — re-subscribe');
        Future.delayed(const Duration(seconds: 1), _subscribeLinkStream);
      },
      onDone: () {
        debugPrint('STREAM DONE — re-subscribe');
        Future.delayed(const Duration(seconds: 1), _subscribeLinkStream);
      },
    );
  }

  void onAppResumed() {
    debugPrint('App resumed | isNavigating: $_isNavigating');

    _subscribeLinkStream();

    if (_isNavigating || _isProcessing) {
      debugPrint('Sedang navigasi/processing, skip onAppResumed check');
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_isNavigating || _isProcessing) return; // double check

      try {
        final uri = await _appLinks.getLatestLink();
        if (uri != null && uri != _lastProcessedUri) {
          debugPrint('resumed getLatestLink: $uri');
          _lastProcessedUri = uri;
          if (_pendingUri == null) {
            _handleLink(uri);
            return;
          }
        }
      } catch (e) {
        debugPrint('getLatestLink error: $e');
      }

      if (_pendingUri != null) {
        final uri = _pendingUri!;
        _pendingUri = null;
        debugPrint('Proses pending di resumed: $uri');
        _waitAndProcess(uri);
      }
    });
  }

  void _handleLink(Uri uri) {
    debugPrint('_handleLink | isNavigating: $_isNavigating | lifecycle: ${WidgetsBinding.instance.lifecycleState}');

    if (_isNavigating) {
      debugPrint('Sedang navigasi, pending: $uri');
      _pendingUri = uri;
      return;
    }

    _waitAndProcess(uri);
  }

  Future<void> _waitAndProcess(Uri uri, {int maxRetries = 30}) async {
    if (_isProcessing) {
      debugPrint('_waitAndProcess sudah berjalan, skip: $uri');
      _pendingUri = uri; // simpan yang terbaru
      return;
    }
    _isProcessing = true;
    debugPrint('_waitAndProcess START');

    try {
      for (int i = 0; i < maxRetries; i++) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final hasContext = navigatorKey.currentContext != null;
        debugPrint('Retry $i: lifecycle=$lifecycle | hasContext=$hasContext | isNavigating=$_isNavigating');

        if (_isNavigating) {
          // Kalau masih navigasi setelah 10 retry, force reset
          if (i >= 10) {
            debugPrint('FORCE RESET isNavigating setelah $i retry');
            _isNavigating = false;
          }
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }

        if (hasContext && 
            (lifecycle == AppLifecycleState.resumed || 
            lifecycle == null)) { // null = belum ada lifecycle event, proses saja
          debugPrint('READY di retry $i: proses uri');
          _processUri(uri, navigatorKey.currentContext!);
          return;
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      debugPrint('TIMEOUT, fallback proses langsung');
      final ctx = navigatorKey.currentContext;
      if (ctx != null && !_isNavigating) {
        _processUri(uri, ctx);
      } else {
        // Simpan kembali sebagai pending, akan diproses saat resumed
        debugPrint('Simpan kembali sebagai pending');
        _pendingUri = uri;
      }
    } finally {
      _isProcessing = false;
      debugPrint('_waitAndProcess DONE');
    }
  }

  void processPendingLink() {
    if (_pendingUri == null) return;
    final uri = _pendingUri!;
    _pendingUri = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        _processUri(uri, context);
      }
    });
  }

  void _processUri(Uri uri, BuildContext context) {
    final isHttps = uri.scheme == 'https' && uri.host == baseHost;
    if (!isHttps) return;
    if (!uri.path.contains('/mobile-deeplink')) return;

    final rawData = uri.queryParameters['data'];
    if (rawData == null) return;

    debugPrint('Deep link rawData: $rawData');

    final parts = rawData.split(':');
    if (parts.length < 3) return;

    final lang = parts[0];
    final currency = parts[1];
    final destination = parts[2];

    debugPrint('Lang: $lang | Currency: $currency | Destination: $destination');

    switch (destination.toLowerCase()) {
      case 'home':
        _navigateToHome();
        break;
      case 'vote':
        if (parts.length == 4) {
          _navigateToVote(parts[3]);
        } else if (parts.length == 5) {
          _navigateToFinalis(parts[3], parts[4], lang, currency.toUpperCase());
        }
        break;
      case 'event':
        _navigateToEvent(parts[3], lang, currency.toUpperCase());
        break;
      default:
        _navigateToHome();
    }
  }

  Future<bool> _resetToHome() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('_resetToHome: navigatorState null');
      return false;
    }

    debugPrint('_resetToHome: mulai clear stack');

    // Jangan await — langsung fire and forget, lalu delay
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );

    // Tunggu animasi selesai + HomePage build
    await Future.delayed(const Duration(milliseconds: 800));
    
    debugPrint('_resetToHome: selesai, context: ${navigatorKey.currentContext != null}');
    return navigatorKey.currentContext != null;
  }

  Future<BuildContext?> _waitForContext({int maxRetries = 20}) async {
    for (int i = 0; i < maxRetries; i++) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        debugPrint('_waitForContext: dapat context di retry $i');
        return ctx;
      }
      debugPrint('_waitForContext retry $i: null');
      await Future.delayed(const Duration(milliseconds: 150));
    }
    debugPrint('_waitForContext: TIMEOUT');
    return null;
  }

  void _checkPendingLink() {
    if (_pendingUri == null) return;
    final uri = _pendingUri!;
    _pendingUri = null;
    _waitAndProcess(uri);
  }

  void _navigateToHome() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await _resetToHome();
    } catch (e, s) {
      debugPrint('ERROR _navigateToHome: $e\n$s');
    } finally {
      _isNavigating = false;
      _checkPendingLink();
    }
  }

  void _navigateToVote(String voteId) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      debugPrint('_resetToHome START (vote)');
      final ok = await _resetToHome();
      debugPrint('_resetToHome result: $ok');
      if (!ok) return;

      final ctx = await _waitForContext();
      debugPrint('_waitForContext result: ${ctx != null}');
      if (ctx == null) return;

      debugPrint('Push DetailVotePage NOW');
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => DetailVotePage(id_event: voteId)),
      );
      debugPrint('Push DetailVotePage DONE');
    } catch (e, s) {
      debugPrint('ERROR _navigateToVote: $e\n$s');
    } finally {
      _isNavigating = false;
      debugPrint('_navigateToVote DONE');
      _checkPendingLink();
    }
  }

  void _navigateToFinalis(
    String voteId,
    String finalisId,
    String lang,
    String currency,
  ) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      // Fetch data DULU sebelum clear stack
      await getInfoVote(voteId, lang, currency);
      debugPrint('getInfoVote done: ${vote.keys}');

      if (vote.isEmpty) {
        debugPrint('ERROR: vote data kosong');
        return;
      }

      debugPrint('_resetToHome START (finalis)');
      final ok = await _resetToHome();
      debugPrint('_resetToHome result: $ok');
      if (!ok) return;

      final ctx = await _waitForContext();
      debugPrint('_waitForContext result: ${ctx != null}');
      if (ctx == null) return;

      final tanggal = _formatDate(
        lang,
        vote['tanggal_buka_payment']?.toString(),
        includeTime: true,
      );
      final viewApi = _getViewApi(vote['leaderboard_tipe']);
      debugPrint('flag_paket: ${vote['flag_paket']} | viewApi: $viewApi');

      if (vote['flag_paket'] == '0') {
        debugPrint('Push LeaderboardSingleVote NOW');
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => LeaderboardSingleVote(
              id_finalis: finalisId,
              count: 0,
              indexWrap: null,
              close_payment: vote['close_payment'],
              tanggal_buka_vote: tanggal,
              flag_hide_nomor_urut: vote['flag_hide_nomor_urut'],
              currencyCode: currency,
              view_api: viewApi,
            ),
          ),
        );
        debugPrint('Push LeaderboardSingleVote DONE');
      } else {
        final idFinalis = vote['id_finalis']?.toString();
        if (idFinalis == null) {
          debugPrint('ERROR: vote[id_finalis] null');
          return;
        }
        debugPrint('Push LeaderboardSingleVotePaket NOW');
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => LeaderboardSingleVotePaket(
              id_finalis: idFinalis,
              vote: 0, index: 0, total_detail: 0, id_paket_bw: null,
              close_payment: vote['close_payment'],
              tanggal_buka_vote: tanggal,
              flag_hide_nomor_urut: vote['flag_hide_nomor_urut'],
              currencyCode: currency,
              view_api: viewApi,
            ),
          ),
        );
        debugPrint('Push LeaderboardSingleVotePaket DONE');
      }
    } catch (e, s) {
      debugPrint('ERROR _navigateToFinalis: $e\n$s');
    } finally {
      _isNavigating = false;
      debugPrint('_navigateToFinalis DONE');
      _checkPendingLink();
    }
  }

  void _navigateToEvent(String eventId, String lang, String currency) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await getInfoEvent(eventId, lang, currency);
      debugPrint('getInfoEvent done: ${event.keys}');

      if (event.isEmpty) {
        debugPrint('ERROR: event data kosong, batalkan navigasi');
        return;
      }

      final tickets = event['event_ticket'];
      if (tickets == null || tickets.isEmpty) {
        debugPrint('ERROR: event_ticket kosong');
        return;
      }

      debugPrint('_resetToHome START');
      final ok = await _resetToHome();
      debugPrint('_resetToHome result: $ok');
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) {
        debugPrint('ERROR: context null setelah _resetToHome');
        return;
      }

      debugPrint('Push DetailEventPage');
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => DetailEventPage(
            id_event: eventId,
            price: tickets[0]['price'],
            currencyCode: event['event']['currency_code'] ?? currency,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('ERROR _navigateToEvent: $e\n$s');
    } finally {
      _isNavigating = false;
      debugPrint('_navigateToEvent DONE');
      _checkPendingLink();
    }
  }

  int _getViewApi(String? tipe) {
    switch (tipe) {
      case 'number': return 2;
      case 'percent': return 3;
      case 'hidden': return 4;
      case 'bar-percent': return 5;
      case 'bar-number': return 6;
      default: return 0;
    }
  }

  Future<void> getInfoVote(String idVote, String langCode, String currencyCode) async {
    final result = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
    vote = result?['data'] ?? {};
  }

  Future<void> getInfoEvent(String idEvent, String langCode, String currencyCode) async {
    final body = {"id_event": idEvent};
    final result = await ApiService.post('/event/detail', body: body, xCurrency: currencyCode, xLanguage: langCode);
    event = result?['data'] ?? {};
  }

  String _formatDate(String langCode, String? dateStr, {bool includeTime = false}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      if (langCode == 'id') {
        final pattern = includeTime ? "$formatDateId HH:mm" : "$formatDay, $formatDateId";
        return DateFormat(pattern, "id_ID").format(date);
      } else {
        final pattern = includeTime ? "$formatDateEn HH:mm" : "$formatDay, $formatDateEn";
        String formatted = DateFormat(pattern, "en_US").format(date);
        final day = date.day;
        String suffix = 'th';
        if (day % 10 == 1 && day != 11) { suffix = 'st'; }
        else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
        else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
        return formatted.replaceFirst('$day', '$day$suffix');
      }
    } catch (_) {
      return '-';
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_observer);
  }
}

// Observer terpisah — bebas dari conflict method
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final DeepLinkHandler handler;
  _AppLifecycleObserver(this.handler);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('=== AppLifecycle: $state ===');
    if (state == AppLifecycleState.resumed) {
      handler.onAppResumed();
    }
  }
}
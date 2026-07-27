// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

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
    
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLink') {
        final url = call.arguments as String?;
        if (url != null) {
          final uri = Uri.tryParse(url);
          if (uri != null && uri != _lastProcessedUri) {
            _lastProcessedUri = uri;
            _handleLink(uri);
          }
        }
      }
    });
    
    try {
      final pendingUrl = await _methodChannel.invokeMethod<String>('getPendingLink');
      if (pendingUrl != null) {
        _pendingUri = Uri.tryParse(pendingUrl);
      }
    } catch (e) {
      // debugPrint('Error ambil pending link: $e');
    }
    
    _subscribeLinkStream();
    
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _pendingUri = initialUri;
    }
  }

  void _subscribeLinkStream() {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri != _lastProcessedUri) {
          _lastProcessedUri = uri;
          _handleLink(uri);
        }
      },
      onError: (e) {
        Future.delayed(const Duration(seconds: 1), _subscribeLinkStream);
      },
      onDone: () {
        Future.delayed(const Duration(seconds: 1), _subscribeLinkStream);
      },
    );
  }

  void onAppResumed() {

    _subscribeLinkStream();

    if (_isNavigating || _isProcessing) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_isNavigating || _isProcessing) return;

      try {
        final uri = await _appLinks.getLatestLink();
        if (uri != null && uri != _lastProcessedUri) {
          _lastProcessedUri = uri;
          if (_pendingUri == null) {
            _handleLink(uri);
            return;
          }
        }
      } catch (e) {
        // debugPrint('getLatestLink error: $e');
      }

      if (_pendingUri != null) {
        final uri = _pendingUri!;
        _pendingUri = null;
        _waitAndProcess(uri);
      }
    });
  }

  void _handleLink(Uri uri) {

    if (_isNavigating) {
      _pendingUri = uri;
      return;
    }

    _waitAndProcess(uri);
  }

  Future<void> _waitAndProcess(Uri uri, {int maxRetries = 30}) async {
    if (_isProcessing) {
      _pendingUri = uri;
      return;
    }
    _isProcessing = true;

    try {
      for (int i = 0; i < maxRetries; i++) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final hasContext = navigatorKey.currentContext != null;

        if (_isNavigating) {
          if (i >= 10) {
            _isNavigating = false;
          }
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }

        if (hasContext && 
            (lifecycle == AppLifecycleState.resumed || 
            lifecycle == null)) {
          _processUri(uri, navigatorKey.currentContext!);
          return;
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      final ctx = navigatorKey.currentContext;
      if (ctx != null && !_isNavigating) {
        _processUri(uri, ctx);
      } else {
        _pendingUri = uri;
      }
    } finally {
      _isProcessing = false;
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

    final parts = rawData.split(':');
    if (parts.length < 3) return;

    final lang = parts[0];
    final currency = parts[1];
    final destination = parts[2];

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
        if (parts.length == 4) {
          _navigateToEvent(parts[3], lang, currency.toUpperCase());
        }
        break;
      default:
        _navigateToHome();
    }
  }

  Future<bool> _resetToHome() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return false;
    }
    
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
    
    await Future.delayed(const Duration(milliseconds: 800));
    return navigatorKey.currentContext != null;
  }

  Future<BuildContext?> _waitForContext({int maxRetries = 20}) async {
    for (int i = 0; i < maxRetries; i++) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        return ctx;
      }
      
      await Future.delayed(const Duration(milliseconds: 150));
    }
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
    } finally {
      _isNavigating = false;
      _checkPendingLink();
    }
  }

  void _navigateToVote(String voteId) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final ok = await _resetToHome();
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) return;
      
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => DetailVotePage(id_event: voteId)),
      );
    } finally {
      _isNavigating = false;
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
      await getInfoVote(voteId, lang, currency);

      if (vote.isEmpty) {
        return;
      }
      
      final ok = await _resetToHome();
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) return;

      final tanggal = _formatDate(
        lang,
        vote['tanggal_buka_payment']?.toString(),
        includeTime: true,
      );
      final viewApi = _getViewApi(vote['leaderboard_tipe']);

      if (vote['flag_paket'] == '0') {
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
      } else {
        final idFinalis = finalisId;

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
      }
    } finally {
      _isNavigating = false;
      _checkPendingLink();
    }
  }

  void _navigateToEvent(String eventId, String lang, String currency) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await getInfoEvent(eventId, lang, currency);

      if (event.isEmpty) {
        return;
      }

      final tickets = event['event_ticket'];
      if (tickets == null || tickets.isEmpty) {
        return;
      }
      
      final ok = await _resetToHome();
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) {
        return;
      }
      
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
    } finally {
      _isNavigating = false;
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
    String? token = await StorageService.getToken();
    final result = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode, token: token);
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

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final DeepLinkHandler handler;
  _AppLifecycleObserver(this.handler);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      handler.onAppResumed();
    }
  }
}
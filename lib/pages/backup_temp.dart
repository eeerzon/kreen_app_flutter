// ignore_for_file: use_build_context_synchronously

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';

class DeepLinkData {
  final String lang;
  final String currency;
  final String destination;
  final String? voteId;
  final String? finalisId;

  DeepLinkData({
    required this.lang,
    required this.currency,
    required this.destination,
    this.voteId,
    this.finalisId,
  });
}

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Uri? _pendingUri;
  bool _isNavigating = false;
  Map<String, dynamic> vote = {};
  Map<String, dynamic> event = {};

  Future<void> init() async {
    // Handle saat app foreground
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link foreground: $uri');
      _handleLink(uri);
    });

    // Handle cold start
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('Deep link cold start: $initialUri');
      // _handleLink(initialUri);
      _pendingUri = initialUri;
    }
  }

  void _handleLink(Uri uri) {
    if (_isNavigating) {
      _pendingUri = uri;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('Context null, simpan pending: $uri');
        _pendingUri = uri;
        return;
      }
      _processUri(uri, context);
    });
  }

  // Panggil di HomePage setelah semua init selesai
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
    // Validasi
    final isHttps = uri.scheme == 'https' && uri.host == 'dev.kreenconnect.com';

    if (!isHttps) return;
    if (!uri.path.contains('/mobile-deeplink')) return;

    final rawData = uri.queryParameters['data'];
    if (rawData == null) return;

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

  // ─── Helper: clear stack ke HomePage dengan aman ───────────────────────────
  Future<bool> _resetToHome() async {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );

    // Tunggu frame selesai setelah navigasi
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // ─── Tunggu context valid setelah navigasi ──────────────────────────────────
  Future<BuildContext?> _waitForContext({int maxRetries = 10}) async {
    for (int i = 0; i < maxRetries; i++) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) return ctx;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return null;
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

      final ok = await _resetToHome();
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) return;

      final tanggal = _formatDate(lang, vote['tanggal_buka_payment']?.toString(), includeTime: true);

      int viewApi = _getViewApi(vote['leaderboard_tipe']);

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
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => LeaderboardSingleVotePaket(
              id_finalis: vote['id_finalis'].toString(),
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
      // Fetch data SEBELUM clear stack — hindari async setelah navigasi
      await getInfoEvent(eventId, lang, currency);

      final ok = await _resetToHome();
      if (!ok) return;

      final ctx = await _waitForContext();
      if (ctx == null) return;

      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => DetailEventPage(
            id_event: eventId,
            price: event['event_ticket'][0]['price'],
            currencyCode: event['event']['currency_code'] ?? currency,
          ),
        ),
      );
    } finally {
      _isNavigating = false;
      _checkPendingLink();
    }
  }

  // Kalau ada pending link setelah navigasi selesai, proses sekarang
  void _checkPendingLink() {
    if (_pendingUri == null) return;
    final uri = _pendingUri!;
    _pendingUri = null;
    _handleLink(uri);
  }

  // ─── Helper: mapping leaderboard_tipe → view_api ───────────────────────────
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

  // ─── API calls ──────────────────────────────────────────────────────────────
  Future<void> getInfoVote(String idVote, String langCode, String currencyCode) async {
    final result = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
    vote = result?['data'] ?? {};
  }

  Future<void> getInfoEvent(String idEvent, String langCode, String currencyCode) async {
    final body = {"id_event": idEvent};
    final result = await ApiService.post('/event/detail', body: body, xCurrency: currencyCode, xLanguage: langCode);
    event = result?['data'] ?? {};
  }

  // ─── Format tanggal ─────────────────────────────────────────────────────────
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
}
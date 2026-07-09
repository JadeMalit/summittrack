import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'native_dns_lookup.dart'
    if (dart.library.io) 'native_dns_lookup_io.dart'
    as native_dns;

enum InternetConnectionStatus { unknown, checking, online, offline }

typedef ConnectivityResultsReader =
    Future<List<ConnectivityResult>?> Function();
typedef NativeDnsLookup = Future<bool?> Function(String host, Duration timeout);
typedef HttpsGet = Future<http.Response> Function(Uri uri);

class ConnectivityService {
  ConnectivityService._({
    ConnectivityResultsReader? connectivityResultsReader,
    NativeDnsLookup? nativeDnsLookup,
    bool? nativeDnsLookupSupported,
    HttpsGet? httpsGet,
  }) : _connectivityResultsReader = connectivityResultsReader,
       _nativeDnsLookup = nativeDnsLookup ?? native_dns.canResolveHost,
       _nativeDnsLookupSupported =
           nativeDnsLookupSupported ?? native_dns.isSupported,
       _httpsGet = httpsGet ?? http.get;

  @visibleForTesting
  ConnectivityService.testing({
    ConnectivityResultsReader? connectivityResultsReader,
    NativeDnsLookup? nativeDnsLookup,
    bool? nativeDnsLookupSupported,
    HttpsGet? httpsGet,
  }) : this._(
         connectivityResultsReader: connectivityResultsReader,
         nativeDnsLookup: nativeDnsLookup,
         nativeDnsLookupSupported: nativeDnsLookupSupported,
         httpsGet: httpsGet,
       );

  static final ConnectivityService instance = ConnectivityService._();
  final Connectivity _connectivity = Connectivity();
  final ConnectivityResultsReader? _connectivityResultsReader;
  final NativeDnsLookup _nativeDnsLookup;
  final bool _nativeDnsLookupSupported;
  final HttpsGet _httpsGet;

  static const List<String> _lookupHosts = [
    'google.com',
    'cloudflare.com',
    'example.com',
    'microsoft.com',
  ];
  static const List<String> _httpsFallbackUrls = [
    'https://www.google.com/generate_204',
    'https://www.gstatic.com/generate_204',
    'https://cloudflare.com/cdn-cgi/trace',
    'https://example.com',
  ];
  static const Duration _timeout = Duration(seconds: 2);
  static const Duration _retryDelay = Duration(seconds: 1);

  Stream<void> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((_) {});
  }

  Future<InternetConnectionStatus> checkInternetStatus({
    int attempts = 3,
    bool isStartupCheck = false,
  }) async {
    if (isStartupCheck) {
      _log('app startup internet check started');
    }

    final maxAttempts = attempts < 1 ? 1 : attempts;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt == 0) {
        _log('platform: ${kIsWeb ? 'web' : 'native'}');
      }

      final connectivityResults = await _safeConnectivityResults();
      final hasNetworkTransport = _hasNetworkTransport(connectivityResults);
      final formattedConnectivity = _formatConnectivityResults(
        connectivityResults,
      );

      _log(
        'connectivity result attempt ${attempt + 1}/$maxAttempts: '
        '$formattedConnectivity '
        '(hasNetworkTransport: $hasNetworkTransport)',
      );
      _log('connectivity result: $formattedConnectivity');
      _log('hasNetworkTransport: $hasNetworkTransport');
      _log('network transport available: $hasNetworkTransport');

      final hasAccess = hasNetworkTransport
          ? await _hasInternetAccess()
          : false;
      _log('real internet result: $hasAccess');
      _log(
        'real internet lookup result attempt ${attempt + 1}/$maxAttempts: '
        '$hasAccess',
      );

      if (hasAccess) {
        _log('offline confirmed false');
        _log('final state: ONLINE');
        _log('no internet modal: false');
        return InternetConnectionStatus.online;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }

    _log('offline confirmed true');
    _log('final state: OFFLINE');
    return InternetConnectionStatus.offline;
  }

  Future<bool> hasInternetConnection() async {
    final status = await checkInternetStatus();
    return status == InternetConnectionStatus.online;
  }

  Future<List<ConnectivityResult>?> _safeConnectivityResults() async {
    try {
      final readConnectivity =
          _connectivityResultsReader ?? _connectivity.checkConnectivity;
      return await readConnectivity().timeout(_timeout);
    } on TimeoutException catch (error) {
      _log(
        'connectivity result unavailable with exact exception: '
        '${error.runtimeType}: $error',
      );
      return null;
    } catch (error) {
      _log(
        'connectivity result unavailable with exact exception: '
        '${error.runtimeType}: $error',
      );
      return null;
    }
  }

  bool _hasNetworkTransport(List<ConnectivityResult>? results) {
    if (results == null || results.isEmpty) {
      return true;
    }

    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> _hasInternetAccess() async {
    final hasDnsAccess = await _hasDnsAccess();
    if (hasDnsAccess) {
      _log('internet confirmed: true');
      return true;
    }

    final hasHttpsFallbackAccess = await _hasHttpsFallbackAccess();
    _log('internet confirmed: $hasHttpsFallbackAccess');
    return hasHttpsFallbackAccess;
  }

  Future<bool> _hasDnsAccess() async {
    if (!_nativeDnsLookupSupported) {
      final reason = kIsWeb
          ? 'unsupported on web'
          : 'unsupported on this platform';
      _log('native DNS lookup skipped: $reason');
      return false;
    }

    final results = await Future.wait(_lookupHosts.map(_canResolveHost));
    return results.any((hasAccess) => hasAccess == true);
  }

  Future<bool> _hasHttpsFallbackAccess() async {
    final results = await Future.wait(
      _httpsFallbackUrls.map(_canReachHttpsFallbackUrl),
    );
    return results.any((hasAccess) => hasAccess);
  }

  Future<bool?> _canResolveHost(String host) async {
    _log('DNS lookup started for $host');

    try {
      final hasAddress = await _nativeDnsLookup(host, _timeout);

      if (hasAddress == null) {
        _log('DNS lookup skipped for $host: unsupported on this platform');
        return null;
      }

      if (hasAddress) {
        _log('DNS lookup success for $host');
        return true;
      }

      _log(
        'DNS lookup failed for $host with exact exception: '
        'empty address list',
      );
      return false;
    } on TimeoutException catch (error) {
      _log(
        'DNS lookup failed for $host with exact exception: '
        '${error.runtimeType}: $error',
      );
      return false;
    } on UnsupportedError catch (error) {
      _log(
        'DNS lookup skipped for $host with exact exception: '
        '${error.runtimeType}: $error',
      );
      return null;
    } catch (error) {
      _log(
        'DNS lookup failed for $host with exact exception: '
        '${error.runtimeType}: $error',
      );
      return false;
    }
  }

  Future<bool> _canReachHttpsFallbackUrl(String url) async {
    _log('HTTPS fallback started for $url');

    try {
      final response = await _httpsGet(Uri.parse(url)).timeout(_timeout);
      final isReachable =
          response.statusCode >= 200 && response.statusCode < 500;

      if (isReachable) {
        _log(
          'HTTPS fallback success for $url with status code '
          '${response.statusCode}',
        );
        return true;
      }

      _log(
        'HTTPS fallback failed for $url with exact exception: '
        'HTTP status code ${response.statusCode}',
      );
      return false;
    } on TimeoutException catch (error) {
      _log(
        'HTTPS fallback failed for $url with exact exception: '
        '${error.runtimeType}: $error',
      );
      return false;
    } catch (error) {
      _log(
        'HTTPS fallback failed for $url with exact exception: '
        '${error.runtimeType}: $error',
      );
      return false;
    }
  }

  String _formatConnectivityResults(List<ConnectivityResult>? results) {
    if (results == null) {
      return 'unknown';
    }

    if (results.isEmpty) {
      return 'empty';
    }

    return results.map((result) => result.name).join(', ');
  }

  void _log(String message) {
    debugPrint('[ConnectivityService] $message');
  }
}

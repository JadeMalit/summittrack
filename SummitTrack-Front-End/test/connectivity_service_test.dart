import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:summittrack/core/services/connectivity_service.dart';

void main() {
  ConnectivityService service({
    required Future<List<ConnectivityResult>?> Function()
    connectivityResultsReader,
    required Future<bool?> Function(String host, Duration timeout)
    nativeDnsLookup,
    required bool nativeDnsLookupSupported,
    required Future<http.Response> Function(Uri uri) httpsGet,
  }) {
    return ConnectivityService.testing(
      connectivityResultsReader: connectivityResultsReader,
      nativeDnsLookup: nativeDnsLookup,
      nativeDnsLookupSupported: nativeDnsLookupSupported,
      httpsGet: httpsGet,
    );
  }

  test(
    'confirms online when DNS is unsupported and one HTTPS endpoint works',
    () async {
      final connectivityService = service(
        connectivityResultsReader: () async => [ConnectivityResult.wifi],
        nativeDnsLookupSupported: true,
        nativeDnsLookup: (_, _) async {
          throw UnsupportedError(
            'Unsupported operation: InternetAddress.lookup',
          );
        },
        httpsGet: (uri) async {
          if (uri.host == 'cloudflare.com') {
            return http.Response('ok', 200);
          }

          throw http.ClientException('Failed to fetch', uri);
        },
      );

      final status = await connectivityService.checkInternetStatus(attempts: 1);

      expect(status, InternetConnectionStatus.online);
    },
  );

  test(
    'skips native DNS lookup when the platform does not support it',
    () async {
      var dnsCalls = 0;
      final connectivityService = service(
        connectivityResultsReader: () async => [ConnectivityResult.wifi],
        nativeDnsLookupSupported: false,
        nativeDnsLookup: (_, _) async {
          dnsCalls++;
          throw StateError('DNS lookup should not run on this platform');
        },
        httpsGet: (uri) async {
          if (uri.host == 'cloudflare.com') {
            return http.Response('ok', 200);
          }

          throw http.ClientException('Failed to fetch', uri);
        },
      );

      final status = await connectivityService.checkInternetStatus(attempts: 1);

      expect(status, InternetConnectionStatus.online);
      expect(dnsCalls, isZero);
    },
  );

  test(
    'does not verify DNS or HTTPS when no network transport exists',
    () async {
      var dnsCalls = 0;
      var httpsCalls = 0;
      final connectivityService = service(
        connectivityResultsReader: () async => [ConnectivityResult.none],
        nativeDnsLookupSupported: true,
        nativeDnsLookup: (_, _) async {
          dnsCalls++;
          return true;
        },
        httpsGet: (_) async {
          httpsCalls++;
          return http.Response('ok', 200);
        },
      );

      final status = await connectivityService.checkInternetStatus(attempts: 1);

      expect(status, InternetConnectionStatus.offline);
      expect(dnsCalls, isZero);
      expect(httpsCalls, isZero);
    },
  );

  test(
    'keeps offline only when transport exists but every verification fails',
    () async {
      final connectivityService = service(
        connectivityResultsReader: () async => [ConnectivityResult.wifi],
        nativeDnsLookupSupported: true,
        nativeDnsLookup: (_, _) async => false,
        httpsGet: (uri) async {
          throw http.ClientException('Failed to fetch', uri);
        },
      );

      final status = await connectivityService.checkInternetStatus(attempts: 1);

      expect(status, InternetConnectionStatus.offline);
    },
  );
}

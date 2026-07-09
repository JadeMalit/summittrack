import 'dart:async';
import 'dart:io';

bool get isSupported => true;

Future<bool?> canResolveHost(String host, Duration timeout) async {
  final addresses = await InternetAddress.lookup(host).timeout(timeout);
  return addresses.any((address) => address.rawAddress.isNotEmpty);
}

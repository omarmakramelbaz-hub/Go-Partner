import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:go_partner/helpers/networking/api_helper.dart';
import 'package:go_partner/main.dart' as app;

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.directory);

  final Directory directory;

  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;
}

class _PlatformHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native startup preserves platform certificate validation', () async {
    final directory = await Directory.systemTemp.createTemp('go-partner-tls');
    final originalPathProvider = PathProviderPlatform.instance;
    final originalHttpOverrides = HttpOverrides.current;
    final platformOverrides = _PlatformHttpOverrides();

    PathProviderPlatform.instance = _TestPathProvider(directory);
    HttpOverrides.global = platformOverrides;
    try {
      await app.initLocalServices();

      // Startup must leave the platform trust policy in place. Replacing it
      // with an override that accepts every certificate makes passwords and
      // session tokens vulnerable even when the request URL uses HTTPS.
      expect(HttpOverrides.current, same(platformOverrides));
    } finally {
      HttpOverrides.global = originalHttpOverrides;
      PathProviderPlatform.instance = originalPathProvider;
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('uploads preserve known MIME types and use a valid fallback', () {
    final api = ApiHelper.instance;

    expect(api.appMediaType('portrait.jpg').toString(), 'image/jpeg');
    expect(api.appMediaType('product.png').toString(), 'image/png');
    expect(
      api.appMediaType('upload-without-extension').toString(),
      'application/octet-stream',
    );
    expect(
      api.appMediaType('upload.unrecognized_extension').toString(),
      'application/octet-stream',
    );
  });
}

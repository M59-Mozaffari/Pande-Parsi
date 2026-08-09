import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  final supabase = Supabase.instance.client;

  StreamSubscription? _subscription;

  /// 🔥 متد اصلی که از main صدا زده میشه
  Future<void> init() async {
    // ثبت دستگاه در پس‌زمینه
    Future.microtask(() async {
      try {
        await _tryRegister();
      } catch (e, s) {
        debugPrint('❌ Device register error: $e');
        debugPrint('$s');
      }
    });

    // گوش دادن به اتصال اینترنت
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        debugPrint('🌐 Internet connected → retry register');

        Future.microtask(() async {
          try {
            await _tryRegister();
          } catch (e, s) {
            debugPrint('❌ Retry register error: $e');
            debugPrint('$s');
          }
        });
      }
    });
  }

  /// 🔥 تلاش برای ثبت
  Future<void> _tryRegister() async {
    final prefs = await SharedPreferences.getInstance();

    final isRegistered = prefs.getBool('device_registered') ?? false;
    if (isRegistered) {
      debugPrint('⛔ Device already registered');
      return;
    }

    /// 🔥 چک اینترنت واقعی
    if (!await _hasInternet()) {
      debugPrint('❌ No internet → will retry later');
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = '';
      String deviceName = '';
      String os = '';

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        // ignore: dead_null_aware_expression
        deviceId = android.id ?? android.model ?? DateTime.now().toString();
        deviceName = '${android.brand} ${android.model}';
        os = 'Android ${android.version.release}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? DateTime.now().toString();
        deviceName = ios.utsname.machine;
        os = 'iOS ${ios.systemVersion}';
      } else {
        deviceId = DateTime.now().toString();
        deviceName = 'Unknown Device';
        os = 'Unknown';
      }

      debugPrint('📡 Registering device...');

      await supabase.from('devices').insert({
        'device_id': deviceId,
        'device_name': deviceName,
        'os': os,
        'app_version': packageInfo.version,
      });

      /// ✅ فقط در صورت موفقیت
      await prefs.setBool('device_registered', true);

      debugPrint('✅ Device registered successfully');

      /// 🔥 قطع listener چون دیگه لازم نیست
      await _subscription?.cancel();
    } catch (e) {
      debugPrint('❌ Register failed → retry later: $e');
    }
  }

  /// 🔥 چک واقعی اینترنت
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

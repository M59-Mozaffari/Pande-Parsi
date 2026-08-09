import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/databases/sync_manager.dart';
import 'package:pande_parsi/device_service.dart';
import 'package:pande_parsi/models/pand.dart';

import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pande_parsi/custom_route.dart';
import 'package:pande_parsi/screens/home_screen.dart';
import 'package:pande_parsi/screens/pands_screen.dart';
import 'package:pande_parsi/screens/onboarding_screen.dart';

import 'package:pande_parsi/notifications_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const fetchTask = "syncPandsTask";

/// =================================================
/// باز کردن پند از نوتیفیکیشن
/// =================================================

Future<void> openPandWhenReady(int pandId) async {
  const timeout = Duration(seconds: 1);

  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    final navigator = rootNavigatorKey.currentState;

    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);

      navigator.push(
        MaterialPageRoute(
          builder:
              (_) => PandsScreen(initialPandId: pandId, scrollToPand: true),
        ),
      );

      return;
    }

    await Future.delayed(const Duration(milliseconds: 50));
  }

  debugPrint("Navigator not ready.");
}

/// =================================================
/// Workmanager
/// =================================================

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchTask) {
      await backgroundSync();
    }

    return Future.value(true);
  });
}

/// =================================================
/// Background Sync
/// =================================================

Future<void> backgroundSync() async {
  try {
    final supabase = Supabase.instance.client;

    final localDb = LocalDtb.instance;

    /// دریافت کامل داده‌های سرور

    final data = await supabase.from('persionpand').select();

    final serverPands = data.map((e) => Pand.fromMap(e)).toList();

    /// دریافت داده‌های لوکال

    final localPands = await localDb.getAllPands();

    final serverIds = serverPands.map((e) => e.id).toSet();

    final localIds = localPands.map((e) => e.id).toSet();

    /// حذف پندهایی که از سرور حذف شده‌اند

    final idsToDelete = localIds.difference(serverIds);

    for (final id in idsToDelete) {
      if (id != null) {
        await localDb.deletePand(id);
      }
    }

    /// ساخت Map برای جلوگیری از N+1 Query

    final Map<int, Pand> localPandMap = {
      for (final pand in localPands)
        if (pand.id != null) pand.id!: pand,
    };

    /// Insert / Update

    for (final pand in serverPands) {
      final existing = localPandMap[pand.id];

      if (existing == null) {
        await localDb.insertPand(pand);
      } else {
        pand.isFavorite = existing.isFavorite;

        await localDb.updatePand(pand);
      }
    }

    await NotificationService().scheduleAdvanced();

    debugPrint("✅ Background sync completed");
  } catch (e) {
    debugPrint("❌ Background sync error: $e");
  }
}

/// =================================================
/// Main
/// =================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// Workmanager

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  Workmanager().registerPeriodicTask(
    "1",

    fetchTask,

    frequency: const Duration(minutes: 15),
  );

  /// First Launch

  final prefs = await SharedPreferences.getInstance();

  final firstLaunch = prefs.getBool('first_launch') ?? true;

  if (firstLaunch) {
    await prefs.setBool('first_launch', false);
  }

  try {
    await Supabase.initialize(
      url: "https://yjobtsnnydycmcesizso.supabase.co",

      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlqb2J0c25ueWR5Y21jZXNpenNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1MjMyODAsImV4cCI6MjA2MDA5OTI4MH0.kRf0NJQL-IJSZEDU9bCIbo6bT6c-LIXeL3KapcQXz_I",
    );

    SyncManager.instance.init();

    /// اجرای سریع UI

    runApp(MyApp(isFirstLaunch: firstLaunch));

    /// کارهای پس از نمایش UI

    Future.microtask(() async {
      try {
        DeviceService().init();

        final notificationService = NotificationService();

        await notificationService.init(
          onDidReceiveNotificationResponse: (response) async {
            final payload = response.payload;

            if (payload == null) return;

            if (payload == "rebuild") {
              await notificationService.scheduleAdvanced();

              return;
            }

            final pandId = int.tryParse(payload);

            if (pandId != null) {
              await openPandWhenReady(pandId);
            }
          },
        );

        await notificationService.ensureAdvanced();

        /// بررسی باز شدن از نوتیفیکیشن

        final initialPayload = notificationService.initialPayload;

        if (initialPayload != null) {
          final pandId = int.tryParse(initialPayload);

          if (pandId != null) {
            await openPandWhenReady(pandId);
          }
        }
      } catch (e) {
        debugPrint("Post startup error: $e");
      }
    });
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,

        home: Scaffold(
          body: Center(
            child: Text(
              "خطا در راه‌اندازی برنامه:\n$e",

              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// =================================================
/// App
/// =================================================

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,

      debugShowCheckedModeBanner: false,

      title: 'Pand parsi',

      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),

            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),

      home: isFirstLaunch ? const OnBoardingScreen() : HomeScreen(),
    );
  }
}

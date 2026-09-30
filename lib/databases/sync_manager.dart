import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_dtb.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();

  SyncManager._init();

  final SupabaseDtb _supabaseDtb = SupabaseDtb();

  StreamSubscription? _connectivitySub;
  StreamSubscription? _supabaseStreamSub;

  bool _isOnline = false;
  bool _isSyncing = false;

  final StreamController<void> _syncController = StreamController.broadcast();

  Stream<void> get onSync => _syncController.stream;

  // ================= INIT =================

  void init() {
    _listenConnectivity();
    _listenSupabaseStream();
  }

  // ================= INTERNET =================

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      final isNowOnline = result.first != ConnectivityResult.none;

      if (isNowOnline && !_isOnline) {
        _isOnline = true;

        /// 🔥 سینک کامل
        await _sync();

        /// 🔥 اتصال مجدد به realtime
        _restartRealtime();
      } else if (!isNowOnline) {
        _isOnline = false;
      }
    });
  }

  void _restartRealtime() {
    _supabaseStreamSub?.cancel();
    _listenSupabaseStream();
  }

  // ================= REALTIME =================

  void _listenSupabaseStream() {
    _supabaseStreamSub = _supabaseDtb.stream.listen((_) {
      _syncController.add(null); // notify UI
    });
  }

  // ================= SYNC =================

  Future<void> _sync() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      await _supabaseDtb.fullSync(); // 🔥 جایگزین شد
      _syncController.add(null);
    } catch (e) {
      print("Sync error: $e");
    }

    _isSyncing = false;
  }

  // ================= DISPOSE =================

  void dispose() {
    _connectivitySub?.cancel();
    _supabaseStreamSub?.cancel();
  }
}

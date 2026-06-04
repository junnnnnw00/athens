import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _online(List<ConnectivityResult> r) =>
    r.any((e) => e != ConnectivityResult.none);

/// Emits `true` when the device has a network interface, `false` when fully
/// offline. Reflects interface state (not true internet reachability), which is
/// enough to drive the offline indicator. Overridden in tests.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final conn = Connectivity();
  try {
    yield _online(await conn.checkConnectivity());
  } catch (_) {
    yield true; // assume online if the platform can't tell us
  }
  yield* conn.onConnectivityChanged.map(_online);
});

/// `true` only when we positively know the device is offline. Unknown/loading
/// stays `false` so we never flash a false offline warning.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull == false;
});

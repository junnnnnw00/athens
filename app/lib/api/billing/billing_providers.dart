import 'package:athens/api/platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_service.dart';
import 'noop_billing_service.dart';
import 'play_billing_service.dart';

/// `true` when built with `--dart-define=STORE_BUILD=true`.
///
/// GitHub / sideload builds leave this `false` so billing code never runs.
const bool kStoreBuild = bool.fromEnvironment('STORE_BUILD');

/// The active [BillingService] for this build variant.
///
/// - [kStoreBuild] + Android → [PlayBillingService]
/// - Everything else       → [NoopBillingService]
final billingServiceProvider = Provider<BillingService>((ref) {
  if (kStoreBuild && AppPlatform.isAndroid) {
    final service = PlayBillingService();
    ref.onDispose(service.dispose);
    return service;
  }
  return const NoopBillingService();
});

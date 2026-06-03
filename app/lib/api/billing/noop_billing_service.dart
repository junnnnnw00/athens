import 'billing_service.dart';

/// No-op billing service used in GitHub / sideload builds.
///
/// When [STORE_BUILD] dart-define is absent (the default), this implementation
/// is injected so that billing code is never executed on non-Play-Store builds.
class NoopBillingService implements BillingService {
  const NoopBillingService();

  @override
  bool get isSupported => false;

  @override
  Future<PurchaseResult> purchasePremium() async => PurchaseResult.notSupported;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  void dispose() {}
}

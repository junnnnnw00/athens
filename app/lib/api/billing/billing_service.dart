/// Billing service abstraction.
///
/// Two concrete implementations exist:
///   - [NoopBillingService] — used in GitHub / sideload builds (STORE_BUILD=false)
///   - [PlayBillingService]  — used in Play Store builds (STORE_BUILD=true)
///
/// The active implementation is selected at build time via the
/// `STORE_BUILD` dart-define flag (see [billingServiceProvider]).
library;

/// Product ID registered in Google Play Console.
const kPremiumProductId = 'athens_premium';

/// Result of a purchase attempt.
enum PurchaseResult {
  /// Purchase completed and verified server-side.
  success,

  /// User cancelled the purchase flow.
  cancelled,

  /// Purchase failed (network, billing error, etc.).
  error,

  /// This build does not support in-app purchases.
  notSupported,
}

abstract class BillingService {
  /// Whether this build supports in-app purchases at all.
  bool get isSupported;

  /// Initiates the $4.99 premium purchase flow.
  ///
  /// Returns a [PurchaseResult] indicating the outcome.
  Future<PurchaseResult> purchasePremium();

  /// Restores a previously completed purchase (for device restores / reinstalls).
  ///
  /// Returns `true` if an existing purchase was found and re-granted.
  Future<bool> restorePurchases();

  /// Disposes any open streams / listeners.
  void dispose();
}

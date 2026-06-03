import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_service.dart';

/// Google Play Billing implementation.
///
/// Active only in Play Store builds (--dart-define=STORE_BUILD=true).
///
/// Purchase flow:
///   1. Load product details from Google Play.
///   2. Initiate purchase — Play UI is presented to the user.
///   3. Listen to [InAppPurchase.instance.purchaseStream] for the result.
///   4. On success: call Supabase edge function to verify the token server-side
///      and flip `profiles.is_premium = true`.
///   5. Complete the purchase so Google marks it as acknowledged.
class PlayBillingService implements BillingService {
  PlayBillingService() {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription.cancel(),
      onError: (Object e) => debugPrint('[Billing] stream error: $e'),
    );
  }

  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  /// Completer that resolves when the pending purchase flow finishes.
  Completer<PurchaseResult>? _pendingCompleter;

  // ── BillingService ──────────────────────────────────────────────────────

  @override
  bool get isSupported => true;

  @override
  Future<PurchaseResult> purchasePremium() async {
    // Guard against concurrent purchase attempts.
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      return PurchaseResult.error;
    }

    // Load product details.
    final response = await InAppPurchase.instance
        .queryProductDetails({kPremiumProductId});

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      debugPrint('[Billing] Product not found: ${response.notFoundIDs}');
      return PurchaseResult.error;
    }

    final product = response.productDetails.first;

    // Create a new completer for this purchase attempt.
    _pendingCompleter = Completer<PurchaseResult>();

    final purchaseParam = PurchaseParam(productDetails: product);
    // buyNonConsumable = one-time purchase (not consumable like gems/coins).
    final started =
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

    if (!started) {
      _pendingCompleter!.complete(PurchaseResult.error);
      _pendingCompleter = null;
      return PurchaseResult.error;
    }

    // Wait for the purchase stream to resolve.
    return _pendingCompleter!.future;
  }

  @override
  Future<bool> restorePurchases() async {
    _pendingCompleter = Completer<PurchaseResult>();
    await InAppPurchase.instance.restorePurchases();
    final result = await _pendingCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => PurchaseResult.error,
    );
    _pendingCompleter = null;
    return result == PurchaseResult.success;
  }

  @override
  void dispose() {
    _subscription.cancel();
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Still processing — nothing to do yet.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyAndGrant(purchase);
          await InAppPurchase.instance.completePurchase(purchase);
          _resolve(verified ? PurchaseResult.success : PurchaseResult.error);

        case PurchaseStatus.error:
          debugPrint('[Billing] purchase error: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          _resolve(PurchaseResult.error);

        case PurchaseStatus.canceled:
          _resolve(PurchaseResult.cancelled);
      }
    }
  }

  /// Calls the Supabase edge function to verify the Google Play purchase token
  /// server-side and set `is_premium = true` in the database.
  Future<bool> _verifyAndGrant(PurchaseDetails purchase) async {
    try {
      final client = Supabase.instance.client;

      // The purchase token is in the verificationData for Android.
      final token = purchase.verificationData.serverVerificationData;
      final productId = purchase.productID;

      final result = await client.functions.invoke(
        'verify-play-purchase',
        body: {
          'purchaseToken': token,
          'productId': productId,
        },
      );

      if (result.status == 200) {
        debugPrint('[Billing] Premium granted via Play purchase.');
        return true;
      }
      debugPrint('[Billing] verify-play-purchase returned ${result.status}');
      return false;
    } catch (e) {
      debugPrint('[Billing] _verifyAndGrant error: $e');
      return false;
    }
  }

  void _resolve(PurchaseResult result) {
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete(result);
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles AdMob ads and the one-time "Remove ads" purchase.
class AdsProvider extends ChangeNotifier {
  /// Play Console in-app product ID (type: one-time / non-consumable).
  static const String removeAdsProductId = 'remove_ads';

  // Real AdMob unit IDs are used in release builds; debug builds use test IDs.
  // Test IDs below are Google's official ones for Android.
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _realBannerId = 'ca-app-pub-9792550446464845/4938221541';
  static const String _realInterstitialId =
      'ca-app-pub-9792550446464845/3617721810';

  static String get bannerAdUnitId =>
      kDebugMode ? _testBannerId : _realBannerId;
  static String get _interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : _realInterstitialId;

  static const String _prefsKey = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  ProductDetails? _product;
  InterstitialAd? _interstitial;

  bool _adsRemoved = false;
  bool _purchasePending = false;
  String? _message;

  bool get adsRemoved => _adsRemoved;
  bool get purchasePending => _purchasePending;
  bool get canBuy => _product != null && !_adsRemoved;
  String get price => _product?.price ?? '';
  String? get message => _message;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) => _setMessage('Purchase failed. Try again.'),
    );

    if (!_adsRemoved) {
      await _gatherConsent();
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _loadInterstitial();
      }
    }

    if (await _iap.isAvailable()) {
      final response = await _iap.queryProductDetails({removeAdsProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
      notifyListeners();
      // Silently re-check ownership (e.g. after a reinstall).
      if (!_adsRemoved) {
        await _iap.restorePurchases();
      }
    }
  }

  /// Shows the Google UMP consent form when required (EU/UK users).
  /// Needs a consent message created in AdMob > Privacy & messaging.
  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        });
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  Future<void> buyRemoveAds() async {
    final product = _product;
    if (product == null) return;
    _message = null;
    _purchasePending = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      _purchasePending = false;
      _setMessage('Could not start the purchase.');
    }
  }

  Future<void> restore() async {
    _message = null;
    _purchasePending = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // If nothing is restored the stream stays silent, so reset after a delay.
      Future.delayed(const Duration(seconds: 5), () {
        if (_purchasePending && !_adsRemoved) {
          _purchasePending = false;
          _setMessage('No previous purchase found.');
        }
      });
    } catch (_) {
      _purchasePending = false;
      _setMessage('Could not restore purchases.');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != removeAdsProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setAdsRemoved();
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _setMessage('Purchase failed. Try again.');
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          notifyListeners();
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _setAdsRemoved() async {
    _adsRemoved = true;
    _purchasePending = false;
    _message = null;
    _interstitial?.dispose();
    _interstitial = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    notifyListeners();
  }

  void _setMessage(String text) {
    _message = text;
    notifyListeners();
  }

  void _loadInterstitial() {
    if (_adsRemoved) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Shows an interstitial if one is ready, then always calls [onDone].
  void showInterstitial(VoidCallback onDone) {
    final ad = _interstitial;
    if (_adsRemoved || ad == null) {
      onDone();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
        onDone();
      },
    );
    ad.show();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _interstitial?.dispose();
    super.dispose();
  }
}

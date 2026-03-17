import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Ad Unit IDs
  static String get appId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532~3105979096';
    } else {
      return 'ca-app-pub-3265595931244532~3006982142';
    }
  }

  static String get homeBannerAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532/3578963258';
    } else {
      return 'ca-app-pub-3265595931244532/4820415823';
    }
  }

  static String get folderViewBannerAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532/7971727733';
    } else {
      return 'ca-app-pub-3265595931244532/8568089149';
    }
  }

  static String get fileViewBannerAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532/2179910238';
    } else {
      return 'ca-app-pub-3265595931244532/1418568307';
    }
  }

  static String get importFileInterstitialAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532/9915364790';
    } else {
      return 'ca-app-pub-3265595931244532/6061345304';
    }
  }

  static String get importBlindKeyInterstitialAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3265595931244532/3430789444';
    } else {
      return 'ca-app-pub-3265595931244532/6136542513';
    }
  }

  // Interstitial ad instances
  InterstitialAd? _importFileInterstitialAd;
  InterstitialAd? _importBlindKeyInterstitialAd;

  bool _isImportFileAdReady = false;
  bool _isImportBlindKeyAdReady = false;

  // Load import file interstitial ad
  void loadImportFileInterstitialAd() {
    InterstitialAd.load(
      adUnitId: importFileInterstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _importFileInterstitialAd = ad;
          _isImportFileAdReady = true;
          _importFileInterstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _importFileInterstitialAd = null;
                  _isImportFileAdReady = false;
                  // Preload next ad
                  loadImportFileInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _importFileInterstitialAd = null;
                  _isImportFileAdReady = false;
                  loadImportFileInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isImportFileAdReady = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), () {
            loadImportFileInterstitialAd();
          });
        },
      ),
    );
  }

  // Load import blind key interstitial ad
  void loadImportBlindKeyInterstitialAd() {
    InterstitialAd.load(
      adUnitId: importBlindKeyInterstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _importBlindKeyInterstitialAd = ad;
          _isImportBlindKeyAdReady = true;
          _importBlindKeyInterstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _importBlindKeyInterstitialAd = null;
                  _isImportBlindKeyAdReady = false;
                  // Preload next ad
                  loadImportBlindKeyInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _importBlindKeyInterstitialAd = null;
                  _isImportBlindKeyAdReady = false;
                  loadImportBlindKeyInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isImportBlindKeyAdReady = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), () {
            loadImportBlindKeyInterstitialAd();
          });
        },
      ),
    );
  }

  // Show import file interstitial ad
  Future<void> showImportFileInterstitialAd() async {
    if (_isImportFileAdReady && _importFileInterstitialAd != null) {
      final completer = Completer<void>();
      
      final previousCallback = _importFileInterstitialAd!.fullScreenContentCallback;
      _importFileInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          previousCallback?.onAdDismissedFullScreenContent?.call(ad);
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          previousCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          if (!completer.isCompleted) completer.complete();
        },
        onAdShowedFullScreenContent: previousCallback?.onAdShowedFullScreenContent,
        onAdImpression: previousCallback?.onAdImpression,
        onAdClicked: previousCallback?.onAdClicked,
      );

      await _importFileInterstitialAd!.show();
      return completer.future;
    } else {
      // If ad not ready, try to load and show later
      loadImportFileInterstitialAd();
      return; // Return immediately if no ad
    }
  }

  // Show import blind key interstitial ad
  Future<void> showImportBlindKeyInterstitialAd() async {
    if (_isImportBlindKeyAdReady && _importBlindKeyInterstitialAd != null) {
      final completer = Completer<void>();

      final previousCallback = _importBlindKeyInterstitialAd!.fullScreenContentCallback;
      _importBlindKeyInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          previousCallback?.onAdDismissedFullScreenContent?.call(ad);
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          previousCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          if (!completer.isCompleted) completer.complete();
        },
        onAdShowedFullScreenContent: previousCallback?.onAdShowedFullScreenContent,
        onAdImpression: previousCallback?.onAdImpression,
        onAdClicked: previousCallback?.onAdClicked,
      );

      await _importBlindKeyInterstitialAd!.show();
      return completer.future;
    } else {
      // If ad not ready, try to load and show later
      loadImportBlindKeyInterstitialAd();
      return; // Return immediately if no ad
    }
  }

  // Initialize - preload ads
  void initialize() {
    loadImportFileInterstitialAd();
    loadImportBlindKeyInterstitialAd();
  }

  // Dispose
  void dispose() {
    _importFileInterstitialAd?.dispose();
    _importBlindKeyInterstitialAd?.dispose();
    _importFileInterstitialAd = null;
    _importBlindKeyInterstitialAd = null;
    _isImportFileAdReady = false;
    _isImportBlindKeyAdReady = false;
  }
}

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Ad Unit IDs
  static const String appId = 'ca-app-pub-9698718721404755~6165833882';
  static const String homeBannerAdId = 'ca-app-pub-9698718721404755/4358762340';
  static const String folderViewBannerAdId = 'ca-app-pub-9698718721404755/6114697140';
  static const String fileViewBannerAdId = 'ca-app-pub-9698718721404755/3936747059';
  static const String importFileInterstitialAdId = 'ca-app-pub-9698718721404755/1521486641';
  static const String importBlindKeyInterstitialAdId = 'ca-app-pub-9698718721404755/1485186998';

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
          _importFileInterstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
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
          _importBlindKeyInterstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
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
  void showImportFileInterstitialAd() {
    if (_isImportFileAdReady && _importFileInterstitialAd != null) {
      _importFileInterstitialAd!.show();
    } else {
      // If ad not ready, try to load and show later
      loadImportFileInterstitialAd();
    }
  }

  // Show import blind key interstitial ad
  void showImportBlindKeyInterstitialAd() {
    if (_isImportBlindKeyAdReady && _importBlindKeyInterstitialAd != null) {
      _importBlindKeyInterstitialAd!.show();
    } else {
      // If ad not ready, try to load and show later
      loadImportBlindKeyInterstitialAd();
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


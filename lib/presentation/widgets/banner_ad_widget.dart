import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;
  final ValueChanged<bool>? onAdLoadedChanged;

  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
    this.onAdLoadedChanged,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
          widget.onAdLoadedChanged?.call(true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          widget.onAdLoadedChanged?.call(false);
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _loadAd();
          });
        },
        onAdOpened: (_) {},
        onAdClosed: (_) {},
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}


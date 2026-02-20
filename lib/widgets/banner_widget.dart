import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/banner.dart' as finlife;
import 'package:finlife/providers/banner_provider.dart';

class BannerWidget extends ConsumerWidget {
  final finlife.BannerType? bannerType;
  final int? maxBanners;
  final double height;
  final EdgeInsets margin;

  const BannerWidget({
    Key? key,
    this.bannerType,
    this.maxBanners,
    this.height = 150,
    this.margin = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerNotifier = ref.watch(bannerProvider.notifier);
    final banners = bannerType != null
        ? bannerNotifier.getBannersByType(bannerType!)
        : bannerNotifier.getActiveBanners();

    final displayBanners = maxBanners != null
        ? banners.take(maxBanners!).toList()
        : banners;

    if (displayBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      margin: margin,
      child: displayBanners.length == 1
          ? _buildSingleBanner(context, displayBanners.first)
          : _buildBannerCarousel(context, displayBanners),
    );
  }

  Widget _buildSingleBanner(BuildContext context, finlife.Banner banner) {
    return GestureDetector(
      onTap: () {
        // Handle banner tap
        _handleBannerTap(context, banner);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          banner.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Fallback UI if image fails to load
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.title,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context, List<finlife.Banner> banners) {
    return PageView.builder(
      itemCount: banners.length,
      itemBuilder: (context, index) {
        return _buildSingleBanner(context, banners[index]);
      },
    );
  }

  void _handleBannerTap(BuildContext context, finlife.Banner banner) {
    // Handle banner tap action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нажат баннер: ${banner.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // In a real app, you would navigate to the target URL
    // Navigator.pushNamed(context, banner.targetUrl);
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/banner.dart';

class BannerNotifier extends StateNotifier<List<Banner>> {
  BannerNotifier() : super([]) {
    _loadBanners();
  }

  void _loadBanners() {
    // Mock data for demonstration
    // In a real app, this would come from an API or local database
    state = [
      Banner(
        id: '1',
        title: 'Специальное предложение',
        imageUrl: 'assets/images/banner_promo_1.png',
        targetUrl: '/special-offer',
        type: BannerType.promotional,
        isActive: true,
      ),
      Banner(
        id: '2',
        title: 'Финансовое образование',
        imageUrl: 'assets/images/banner_promo_1.png',
        targetUrl: '/financial-education',
        type: BannerType.educational,
        isActive: true,
      ),
      Banner(
        id: '3',
        title: 'Пригласите друзей',
        imageUrl: 'assets/images/banner_referral_1.png',
        targetUrl: '/invite-friends',
        type: BannerType.referral,
        isActive: true,
      ),
    ];
  }

  List<Banner> getActiveBanners() {
    return state.where((banner) => banner.isActive).toList();
  }

  List<Banner> getBannersByType(BannerType type) {
    return state
        .where((banner) => banner.isActive && banner.type == type)
        .toList();
  }
}

final bannerProvider =
    StateNotifierProvider<BannerNotifier, List<Banner>>((ref) {
  return BannerNotifier();
});
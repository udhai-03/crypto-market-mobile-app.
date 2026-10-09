import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/ambient_background.dart';
import 'package:crypto_market_mobile/core/widgets/glass_surface.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/viewmodels/watchlist_view_model.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: _GlassNavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
        ),
      ),
    );
  }
}

/// Floating frosted glass capsule with medium transparency and soft shadow.
class _GlassNavigationBar extends ConsumerWidget {
  const _GlassNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double _radius = 28;
  static const double _sideInset = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(_radius);
    final watchlistCount = ref.watch(
      watchlistViewModelProvider.select((state) => state.value?.length ?? 0),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _sideInset,
        0,
        _sideInset,
        bottomInset > 0 ? bottomInset : AppSpacing.medium,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x45000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: GlassSurface(
          color: AppColors.glassBar,
          borderRadius: radius,
          border: Border.all(color: const Color(0x2BFFFFFF)),
          blur: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x26FFFFFF),
                  Color(0x06FFFFFF),
                  Colors.transparent,
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                height: 64,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.candlestick_chart_outlined, size: 24),
                    selectedIcon: Icon(
                      Icons.candlestick_chart_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                    label: AppStrings.market,
                  ),
                  NavigationDestination(
                    icon: watchlistCount > 0
                        ? Badge(
                            label: Text(
                              '$watchlistCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF042F2E),
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.star_outline_rounded,
                              size: 24,
                            ),
                          )
                        : const Icon(Icons.star_outline_rounded, size: 24),
                    selectedIcon: watchlistCount > 0
                        ? Badge(
                            label: Text(
                              '$watchlistCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF042F2E),
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.star_rounded,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.star_rounded,
                            size: 24,
                            color: AppColors.primary,
                          ),
                    label: AppStrings.watchlist,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

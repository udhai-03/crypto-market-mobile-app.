import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/app/shell/app_shell.dart';
import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/views/coin_details_screen.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/views/coin_not_found_screen.dart';
import 'package:crypto_market_mobile/features/market/data/market_symbols.dart';
import 'package:crypto_market_mobile/features/market/presentation/views/market_screen.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/views/watchlist_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.marketPath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.marketPath,
                name: AppRoutes.marketName,
                builder: (context, state) => const MarketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.watchlistPath,
                name: AppRoutes.watchlistName,
                builder: (context, state) => const WatchlistScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.coinDetailsPath,
        name: AppRoutes.coinDetailsName,
        builder: (context, state) {
          final symbol = MarketSymbols.resolve(
            state.pathParameters[AppRoutes.coinSymbolParam],
          );
          return symbol == null
              ? const CoinNotFoundScreen()
              : CoinDetailsScreen(symbol: symbol);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

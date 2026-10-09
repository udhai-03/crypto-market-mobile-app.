import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/router/app_router.dart';
import 'package:crypto_market_mobile/app/theme/app_theme.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';

class CryptoMarketApp extends ConsumerWidget {
  const CryptoMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

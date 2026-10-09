import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/coin_identity.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/coin_avatar.dart';

/// Large brand avatar with the coin name and its quote asset.
class CoinIdentityHeader extends StatelessWidget {
  const CoinIdentityHeader({super.key, required this.symbol});

  final String symbol;

  static const double _avatarSize = 56;
  static const double _chipAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = CoinIdentity.forSymbol(symbol);
    final pair = TradingPair.fromSymbol(symbol);

    return Row(
      children: [
        CoinAvatar(symbol: symbol, size: _avatarSize),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                identity.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.xSmall,
                children: [
                  _Chip(
                    label: pair.base,
                    color: identity.color,
                    alpha: _chipAlpha,
                  ),
                  if (pair.quote.isNotEmpty)
                    _Chip(
                      icon: Icons.swap_horiz_rounded,
                      label: pair.quote,
                      color: theme.colorScheme.onSurfaceVariant,
                      alpha: _chipAlpha,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.alpha,
    this.icon,
  });

  final String label;
  final Color color;
  final double alpha;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xSmall),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

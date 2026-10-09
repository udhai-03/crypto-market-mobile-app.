import 'package:crypto_market_mobile/features/market/data/datasources/binance_remote_data_source.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_ticker_stream_service.dart';
import 'package:crypto_market_mobile/features/market/data/market_symbols.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';
import 'package:crypto_market_mobile/features/market/domain/repositories/market_repository.dart';

class BinanceMarketRepository implements MarketRepository {
  const BinanceMarketRepository(
    this._remoteDataSource,
    this._tickerStreamService, {
    this.symbols = MarketSymbols.tracked,
  });

  final BinanceRemoteDataSource _remoteDataSource;
  final BinanceTickerStreamService _tickerStreamService;
  final List<String> symbols;

  @override
  Future<List<MarketTicker>> getMarketTickers() async {
    final tickers = await _remoteDataSource.fetch24hTickers(symbols);
    return [for (final ticker in tickers) ticker.toDomain()];
  }

  @override
  Stream<MarketTickerUpdate> watchTickerUpdates() {
    return _tickerStreamService.tickerEvents.map((event) => event.toDomain());
  }

  @override
  Stream<LiveConnectionStatus> watchConnectionStatus() {
    return _tickerStreamService.statusChanges;
  }
}

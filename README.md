# Crypto Market

A Flutter app for researching a fixed set of Binance USDT trading pairs:
a market dashboard with live prices, a historical price chart per pair, and
a persistent watchlist.

## Features

- **Market dashboard**: 24h price, change and quote volume for 12 tracked
  Binance USDT pairs (`MarketSymbols.tracked`), with search, a
  gainers/losers filter and sorting.
- **Tracked-pairs overview**: pair count, gainers, losers, the simple
  (unweighted) average 24h change, and the pair with the highest 24h quote
  volume. These describe **only the tracked pairs**, not the global crypto
  market. The app shows no market cap, dominance or supply figures.
- **Live updates** over one shared Binance WebSocket, with a status pill
  (Live / Connecting / Reconnecting / Offline) and automatic reconnects.
- **Coin Details**: live price summary, 24h statistics (base and quote
  volume shown separately) and an interactive historical chart for
  1H / 4H / 24H / 7D / 30D.
- **Watchlist**: star pairs from the market list or Coin Details; saved on
  the device and restored on launch.
- Loading, empty, error and offline states throughout; dark Material 3 UI.

## Architecture

Feature-first folders, MVVM with Riverpod, and the repository pattern.

```
lib/
  app/            App widget, GoRouter config, bottom-nav shell, theme
  core/           Constants, errors, Dio/WebSocket plumbing, formatters,
                  shared widgets
  features/
    market/       data (Binance DTOs, REST data source, WebSocket service,
                  repository) · domain (models, repository interface) ·
                  presentation (view models, views, widgets) · providers
    coin_details/ Klines repository, chart models, Coin Details UI
    watchlist/    Storage, repository, view model, Watchlist UI
```

- **Views** (`presentation/views`, `widgets`) only render state and forward
  user intents. They never call Dio, sockets or storage.
- **View models** (`Notifier`/`AsyncNotifier`) own screen state and call
  repositories. Derived state, such as filtered lists, summary statistics
  and a single pair's ticker, comes from selector providers, so widgets
  rebuild only for the data they use.
- **Repositories** hide Binance and storage details behind interfaces
  (`MarketRepository`, `ChartRepository`, `WatchlistStorage`). DTOs are
  parsed and validated in the data layer and mapped to domain models.
- **Riverpod** provides dependency injection (providers are overridden
  with fakes in tests) and lifecycle management (auto-dispose, keep-alive
  timers, `onDispose` cleanup).

## Market data flow (REST + WebSocket)

1. `MarketViewModel` loads a REST snapshot of all tracked pairs:
   `GET https://api.binance.com/api/v3/ticker/24hr?symbols=[...]`.
2. It subscribes to `BinanceTickerStreamService`, which opens **one**
   combined-stream socket for all pairs:
   `wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/...`.
   No widget opens its own connection; Coin Details and the Watchlist read
   the same `MarketViewModel` state.
3. Each live event replaces that pair's 24h statistics.
4. Every ticker carries its statistics close time (REST `closeTime`, stream
   `C`). Updates received while a snapshot is loading are buffered, and when
   the snapshot arrives the newest value per pair wins. A slow refresh
   therefore cannot overwrite a newer live price, and out-of-order events
   are ignored.
5. Connection drops are retried with exponential backoff (1s doubling up to
   30s, reset after a valid message). The status becomes Offline after three
   consecutive failures while retries continue. Generation IDs make late
   callbacks from abandoned sockets harmless.
6. The socket closes when the app goes to the background and reopens on
   resume. Pull-to-refresh reloads the REST snapshot. If the socket fails,
   the last loaded prices stay on screen.

## Historical chart flow

- `GET /api/v3/klines?symbol=…&interval=…&limit=…` with one request per
  timeframe: 1H = 60×1m, 4H = 48×5m, 24H = 96×15m, 7D = 168×1h,
  30D = 180×4h.
- The Klines request lives in the shared `BinanceRemoteDataSource`
  (`features/market/data`); `BinanceChartRepository` maps the timeframe to an
  interval and limit.
- Candles are validated (malformed records skipped) and sorted by open
  time. Each symbol/timeframe pair is its own auto-disposed provider, kept
  alive for at least one minute after it is requested, so switching back to
  a recent timeframe doesn't refetch. After that it is dropped as soon as no
  screen shows it. A slow response for an old selection can never replace
  the current chart.
- The chart is a **historical snapshot** loaded when the timeframe is
  opened. It is labelled as not live, and Klines are not refetched on
  ticker updates. The live price summary above it is separate, so a chart
  error never hides the price.

## Watchlist persistence

- `shared_preferences` (`SharedPreferencesAsync`) behind the
  `WatchlistStorage` interface; stored as versioned JSON
  (`{"version":1,"symbols":[...]}`).
- Symbols are trimmed, upper-cased, validated and de-duplicated. Adding a
  saved pair or removing an absent one is a no-op.
- Changes are queued so rapid taps apply in order. The UI updates only
  after a successful write; a failed write leaves the star unchanged and
  shows an error.
- Unreadable or corrupt data shows an error with Retry and is never
  overwritten. Saved pairs that the app no longer tracks are shown as
  unavailable rather than erased.

## Setup and run

Prerequisites:

- Flutter stable with Dart ≥ 3.13.5 (`environment: sdk: ^3.13.5`);
  developed and validated with Flutter 3.47.6 / Dart 3.13.5.
- Android SDK (compile/target SDK 36 via Flutter defaults) and JDK 17, e.g.
  the JDK bundled with Android Studio.
- An Android device or emulator with internet access.

```sh
flutter pub get
flutter run
```

No API keys are needed. Only public Binance market-data endpoints are used.

## Tests and builds

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release   # signed with the debug key (template default)
```

APKs are written to `build/app/outputs/flutter-apk/app-debug.apk` and
`build/app/outputs/flutter-apk/app-release.apk`.

Tests never touch the network. Repositories, the WebSocket connection,
reconnect timers and storage are replaced with fakes
(`test/helpers/`), and Riverpod providers are overridden per test.

## Known limitations

- Only the 12 pairs in `MarketSymbols.tracked` are available; there is no
  pair discovery.
- Statistics are computed from those pairs only, and the average change is
  unweighted.
- Charts don't update while they're on screen. Reopening a timeframe more
  than a minute after it was loaded fetches fresh candles.
- Live updates received during a refresh that then fails are not kept; the
  next stream event for each pair (about one per second) restores them.
- Corrupt watchlist data can't be repaired in-app; Retry re-reads it but
  doesn't reset it.
- The release build uses the debug signing config; a real release needs
  its own keystore.
- Quote volumes are shown in USDT, not converted to USD.
- Only Android builds have been produced and checked; the iOS project is
  the unmodified Flutter template and has not been built or tested.

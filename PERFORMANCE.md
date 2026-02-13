# Performance

Performance targets and optimizations for Runic Quotes.

## Targets

| Metric | Target |
|--------|--------|
| App launch | < 1s |
| UI animations | 60 FPS |
| Widget timeline | < 100ms |
| Database query | < 10ms |
| Memory | < 50 MB |

## App Launch

- **Lazy seeding:** Database seeding runs asynchronously in a background `Task`, never blocks UI.
- **Deferred ViewModels:** ViewModels initialize with a placeholder `ModelContext`, replaced in `.task` modifier. Prevents blocking view creation.
- **Single container:** `ModelContainer` created once in app init, shared via environment.

## Runtime

- **Actor concurrency:** `QuoteProvider` actor ensures thread-safe data access without locks.
- **Minimal re-renders:** `@Published` only on UI-relevant state. Private computed properties for view composition.
- **Spring animations:** 0.1-0.3s duration with 0.7 damping. Respect `accessibilityReduceMotion`.

## Widgets

- **Deterministic selection:** Quote-of-the-day uses `daysSinceEpoch` hash -- no RNG in timeline provider.
- **Shared container:** Single `ModelContainer` via App Groups between app and widget.
- **Lightweight entries:** `QuoteData` struct (Codable) instead of full SwiftData models.

## Rendering

- **Native materials:** SwiftUI `.thinMaterial`, `.regularMaterial` -- hardware-accelerated blur.
- **Static gradients:** Computed once, reused across view updates.
- **`Equatable` state:** `QuoteUiState` conforms to `Equatable` to skip redundant diffs.

## Memory

- **SwiftData lifecycle:** Automatic object faulting for large datasets.
- **On-demand fonts:** System loads fonts lazily on first use.
- **No large assets:** Asset catalog compression, no unnecessary in-memory buffers.

## Database

- **Indexed queries:** `@Attribute(.unique)` on `Quote.id` for automatic indexing.
- **Predicated fetches:** `FetchDescriptor` with predicates -- never fetches all quotes.
- **Background contexts:** Widget operations use background `ModelContext`.

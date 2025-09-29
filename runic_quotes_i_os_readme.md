# Runic Quotes (iOS) – README / TODO / ROADMAP

## 1. Overview

**Runic Quotes** is an iOS 17+ SwiftUI application that displays inspirational and literary quotes rendered in ancient runic scripts:

- Elder Futhark
- Younger Futhark
- Tolkien’s Cirth (Angerthas, via Private Use Area font)

The app uses custom runic fonts and a modern Apple stack (SwiftUI, SwiftData, WidgetKit, structured concurrency) and provides Home Screen + Lock Screen widgets.

Primary goals:
- Read quotes in multiple runic scripts.
- Switch scripts and fonts at runtime.
- See quotes in widgets.
- Maintain clean architecture and great testability.
- Deliver a premium black/white liquid glass aesthetic.

---

## 2. Tech Stack (iOS)

**Platform & Language**
- iOS 17+
- Swift 5.9+
- SwiftUI
- Structured concurrency (async/await, actors)

**Data & Persistence**
- SwiftData (@Model, ModelContainer, @Query)
- Optional: UserDefaults / @AppStorage for lightweight settings

**UI & Widgets**
- SwiftUI for all UI
- WidgetKit for Home Screen + Lock Screen widgets

**Testing & Tooling**
- XCTest (unit + UI tests)
- GitHub Actions for CI (build + test + lint)
- SwiftLint
- SwiftFormat

**Fonts / Runic Rendering**
- Noto Sans Runic (Unicode Runic block)
- BabelStone Runic (Unicode Runic block, historically styled)
- Custom Cirth font (PUA-mapped for Tolkien's Cirth / Angerthas)

**Missing tech for runic text rendering**
- Custom fonts bundled in app + widget targets via `UIAppFonts`.
- SwiftUI `.font(.custom("FontName", size:))` usage for Text.
- Runic transliteration module mapping Latin text to runic Unicode (and PUA for Cirth).
- (Optional) CoreText/CGPath helpers if advanced glyph rendering is needed later.

**Design System (Liquid Glass / Glassmorphism)**
- **Grayscale Palette**: Full spectrum from black to white
  - Pure Black: `#000000`
  - Dark Grays: `#1A1A1A`, `#2D2D2D`, `#404040`
  - Mid Grays: `#666666`, `#808080`, `#999999`
  - Light Grays: `#B3B3B3`, `#CCCCCC`, `#E6E6E6`
  - Pure White: `#FFFFFF`
- **Gradients**: Smooth transitions for depth
  - Radial gradients for glass highlights
  - Linear gradients for backgrounds and cards
  - Subtle noise overlay for texture
- **Transparency & Opacity Levels**: 100%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%, 10%, 5%
- **Blur Effects**: SwiftUI materials (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`)
- **Visual Hierarchy**: Achieved through layering, blur intensity, and opacity
- **Animations**: Smooth, fluid 60fps transitions with spring physics

---

## 3. Architecture

### 3.1 High-Level Architecture

- **Pattern:** MVVM + SwiftData
- **Layers:**
  - UI (SwiftUI Views)
  - Presentation (ViewModels)
  - Data (SwiftData models + repositories, transliteration utilities)

### 3.2 Data Model

**Quote model (@Model)**
```swift
@Model
final class Quote {
    @Attribute(.unique) var id: UUID
    var textLatin: String
    var author: String

    // Optional: precomputed fields
    var runicElder: String?
    var runicYounger: String?
    var runicCirth: String?

    init(textLatin: String, author: String) {
        self.id = UUID()
        self.textLatin = textLatin
        self.author = author
    }
}
```

**UserPreferences**
- Stored either as a SwiftData model or via @AppStorage.
- Fields:
  - `selectedScript: RunicScript` (Elder/Younger/Cirth)
  - `selectedFont: RunicFont` (Noto/BabelStone/Cirth)
  - `widgetMode: WidgetMode` (Daily / Random)

**Enums**
```swift
enum RunicScript: String, Codable, CaseIterable {
    case elder
    case younger
    case cirth
}

enum RunicFont: String, Codable, CaseIterable {
    case noto
    case babelstone
    case cirth
}

enum WidgetMode: String, Codable {
    case daily
    case random
}
```

### 3.3 Repositories & Transliteration

**QuoteRepository protocol**
```swift
protocol QuoteRepository {
    func seedIfNeeded() async throws
    func quoteOfTheDay(for script: RunicScript) async throws -> Quote
    func randomQuote(for script: RunicScript) async throws -> Quote
}
```

Implementation uses SwiftData (via ModelContext) and a `RunicTransliterator` utility.

**RunicTransliterator**
- `func latinToElder(_ text: String) -> String`
- `func latinToYounger(_ text: String) -> String`
- `func latinToCirth(_ text: String) -> String` (maps to PUA codepoints)

Strategy:
- Map lowercase Latin letters (and digraphs where necessary) to rune code points.
- Option A: precompute runic strings and persist them in Quote.
- Option B: compute on demand in repository or ViewModel.

### 3.4 ViewModels (MVVM)

**QuoteViewModel** (ObservableObject / @MainActor)

Responsibilities:
- Expose `@Published` `QuoteUiState`:
  - `runicText: String`
  - `author: String`
  - `currentScript: RunicScript`
  - `currentFont: RunicFont`
  - `isLoading: Bool`
- Handle:
  - `onAppear()` – load quote of the day.
  - `onNextQuoteTapped()` – fetch a new random quote.
  - `onScriptChanged(_:)` – update preferences and recompute runic text.
  - `onFontChanged(_:)` – update preferences.

**SettingsViewModel**

Responsibilities:
- Expose `UserPreferences` as published state.
- APIs to update script/font/widget mode.

### 3.5 SwiftData & Concurrency

- App-level `ModelContainer` configured in `@main` app struct.
- Use `@Environment(\.modelContext)` in views that interact with SwiftData.
- Heavy operations (seeding DB, transliteration for many quotes) run in a background Task.
- ViewModels are annotated with `@MainActor` to ensure UI updates on main thread.

### 3.6 Actors (optional but recommended)

**QuoteProvider actor**
- Maintains logic for selecting quote of the day.
- Avoids race conditions if widgets + app both read/update.

```swift
actor QuoteProvider {
    let repository: QuoteRepository

    init(repository: QuoteRepository) {
        self.repository = repository
    }

    func quoteOfTheDay(for script: RunicScript) async throws -> Quote {
        try await repository.quoteOfTheDay(for: script)
    }

    func randomQuote(for script: RunicScript) async throws -> Quote {
        try await repository.randomQuote(for: script)
    }
}
```

---

## 4. Fonts & Runic Rendering

### 4.1 Fonts Used

- **Noto Sans Runic** – Unicode Runic block, clean UI style.
- **BabelStone Runic** – Unicode Runic block, historically styled and comprehensive.
- **Cirth font** – PUA-coded Angerthas/Tolkien’s Cirth.

### 4.2 Bundling Fonts

1. Add `.ttf`/`.otf` files to Xcode project (Resources group).
2. Ensure target membership for **app** and **widget** targets is enabled.
3. Add to `Info.plist` for both app & widget:
   - Key: `Fonts provided by application` (`UIAppFonts`)
   - Value: Array of strings:
     - `NotoSansRunic-Regular.ttf`
     - `BabelStoneRunic.ttf`
     - `CirthAngerthas.ttf`

If fonts do not appear in widget, check widget Info.plist has the same `UIAppFonts` entries.

### 4.3 Using Fonts in SwiftUI

**Font names**
- Use internal font names, e.g.:
  - "Noto Sans Runic"
  - "BabelStone Runic"
  - "Cirth Angerthas" (depends on font)

**Helper**
```swift
enum RunicFontConfiguration {
    static func fontName(for script: RunicScript, font: RunicFont) -> String {
        switch script {
        case .cirth:
            return "Cirth Angerthas"
        case .elder, .younger:
            switch font {
            case .noto: return "Noto Sans Runic"
            case .babelstone: return "BabelStone Runic"
            case .cirth: return "Cirth Angerthas" // fallback
            }
        }
    }
}
```

**In a view**
```swift
struct RunicQuoteText: View {
    let text: String
    let script: RunicScript
    let font: RunicFont

    var body: some View {
        Text(text)
            .font(
                .custom(
                    RunicFontConfiguration.fontName(for: script, font: font),
                    size: 28
                )
            )
            .multilineTextAlignment(.center)
            .padding()
    }
}
```

### 4.4 Transliteration

- For Elder/Younger Futhark:
  - Map Latin letters/sounds to rune code points (U+16A0–U+16FF).
- For Cirth:
  - Map Latin letters/digraphs to PUA code points (e.g. U+E080+), matching the font.

Approach:
- Keep transliteration tables in code (dictionary of char → rune).
- For multi-character digraphs (e.g. "th", "sh"), handle with simple scanning.

Example skeleton:
```swift
struct RunicTransliterator {
    static func elder(from text: String) -> String {
        // 1. lowercase
        // 2. map characters to runes
        return text.lowercased().map { char in
            elderMap[char] ?? char
        }.reduce("", +)
    }

    static func younger(from text: String) -> String { /* similar */ }

    static func cirth(from text: String) -> String { /* PUA mapping */ }
}
```

### 4.5 Performance Notes

- Fonts load once when first used; overhead is negligible.
- Transliteration is cheap; for long lists of quotes, precompute and store in SwiftData.
- SwiftUI text rendering with custom fonts is efficient for short to medium texts.
- In widgets, keep text length reasonable (especially Lock Screen).

---

## 5. WidgetKit Integration

### 5.1 Widget Targets

- **RunicQuotesWidget** (WidgetKit extension)
  - Shows a quote in runes on Home/Lock screen.

Ensure:
- Fonts added to widget target and widget Info.plist (`UIAppFonts`).
- Widget uses shared data (via App Group or read-only bundled data).

### 5.2 Data Sharing Strategy

Phase 1 (simple):
- Widget bundles the same seed quotes as the app, independently.
- Widget picks quotes using simple deterministic logic (e.g., hash of date).

Phase 2 (advanced):
- Use App Group and shared SwiftData store or UserDefaults for:
  - Current quote of the day
  - User preferences (script/font)

### 5.3 Timeline Provider

- `RunicQuoteEntry`:
  - `date: Date`
  - `runicText: String`
  - `author: String?`
  - `script: RunicScript`
  - `font: RunicFont`

- Timeline strategy:
  - Generate entries for next N days (e.g. 7).
  - Update daily at a fixed time.

### 5.4 Widget View

```swift
struct RunicQuoteWidgetEntryView: View {
    var entry: RunicQuoteEntry

    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .center) {
                Text(entry.runicText)
                    .font(
                        .custom(
                            RunicFontConfiguration.fontName(
                                for: entry.script,
                                font: entry.font
                            ),
                            size: 20
                        )
                    )
                    .multilineTextAlignment(.center)
                if let author = entry.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}
```

Lock Screen widgets may need shorter text or truncated versions.

---

## 6. Build & CI

### 6.1 Requirements

- Xcode 15+
- iOS 17 SDK

### 6.2 Build Targets

- `RunicQuotes` – main iOS app
- `RunicQuotesWidget` – WidgetKit extension

### 6.3 GitHub Actions CI (example tasks)

- `xcodebuild -scheme RunicQuotes -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Run SwiftLint
- Run SwiftFormat (check mode)

---

## 7. Usage & UX (Liquid Glass Design)

### 7.1 Main Screen (Glassmorphism)

**Visual Hierarchy:**
- Background: Dark gradient (`#000000` → `#1A1A1A` radial from center)
- Frosted glass card containing quote (`.ultraThinMaterial`)
  - Background: Gradient overlay (white 10% → transparent)
  - White runic text (100% opacity) centered
  - Author label below (70% opacity, light gray `#CCCCCC`)
  - Border: 1px gradient (white 30% → transparent)
  - Corner radius: 24px
  - Soft shadow: Black 40% opacity, 20px blur, 8px offset
  - Subtle inner glow: White 5% opacity

**UI Controls:**
- Glass script selector (custom segmented control)
  - Background: `.thinMaterial` with gradient overlay
  - Three segments: Elder / Younger / Cirth
  - Selected state: White gradient fill (100% → 80%)
  - Unselected: Transparent with gray border (`#666666`, 50% opacity)
  - Smooth sliding indicator animation
- Glass "Next Quote" button
  - Gradient background: Gray `#404040` → `#2D2D2D`
  - Border: White 20% opacity
  - Scale animation on press (0.95x with spring damping)
  - Haptic feedback (.medium impact)
- Settings icon (top right)
  - Glass circle button with gradient fill
  - Gray `#666666` 30% opacity

**Animations:**
- Quote transition: Cross-fade with subtle scale (1.0 → 0.98 → 1.0)
- Glass card entrance: Blur-in + fade + slide up
- Background gradient: Subtle breathing animation (slow radial shift)
- Smooth, fluid 60fps with spring physics

### 7.2 Settings Screen (Glass Cards)

**Layout:**
- Background: Dark gradient (`#000000` → `#2D2D2D` linear top to bottom)
- Each setting group in separate glass card with spacing:
  - **Script Preference** (Picker with glass segments)
  - **Font Preference** (Picker with preview, gradient backgrounds)
  - **Widget Behavior** (Toggle with gradient track)
  - **Glass Intensity** (Slider with gradient fill)
  - **About/Credits** (Text with varied gray shades)

**Glass Card Style:**
- Background: `.thinMaterial` with gradient overlay (white 8% → transparent)
- Border: 1px gradient (gray `#666666` 40% → transparent)
- Corner radius: 20px
- Padding: 16px
- Shadow: Black 30% opacity, 16px blur, 4px offset
- Separator lines: Gray `#404040` 50% opacity

**Interactive Elements:**
- Toggle track: Gray gradient `#2D2D2D` → `#404040`
- Toggle knob: White gradient with shadow
- Slider track: Gray `#404040` with gradient fill
- Slider thumb: White gradient with glow effect

### 7.3 Widgets (Glass on Home/Lock Screen)

**Home Screen Widget:**
- Background: Dark gradient (`#1A1A1A` → `#000000`)
- Frosted glass overlay (`.ultraThinMaterial`)
- Card with gradient border (white 20% → gray `#666666` 10%)
- Content:
  - White runic text (100% opacity) with subtle glow
  - Author in light gray `#CCCCCC` (70% opacity)
  - Gradient vignette around edges for depth
- Sizes:
  - Small: Single large rune with gradient background
  - Medium: Short quote (2-3 words) with gradient card
  - Large: Full quote with author, gradient separators

**Lock Screen Widget:**
- Adapts to iOS lock screen blur
- Circular: Single rune with radial gradient background
- Inline: Short text with subtle gray gradient
- Respects system tinting and wallpaper colors

**Visual Effects:**
- Subtle noise texture overlay (5% opacity)
- Gradient borders that shimmer slightly
- Shadow depth appropriate to widget size

**Interaction:**
- Tapping widget: Smooth transition with matched gradient animation
- Deep-links to quote with cross-fade
- Maintains glass aesthetic throughout navigation

---

## 8. TODO List

### Phase 1 – Project Setup & Foundation (Week 1)

#### 1.1 Xcode Project Initialization
- [ ] Create new Xcode project: "RunicQuotes"
  - iOS 17.0+ minimum deployment target
  - SwiftUI App lifecycle
  - Bundle identifier: `com.yourdomain.RunicQuotes`
  - Enable SwiftData, Swift 5.9+
  - **Acceptance**: Project builds successfully on iOS 17 simulator

- [ ] Setup project structure with folders:
  ```
  RunicQuotes/
  ├── App/
  │   └── RunicQuotesApp.swift
  ├── Models/
  │   ├── Quote.swift
  │   ├── UserPreferences.swift
  │   └── Enums/
  │       ├── RunicScript.swift
  │       ├── RunicFont.swift
  │       └── WidgetMode.swift
  ├── Data/
  │   ├── Repositories/
  │   │   ├── QuoteRepository.swift
  │   │   └── QuoteRepositoryImpl.swift
  │   ├── Transliteration/
  │   │   ├── RunicTransliterator.swift
  │   │   ├── ElderFutharkMap.swift
  │   │   ├── YoungerFutharkMap.swift
  │   │   └── CirthMap.swift
  │   └── Actors/
  │       └── QuoteProvider.swift
  ├── ViewModels/
  │   ├── QuoteViewModel.swift
  │   └── SettingsViewModel.swift
  ├── Views/
  │   ├── QuoteView.swift
  │   ├── SettingsView.swift
  │   ├── Components/
  │   │   ├── RunicQuoteText.swift
  │   │   ├── ScriptSelector.swift
  │   │   └── FontSelector.swift
  │   └── Helpers/
  │       └── RunicFontConfiguration.swift
  ├── Resources/
  │   ├── Fonts/
  │   │   ├── NotoSansRunic-Regular.ttf
  │   │   ├── BabelStoneRunic.ttf
  │   │   └── CirthAngerthas.ttf
  │   └── SeedData/
  │       └── quotes.json
  └── Utilities/
      └── Extensions/
  ```
  - **Acceptance**: Folder structure matches above, compiles without errors

#### 1.2 Dependencies & Configuration
- [ ] Add `.swiftlint.yml` configuration
  - Configure rules for line length (120), force unwrapping, etc.
  - **File**: `.swiftlint.yml` in project root

- [ ] Add `.swiftformat` configuration
  - Configure indent style, spacing, import order
  - **File**: `.swiftformat` in project root

- [ ] Configure `Info.plist` with required keys:
  - `CFBundleName`: "Runic Quotes"
  - `CFBundleDisplayName`: "Runic Quotes"
  - `UIAppFonts`: (fonts will be added in Phase 1.4)
  - **Acceptance**: App name displays correctly

#### 1.3 SwiftData Models
- [ ] Implement `Quote.swift` model
  - Properties: `id`, `textLatin`, `author`, `runicElder?`, `runicYounger?`, `runicCirth?`
  - Use `@Model` and `@Attribute(.unique)` for id
  - **File**: `RunicQuotes/Models/Quote.swift`
  - **Tests**: Unit test model initialization

- [ ] Implement enum definitions:
  - `RunicScript.swift` (elder, younger, cirth)
  - `RunicFont.swift` (noto, babelstone, cirth)
  - `WidgetMode.swift` (daily, random)
  - **Files**: `RunicQuotes/Models/Enums/*.swift`
  - **Acceptance**: All enums conform to `Codable`, `CaseIterable`

- [ ] Implement `UserPreferences.swift`
  - Option A: SwiftData @Model OR
  - Option B: Struct with @AppStorage wrappers
  - Properties: `selectedScript`, `selectedFont`, `widgetMode`
  - **File**: `RunicQuotes/Models/UserPreferences.swift`

- [ ] Configure `ModelContainer` in `RunicQuotesApp.swift`
  - Initialize with Quote model schema
  - Handle migration/versioning strategy
  - **Acceptance**: SwiftData container initializes without errors

#### 1.4 Font Integration
- [ ] Download and add font files:
  - Download Noto Sans Runic from Google Fonts
  - Download BabelStone Runic (or alternative free runic font)
  - Obtain/create Cirth PUA font (or use placeholder)
  - **Files**: Add to `RunicQuotes/Resources/Fonts/`

- [ ] Configure fonts in Xcode:
  - Add font files to project navigator
  - Verify target membership for RunicQuotes app target
  - Add to `Info.plist` → `UIAppFonts` array:
    - `NotoSansRunic-Regular.ttf`
    - `BabelStoneRunic.ttf`
    - `CirthAngerthas.ttf`
  - **Acceptance**: Fonts load in app (verify with Font.custom)

- [ ] Implement `RunicFontConfiguration.swift`
  - Static function: `fontName(for:font:) -> String`
  - Map script+font to internal font name
  - **File**: `RunicQuotes/Views/Helpers/RunicFontConfiguration.swift`
  - **Tests**: Unit test all combinations return valid font names

- [ ] Create font verification view (temporary, for testing)
  - Display sample text in each font
  - Delete after verification
  - **Acceptance**: All three fonts render correctly

#### 1.5 Runic Transliteration Engine
- [ ] Implement `RunicTransliterator.swift` base structure
  - Static functions: `elder(from:)`, `younger(from:)`, `cirth(from:)`
  - **File**: `RunicQuotes/Data/Transliteration/RunicTransliterator.swift`

- [ ] Create `ElderFutharkMap.swift`
  - Dictionary mapping Latin chars → Elder Futhark Unicode (U+16A0–U+16EA)
  - Handle: a-z, common digraphs (th, ng)
  - Reference: https://en.wikipedia.org/wiki/Elder_Futhark
  - **File**: `RunicQuotes/Data/Transliteration/ElderFutharkMap.swift`
  - **Tests**: Verify all 24 runes map correctly

- [ ] Create `YoungerFutharkMap.swift`
  - Dictionary mapping Latin → Younger Futhark Unicode (U+16A0–U+16EA subset)
  - Handle 16 runes
  - Reference: https://en.wikipedia.org/wiki/Younger_Futhark
  - **File**: `RunicQuotes/Data/Transliteration/YoungerFutharkMap.swift`
  - **Tests**: Verify all 16 runes map correctly

- [ ] Create `CirthMap.swift`
  - Dictionary mapping Latin → PUA codepoints for Cirth
  - Handle Sindarin/English phonemes
  - Reference: Cirth font documentation
  - **File**: `RunicQuotes/Data/Transliteration/CirthMap.swift`
  - **Tests**: Verify major phonemes map correctly

- [ ] Implement transliteration logic:
  - Lowercase input
  - Handle multi-character sequences (digraphs: th, ng, ch, sh)
  - Fallback to original character if no mapping
  - **Tests**: Unit tests with known phrases:
    - "Hello World" → runes
    - "The quick brown fox" → runes
    - Verify output is valid Unicode

#### 1.6 Seed Data
- [ ] Create `quotes.json` with initial quotes
  - At least 30 quotes (literary, inspirational, Norse proverbs)
  - JSON structure: `[{"text": "...", "author": "..."}]`
  - **File**: `RunicQuotes/Resources/SeedData/quotes.json`
  - **Acceptance**: Valid JSON, varied content

- [ ] Implement quote seeding logic in `QuoteRepositoryImpl`
  - Check if database is empty on app launch
  - Load quotes.json
  - Decode and insert into SwiftData
  - Precompute runic fields using RunicTransliterator
  - **Acceptance**: First launch populates database with quotes

---

### Phase 2 – Core App Implementation (Week 2)

#### 2.1 Repository Layer
- [ ] Define `QuoteRepository` protocol
  - `func seedIfNeeded() async throws`
  - `func quoteOfTheDay(for script: RunicScript) async throws -> Quote`
  - `func randomQuote(for script: RunicScript) async throws -> Quote`
  - `func allQuotes() async throws -> [Quote]`
  - **File**: `RunicQuotes/Data/Repositories/QuoteRepository.swift`

- [ ] Implement `QuoteRepositoryImpl`
  - Use `ModelContext` from SwiftData
  - Implement seeding logic (load JSON, transliterate, insert)
  - Quote of the day: deterministic based on current date (hash date → index)
  - Random quote: random index, different from last shown
  - **File**: `RunicQuotes/Data/Repositories/QuoteRepositoryImpl.swift`
  - **Tests**:
    - Test seeding inserts correct count
    - Test quote-of-day is deterministic for same date
    - Test random quote varies

- [ ] Implement `QuoteProvider` actor
  - Wraps QuoteRepository for thread-safe access
  - Methods: `quoteOfTheDay(for:)`, `randomQuote(for:)`
  - **File**: `RunicQuotes/Data/Actors/QuoteProvider.swift`
  - **Acceptance**: Actor prevents data races in concurrent access

#### 2.2 ViewModels
- [ ] Implement `QuoteViewModel` (@MainActor, ObservableObject)
  - `@Published var currentQuote: Quote?`
  - `@Published var runicText: String = ""`
  - `@Published var isLoading: Bool = false`
  - `@Published var currentScript: RunicScript`
  - `@Published var currentFont: RunicFont`
  - Methods:
    - `func loadQuoteOfTheDay()`
    - `func loadNextQuote()`
    - `func updateScript(_ script: RunicScript)`
    - `func updateFont(_ font: RunicFont)`
  - **File**: `RunicQuotes/ViewModels/QuoteViewModel.swift`
  - **Tests**: Unit test state updates, async loading

- [ ] Implement `SettingsViewModel` (@MainActor, ObservableObject)
  - `@Published var preferences: UserPreferences`
  - Methods:
    - `func updateScript(_ script: RunicScript)`
    - `func updateFont(_ font: RunicFont)`
    - `func updateWidgetMode(_ mode: WidgetMode)`
  - Persist changes via @AppStorage or SwiftData
  - **File**: `RunicQuotes/ViewModels/SettingsViewModel.swift`

#### 2.3 Liquid Glass UI Components
- [ ] Implement `GlassCard.swift` base component
  - Reusable frosted glass container
  - Properties: blur intensity, gradient overlay, border style, corner radius
  - Background: `.ultraThinMaterial` or `.thinMaterial`
  - Gradient overlay: White/gray with low opacity (configurable)
  - Border: 1px gradient (white → gray with opacity, default 30% → 10%)
  - Corner radius: 20-24px (configurable)
  - Soft shadow: Black with blur (30-40% opacity, 16-20px blur)
  - Optional inner glow: White 5% opacity
  - **File**: `RunicQuotes/Views/Components/GlassCard.swift`

- [ ] Implement `GlassButton.swift`
  - Button with glassmorphism effect
  - Background: Gray gradient (`#404040` → `#2D2D2D`)
  - Border: White gradient with opacity
  - Scale animation on press (0.95x with spring damping)
  - Haptic feedback (.medium impact)
  - States: normal, pressed (darker gradient), disabled (lower opacity)
  - Optional glow effect on press
  - **File**: `RunicQuotes/Views/Components/GlassButton.swift`

- [ ] Implement `RunicQuoteText.swift`
  - SwiftUI view displaying text in custom runic font
  - Parameters: `text`, `script`, `font`
  - Styling: white color, center-aligned, multiline
  - Inside GlassCard container
  - **File**: `RunicQuotes/Views/Components/RunicQuoteText.swift`

- [ ] Implement `GlassScriptSelector.swift`
  - Custom segmented control with glass effect
  - Three segments: Elder / Younger / Cirth
  - Selected: white fill, Unselected: transparent with border
  - Smooth animation between selections
  - Binding to selected script
  - **File**: `RunicQuotes/Views/Components/GlassScriptSelector.swift`

- [ ] Implement `GlassFontSelector.swift`
  - Picker with glass styling
  - Font preview in each row
  - Binding to selected font
  - **File**: `RunicQuotes/Views/Components/GlassFontSelector.swift`

#### 2.4 Main Views (Liquid Glass Design)
- [ ] Implement `QuoteView.swift` with glassmorphism
  - Background: Dark radial gradient (`#000000` → `#1A1A1A`)
  - GlassCard containing:
    - RunicQuoteText (white, centered, 100% opacity)
    - Author label (light gray `#CCCCCC`, 70% opacity)
    - Gradient overlay and border
  - GlassScriptSelector at bottom (gradient segments)
  - GlassButton for "Next Quote" with gradient background
  - Settings icon (glass circle button with gradient, top right)
  - Wire to QuoteViewModel
  - `.task { await viewModel.loadQuoteOfTheDay() }`
  - Smooth animations: cross-fade, scale, blur transitions
  - Subtle background gradient animation
  - **File**: `RunicQuotes/Views/QuoteView.swift`
  - **Acceptance**: Premium glass aesthetic with gradients, quote display works

- [ ] Implement `SettingsView.swift` with glass cards
  - Background: Linear gradient (`#000000` → `#2D2D2D` top to bottom)
  - Multiple GlassCards for sections (each with gradient overlays):
    - Script preference (GlassScriptSelector with gradients)
    - Font preference (GlassFontSelector with gradient backgrounds)
    - Widget mode (Toggle with gradient track)
    - Glass intensity (Slider with gradient fill)
    - About section (Text with varied gray shades)
  - Wire to SettingsViewModel
  - Smooth scroll with glass cards
  - Separator lines: Gray `#404040` 50% opacity
  - **File**: `RunicQuotes/Views/SettingsView.swift`

- [ ] Update `RunicQuotesApp.swift`
  - Configure ModelContainer
  - Inject environment objects (viewModels if needed)
  - Set QuoteView as root view
  - **Acceptance**: App launches, displays quote-of-day

#### 2.5 User Preferences Persistence
- [ ] Implement persistence strategy
  - Option A: @AppStorage for simple key-value
  - Option B: SwiftData UserPreferences model
  - Save: selectedScript, selectedFont, widgetMode
  - **Acceptance**: Preferences persist across app launches

- [ ] Wire preferences to ViewModels
  - QuoteViewModel reads preferences on init
  - SettingsViewModel writes preferences on change
  - **Tests**: Verify preferences save/load correctly

---

### Phase 3 – Widgets (Week 3)

#### 3.1 Widget Extension Setup
- [ ] Create WidgetKit extension target: "RunicQuotesWidget"
  - Add to project with Widget Extension template
  - Set minimum iOS 17
  - **Acceptance**: Extension builds successfully

- [ ] Configure widget Info.plist
  - Add `UIAppFonts` with same fonts as main app
  - Ensure fonts are added to widget target membership
  - **Acceptance**: Fonts load in widget (verify in preview)

- [ ] Setup App Group (optional, for shared data)
  - Create App Group ID: `group.com.yourdomain.RunicQuotes`
  - Enable in both app and widget targets
  - **File**: Update Signing & Capabilities
  - **Acceptance**: App Group appears in both targets

#### 3.2 Widget Data Models
- [ ] Create `RunicQuoteEntry` struct (TimelineEntry)
  - Properties: `date`, `runicText`, `author`, `script`, `font`
  - Conform to `TimelineEntry`
  - **File**: `RunicQuotesWidget/RunicQuoteEntry.swift`

- [ ] Implement data sharing strategy:
  - Phase 1: Widget bundles own copy of quotes.json
  - Phase 1: Widget uses deterministic quote-of-day (same logic as app)
  - Phase 2 (later): Use App Group + shared UserDefaults for preferences
  - **Acceptance**: Widget can independently fetch quote data

#### 3.3 Widget Timeline Provider
- [ ] Implement `RunicQuoteTimelineProvider`
  - `placeholder(in:)`: Return sample entry
  - `getSnapshot(in:completion:)`: Return current quote
  - `getTimeline(for:in:completion:)`: Generate entries for next 7 days
  - Use deterministic quote-of-day logic
  - Update at midnight each day
  - **File**: `RunicQuotesWidget/RunicQuoteTimelineProvider.swift`
  - **Tests**: Verify timeline generates correct dates

#### 3.4 Widget Views
- [ ] Implement `RunicQuoteWidgetEntryView`
  - Display runic text with custom font
  - Display author (if space allows)
  - Support multiple widget families:
    - `.systemSmall`: Short quote
    - `.systemMedium`: Full quote
    - `.systemLarge`: Quote + author + decorative elements
  - **File**: `RunicQuotesWidget/RunicQuoteWidgetEntryView.swift`
  - **Acceptance**: Widget displays correctly in all sizes

- [ ] Implement Lock Screen widget (circular/inline)
  - Use `.accessoryCircular` or `.accessoryInline` family
  - Display short runic phrase or single rune
  - **File**: `RunicQuotesWidget/LockScreenWidgetView.swift`

- [ ] Configure widget main struct
  - Define `RunicQuoteWidget` struct conforming to `Widget`
  - Configure supported families
  - Add configuration options (if needed)
  - **File**: `RunicQuotesWidget/RunicQuotesWidget.swift`

#### 3.5 Widget Interactivity
- [ ] Implement deep linking from widget to app
  - Add URL scheme or use `Link` in widget view
  - Open app to specific quote (optional)
  - **Acceptance**: Tapping widget opens app

- [ ] Test widget updates
  - Verify widget updates at midnight
  - Test timeline expiration and reload
  - Test in simulator and on device
  - **Acceptance**: Widget displays new quote daily

---

### Phase 4 – Testing & Quality (Week 4)

#### 4.1 Unit Tests
- [ ] Create test target: "RunicQuotesTests"
  - **File**: `RunicQuotesTests/` folder

- [ ] Unit tests for RunicTransliterator:
  - Test Elder Futhark mapping for all 24 runes
  - Test Younger Futhark mapping for all 16 runes
  - Test Cirth mapping for common phonemes
  - Test edge cases: empty string, numbers, special chars
  - **File**: `RunicQuotesTests/TransliteratorTests.swift`
  - **Acceptance**: 95%+ code coverage for transliteration

- [ ] Unit tests for QuoteRepository:
  - Test seeding inserts correct count
  - Test quote-of-day returns consistent quote for same date
  - Test random quote returns different quotes
  - Mock ModelContext for testing
  - **File**: `RunicQuotesTests/QuoteRepositoryTests.swift`

- [ ] Unit tests for ViewModels:
  - Test QuoteViewModel state changes
  - Test async loading behavior
  - Test script/font switching updates runic text
  - **File**: `RunicQuotesTests/ViewModelTests.swift`

- [ ] Unit tests for models:
  - Test Quote initialization
  - Test enum conformances
  - **File**: `RunicQuotesTests/ModelTests.swift`

#### 4.2 UI Tests
- [ ] Create UI test target: "RunicQuotesUITests"
  - **File**: `RunicQuotesUITests/` folder

- [ ] UI tests for QuoteView:
  - Test app launches and displays quote
  - Test "Next Quote" button loads new quote
  - Test script selector changes displayed text
  - Test navigation to Settings
  - **File**: `RunicQuotesUITests/QuoteViewUITests.swift`

- [ ] UI tests for SettingsView:
  - Test preference changes persist
  - Test all pickers are interactive
  - **File**: `RunicQuotesUITests/SettingsViewUITests.swift`

#### 4.3 Widget Tests
- [ ] Widget timeline tests:
  - Test timeline generates entries for next N days
  - Test placeholder entry is valid
  - Test snapshot entry is valid
  - **File**: `RunicQuotesTests/WidgetTimelineTests.swift`

#### 4.4 CI/CD Setup
- [ ] Create `.github/workflows/ci.yml`
  - Jobs:
    - Build app for iOS simulator
    - Run unit tests
    - Run UI tests
    - Run SwiftLint
    - Run SwiftFormat --lint
    - Generate code coverage report
  - Trigger: on push to main, on PR
  - **File**: `.github/workflows/ci.yml`
  - **Acceptance**: CI passes on sample commit

- [ ] Configure SwiftLint
  - Fix all violations (or disable irrelevant rules)
  - Integrate into Xcode build phase (optional)
  - **Acceptance**: `swiftlint` returns 0 warnings

- [ ] Configure SwiftFormat
  - Run `swiftformat .` to format all files
  - Add pre-commit hook (optional)
  - **Acceptance**: `swiftformat --lint .` returns 0 violations

---

### Phase 5 – Polish & Finalization (Week 5)

#### 5.1 Visual Design
- [ ] Design app icon with liquid glass aesthetic
  - Create icon in multiple sizes (1024x1024 base)
  - Dark gradient background (`#000000` → `#2D2D2D`)
  - White/light gray rune with frosted glass effect
  - Subtle radial gradient highlight
  - Glassmorphism: gradient borders, soft glow
  - **Tool**: Figma, Sketch, or SF Symbols app
  - **File**: Add to `Assets.xcassets/AppIcon`

- [ ] Create liquid glass launch screen
  - Dark gradient background (`#000000` → `#1A1A1A`)
  - Frosted glass card with gradient overlay
  - Single white rune with subtle glow and blur
  - Gradient border effect
  - Use `LaunchScreen.storyboard` or SwiftUI launch screen
  - **File**: `RunicQuotes/Resources/LaunchScreen.storyboard`

- [ ] Implement glassmorphism UI components
  - Create `GlassCard.swift` reusable component
    - Background: `.ultraThinMaterial` or `.thinMaterial`
    - Gradient overlay (white/gray with low opacity)
    - Border: 1px gradient (white → gray with opacity)
    - Shadow: Black with configurable opacity (30-40%)
    - Corner radius: 20-24px
    - Optional inner glow effect
  - Create `GlassButton.swift` component
    - Frosted background with gradient overlay
    - Gray gradient fill (`#404040` → `#2D2D2D`)
    - Scale animation on press (0.95x spring)
    - Haptic feedback (.medium impact)
    - States: normal, pressed, disabled (with opacity)
  - Create `GradientBackground.swift` helper
    - Radial and linear gradient support
    - Animated gradients (subtle breathing effect)
  - **Files**: `RunicQuotes/Views/Components/GlassCard.swift`, `GlassButton.swift`, `GradientBackground.swift`
  - **Acceptance**: All UI uses glassmorphism consistently

- [ ] Design grayscale liquid glass color palette
  - **Grayscale spectrum**:
    - Pure Black: `#000000`
    - Dark Grays: `#1A1A1A`, `#2D2D2D`, `#404040`
    - Mid Grays: `#666666`, `#808080`, `#999999`
    - Light Grays: `#B3B3B3`, `#CCCCCC`, `#E6E6E6`
    - Pure White: `#FFFFFF`
  - **Opacity levels**: 100%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%, 10%, 5%
  - **Gradients**:
    - Linear gradients for backgrounds
    - Radial gradients for highlights/glows
    - Angular gradients for borders
  - **Blur intensities**: ultraThin, thin, regular, thick
  - Add all colors and gradients to `Assets.xcassets`
  - Create `ColorPalette.swift` with semantic color definitions
  - **File**: `RunicQuotes/Design/ColorPalette.swift`
  - **Acceptance**: App achieves premium glassmorphism with rich grayscale depth

#### 5.2 Accessibility
- [ ] Implement Dynamic Type support
  - Use `.font(.custom(..., size: .body))` with dynamic sizing
  - Test with largest accessibility text size
  - **Acceptance**: Text scales correctly

- [ ] Add VoiceOver labels
  - Label all interactive elements
  - Provide hints for custom controls
  - **File**: Update all views with `.accessibilityLabel()`
  - **Acceptance**: VoiceOver reads all elements correctly

- [ ] Test with accessibility features:
  - VoiceOver
  - Increase Contrast
  - Reduce Motion
  - **Acceptance**: App is usable with all features enabled

#### 5.3 Localization Scaffolding
- [ ] Setup localization infrastructure
  - Create `Localizable.strings` for English
  - Extract hardcoded strings to LocalizedStringKey
  - **File**: `RunicQuotes/Resources/en.lproj/Localizable.strings`

- [ ] Prepare for future localizations:
  - Comment which strings need cultural adaptation
  - Consider script direction (RTL support later)
  - **Acceptance**: All UI strings use localized keys

#### 5.4 About & Credits
- [ ] Implement About screen in SettingsView
  - App version and build number (from Bundle)
  - Description of runic scripts
  - Font credits and licenses
  - Links to sources (Wikipedia, font authors)
  - **File**: Update `SettingsView.swift` with About section

- [ ] Add LICENSE and CREDITS files
  - Document font licenses
  - Document quote sources
  - **Files**: `LICENSE` (MIT), `CREDITS.md`

#### 5.5 Performance & Optimization
- [ ] Profile app with Instruments
  - Check SwiftData fetch performance
  - Check transliteration performance
  - Optimize if needed (e.g., cache transliterations)
  - **Acceptance**: App launch < 1s, quote switching < 100ms

- [ ] Optimize widget performance
  - Ensure timeline generation is fast
  - Minimize data fetching in widget
  - **Acceptance**: Widget updates without noticeable delay

#### 5.6 Final Testing
- [ ] Test on physical iOS device (iPhone & iPad)
  - Verify fonts render correctly
  - Test widgets on Home Screen and Lock Screen
  - Test in low-power mode
  - **Acceptance**: No crashes, smooth UX

- [ ] Beta testing (TestFlight, optional)
  - Upload build to App Store Connect
  - Invite testers (friends, colleagues)
  - Collect feedback
  - Fix critical bugs

- [ ] Final QA pass:
  - Test all user flows
  - Test all widget configurations
  - Verify no memory leaks (Instruments)
  - **Acceptance**: Ready for v1.0 release

---

### Phase 6 – Release & Post-Launch (Week 6+)

#### 6.1 App Store Preparation
- [ ] Prepare App Store listing:
  - Screenshots (iPhone, iPad, multiple sizes)
  - App description emphasizing runic scripts and widgets
  - Keywords: runes, quotes, Viking, Elder Futhark, widgets
  - Privacy policy (if collecting data)
  - **Tool**: App Store Connect

- [ ] Submit for App Store review
  - Ensure compliance with App Store guidelines
  - Respond to review feedback
  - **Acceptance**: App approved

- [ ] Launch v1.0
  - Release to App Store
  - Announce on social media, blog, etc.
  - Monitor crash reports and reviews

#### 6.2 Post-Launch Monitoring
- [ ] Setup crash reporting (optional)
  - Integrate Crashlytics or native crash reports
  - Monitor for crashes

- [ ] Monitor user reviews
  - Respond to feedback
  - Collect feature requests

- [ ] Plan v1.1 features based on feedback

---

### Phase 7 – Advanced Features (Post-1.0)

#### 7.1 Quote Sharing (v1.1)
- [ ] Implement ImageRenderer for quote export
  - Render quote as image with runic text + author
  - Add parchment or stone background
  - **File**: `RunicQuotes/Utilities/QuoteImageRenderer.swift`

- [ ] Add ShareLink button in QuoteView
  - Share image or text
  - Include hashtags (#RunicQuotes, #ElderFuthark)
  - **Acceptance**: User can share quote to social media

#### 7.2 User-Generated Quotes (v1.2)
- [ ] Implement Create/Edit/Delete UI for quotes
  - Add "+" button in QuoteView
  - Form to enter text and author
  - List view of user quotes
  - **Files**: `RunicQuotes/Views/QuoteEditorView.swift`, `QuoteListView.swift`

- [ ] Store user quotes in SwiftData
  - Flag to distinguish user quotes from preloaded
  - **Acceptance**: User can add custom quotes

#### 7.3 Liquid Glass Refinements (v1.2)
- [ ] Enhance glassmorphism effects
  - Add subtle parallax on scroll
  - Implement smooth blur transitions
  - Add micro-interactions (hover states, ripple effects)
  - **File**: `RunicQuotes/Views/Components/AnimatedGlass.swift`

- [ ] Add glass intensity preference
  - User can adjust blur strength (subtle/medium/strong)
  - Persist preference
  - **Acceptance**: Users can customize glass effect intensity

---

### Testing Acceptance Criteria Summary

**Phase 1 Complete When:**
- ✅ Project builds without errors
- ✅ Fonts load and display correctly
- ✅ Transliteration produces valid runic Unicode
- ✅ Database seeds with quotes on first launch

**Phase 2 Complete When:**
- ✅ App displays quote of the day in runes
- ✅ User can switch scripts and fonts
- ✅ "Next Quote" button works
- ✅ Settings persist across launches

**Phase 3 Complete When:**
- ✅ Home Screen widget displays daily quote
- ✅ Lock Screen widget displays runic text
- ✅ Widget updates daily at midnight
- ✅ Tapping widget opens app

**Phase 4 Complete When:**
- ✅ All unit tests pass (≥80% coverage)
- ✅ All UI tests pass
- ✅ CI pipeline passes
- ✅ SwiftLint/SwiftFormat violations = 0

**Phase 5 Complete When:**
- ✅ App looks polished and professional
- ✅ App is accessible (VoiceOver, Dynamic Type)
- ✅ Performance metrics met (launch < 1s)
- ✅ Beta testing feedback addressed

**Phase 6 Complete When:**
- ✅ v1.0 live on App Store
- ✅ Monitoring systems active
- ✅ User reviews positive (≥4.0 rating)

---

### Estimated Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1 | Week 1 (5 days) | Foundation: Project, models, fonts, transliteration |
| Phase 2 | Week 2 (5 days) | Core app: UI, ViewModels, quote display |
| Phase 3 | Week 3 (5 days) | Widgets: Home + Lock Screen |
| Phase 4 | Week 4 (5 days) | Testing: Unit + UI + CI |
| Phase 5 | Week 5 (5 days) | Polish: Icon, accessibility, About |
| Phase 6 | Week 6+ (ongoing) | Release + post-launch monitoring |
| **Total** | **5–6 weeks** | **v1.0 MVP ready for App Store** |

Post-1.0 features (Phase 7) are developed in future sprints based on user feedback and priorities.

---

## 9. Roadmap

### Overview

The Runic Quotes app development is structured around iterative releases, each adding value while maintaining stability. The roadmap balances core functionality (v1.0), user engagement features (v1.1-1.2), and innovative extensions (v2.0+).

---

### v1.0 – Core Release (MVP)
**Target Release:** 6 weeks from project start
**Focus:** Essential functionality for App Store launch

#### Features
- **Quote Display Engine**
  - 30+ preloaded inspirational/literary quotes
  - Real-time transliteration to Elder Futhark, Younger Futhark, and Cirth
  - Quote of the Day (deterministic, same for all users on same date)
  - Random quote generation with no immediate repeats

- **Runic Script Support**
  - Three scripts: Elder Futhark, Younger Futhark, Tolkien's Cirth
  - Seamless script switching via segmented control
  - Unicode-compliant rendering (U+16A0–U+16FF for Futhark, PUA for Cirth)

- **Custom Font Integration**
  - Noto Sans Runic (modern, clean)
  - BabelStone Runic (historical, comprehensive)
  - Cirth Angerthas font (PUA-mapped)
  - Runtime font selection

- **iOS Widgets**
  - Home Screen widgets: Small, Medium, Large
  - Lock Screen widgets: Circular, Inline
  - Daily auto-refresh at midnight
  - Deep-link to app on tap

- **Settings & Preferences**
  - Persistent user preferences (script, font, widget mode)
  - About screen with runic script descriptions
  - Font and quote source credits

- **Testing & Quality**
  - 80%+ code coverage (unit + UI tests)
  - SwiftLint/SwiftFormat compliance
  - GitHub Actions CI pipeline
  - Accessibility: VoiceOver labels, Dynamic Type support

#### Success Metrics
- ✅ App Store approval on first submission
- ✅ Zero critical bugs in first week
- ✅ Widget displays correctly on iOS 17+ devices
- ✅ App launch time < 1 second
- ✅ 4.0+ star rating target

#### Technical Debt & Known Limitations
- Widget uses bundled data (no App Group sync in v1.0)
- Limited to 30 preloaded quotes
- No user-generated content
- Grayscale only (by design constraint - no colors beyond black/white/gray spectrum)

---

### v1.1 – Sharing & Customization
**Target Release:** 2-3 weeks after v1.0
**Focus:** Social features and user personalization

#### Features
- **Quote Sharing**
  - Export quote as stylized image (ImageRenderer)
  - Liquid glass card design with gradients and blur effects
  - Dark gradient background with frosted glass card
  - White runic text with subtle glow effect
  - Author in light gray with gradient separators
  - Include subtle app watermark (gray with low opacity)
  - ShareSheet integration (share to Instagram, Twitter, Messages)
  - Copy runic text to clipboard

- **Enhanced Font Selection**
  - In-app font preview for each script
  - Side-by-side font comparison view
  - Favorite font per script (persist separately)

- **Widget Improvements**
  - Widget mode configuration: Daily (fixed) vs Random (changes hourly)
  - App Group support for preference sync between app and widget
  - Widget refresh on app usage (update if user changes script/font)

- **UX Polish**
  - Haptic feedback on quote change
  - Smooth animations for script switching
  - Pull-to-refresh gesture for new quote
  - Loading skeletons during async operations

#### Success Metrics
- ✅ 30%+ of users share at least one quote
- ✅ Widget mode configuration used by 50%+ of users
- ✅ 4.2+ star rating
- ✅ Zero crashes related to new features

#### Dependencies
- v1.0 must be stable (< 1% crash rate)
- User feedback on desired customization options

---

### v1.2 – User Content & Themes
**Target Release:** 1-2 months after v1.1
**Focus:** User empowerment and visual customization

#### Features
- **User-Generated Quotes (CRUD)**
  - Add new quotes via in-app form (Latin text + author)
  - Edit/delete user-created quotes
  - SwiftData storage with `isUserCreated` flag
  - Filter view: All / Preloaded / My Quotes
  - Quote validation (min/max length, profanity filter optional)

- **Visual Customization**
  - Glass intensity adjustment (subtle/medium/strong blur)
  - Animation speed preference (reduced motion support)
  - Contrast adjustment for accessibility
  - Widget visual sync (match app glass intensity)

- **Localization**
  - Full English localization (baseline)
  - Translations for: Norwegian, Icelandic, Swedish (Nordic focus)
  - Localized quote packs (region-specific proverbs)
  - RTL support scaffolding (for future Arabic/Hebrew)

- **Enhanced Search & Filtering**
  - Search quotes by keyword or author
  - Filter by script, favorites, user-created
  - Sort by: Date added, Author, Random

#### Success Metrics
- ✅ 20%+ of users create at least one custom quote
- ✅ 40%+ of users change theme from default
- ✅ Successful launches in 3+ Nordic markets
- ✅ 4.5+ star rating

#### Technical Challenges
- User content moderation (if adding cloud sync later)
- Localized quote quality/curation
- Maintaining glassmorphism performance on older devices

---

### v1.3 – Cloud Sync & Collections
**Target Release:** 3-4 months after v1.2
**Focus:** Cross-device experience and organization

#### Features
- **iCloud Sync**
  - Sync user quotes across iPhone, iPad, Mac
  - CloudKit integration for preferences
  - Conflict resolution for edits
  - Maintain liquid glass design across all platforms

- **Quote Collections**
  - Organize quotes into custom collections (folders/tags)
  - Predefined collections: Favorites, Daily Rotation, Shared
  - Widget can pull from specific collection
  - Glass card UI for collection browsing

- **Advanced Widget Customization**
  - Configure widget to show specific collection
  - Manual widget refresh button
  - Widget intent configuration (iOS intents framework)
  - Glass effect intensity matches app settings

#### Success Metrics
- ✅ 50%+ of multi-device users enable sync
- ✅ Collections used by 30%+ of users
- ✅ Consistent glassmorphism across platforms

---

### Versioning Strategy

**Semantic Versioning:** `MAJOR.MINOR.PATCH`
- **MAJOR:** Breaking changes (e.g., v1 → v2, new architecture)
- **MINOR:** New features, backward-compatible (e.g., v1.1, v1.2)
- **PATCH:** Bug fixes, performance improvements (e.g., v1.0.1)

**Release Cadence:**
- v1.0: Initial stable release
- v1.x: Monthly minor updates (features)
- v1.x.y: Bi-weekly patch updates (bug fixes)
- v2.0: Annual major release (significant new features)

---

### Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Font rendering issues on older iOS | High | Extensive testing on iOS 17.0+, fallback fonts |
| Widget not updating | High | Comprehensive timeline testing, logging |
| App Store rejection | High | Pre-submission review checklist, compliance audit |
| Poor user adoption | Medium | Marketing campaign, App Store Optimization (ASO) |
| Transliteration inaccuracies | Medium | Peer review by runology experts, user feedback loop |
| Performance issues on older devices | Low | Profile on iPhone SE (oldest supported), optimize |
| Localization errors | Low | Native speaker review before release |

---

### Feature Prioritization Framework

**MoSCoW Method:**
- **Must Have (v1.0):** Core quote display, transliteration, widgets, liquid glass design with gradients
- **Should Have (v1.1-1.2):** Sharing with gradient effects, visual customization, user quotes
- **Could Have (v1.3):** iCloud sync, collections
- **Won't Have:** Keyboard extensions, AR/VR, learning mode, community features, color themes (grayscale only)

**User Impact vs. Effort Matrix:**
```
High Impact, Low Effort → v1.1 (Sharing, widget modes, glassmorphism)
High Impact, High Effort → v1.2-1.3 (User quotes, iCloud sync)
Low Impact, Low Effort → v1.2 (Glass intensity customization)
Low Impact, High Effort → Won't Have (Keyboard, AR, community features)
```

---

### Long-Term Vision (2-3 Years)

**Mission:** Create the most beautiful and functional iOS app for displaying quotes in runic scripts with a premium liquid glass aesthetic.

**Goals:**
1. **Design Excellence:** Set the standard for glassmorphism in iOS quote apps
2. **Reach:** 50K+ downloads, 4.5+ star rating
3. **User Engagement:** 10K+ user-created quotes in community
4. **Platform:** Expand to macOS, watchOS with consistent liquid glass design
5. **Scripts:** Maintain focus on Elder Futhark, Younger Futhark, and Cirth

**Sustainability:**
- One-time "Pro" unlock for premium features ($4.99)
- Free tier: 30 quotes, basic widgets, standard glass effects
- Pro tier: unlimited quotes, iCloud sync, collections, glass customization
- No ads, no subscription - just beautiful, distraction-free design

---

This roadmap is a living document and will be updated based on user feedback, technical feasibility, and market opportunities.

---

## 10. Conclusion

This document serves as the **canonical specification** for the iOS **Runic Quotes** app. It defines:
- Architecture (MVVM + SwiftData)
- Tech stack (SwiftUI, WidgetKit, iOS 17+)
- Font integration strategy (custom runic fonts)
- Comprehensive TODO list (7 phases, 100+ tasks)
- Product roadmap (v1.0 → v2.1+)

**Next Steps:**
1. Review and approve this document
2. Begin Phase 1: Project Setup & Foundation
3. Establish weekly sprint reviews
4. Track progress in GitHub Projects/Issues

For questions or suggestions, open an issue or contact the development team.

---

**Last Updated:** 2025-11-15
**Version:** 1.0 (Living Document)
**Maintainer:** Development Team


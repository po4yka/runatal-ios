# Runatal iOS -- Design Refactor

## Objective

Refactor the Runatal (RunicQuotes) iOS app to match the new Figma design system. This is a phased, incremental redesign -- not a rewrite. Preserve existing architecture (MVVM + Repository + Actor), SwiftData models, and business logic. Only change UI layer, theme tokens, navigation structure, and add new screens.

## Architecture Context

- **Stack**: SwiftUI, SwiftData, WidgetKit, Swift 6.1, iOS 17+, strict concurrency, zero deps
- **Pattern**: MVVM + Repository + Actor-based concurrency
- **Current state**: 2-tab app (Quote, Settings) with glass morphism components, 3 themes (Obsidian, Parchment, NordicDawn), onboarding flow

## Design System Reference

Full token spec: `.ralph/specs/design-system.md`

**Figma file**: `OQ9lz2369ZW8yobV6eLsGZ`

### Figma Pages (use `get_design_context` or `get_screenshot` MCP tools with these node IDs)

| Section            | Node ID      | URL |
|--------------------|--------------|-----|
| Design System      | `18:48374`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=18-48374&m=dev |
| Onboarding         | `17:31056`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-31056&m=dev |
| Core Screens       | `17:31680`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-31680&m=dev |
| Create & Edit      | `17:36754`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-36754&m=dev |
| Share              | `17:37399`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-37399&m=dev |
| Settings           | `17:39004`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-39004&m=dev |
| Quote Packs        | `17:40422`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-40422&m=dev |
| Archive            | `17:41207`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-41207&m=dev |
| Widgets            | `17:42133`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-42133&m=dev |
| States             | `17:43122`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-43122&m=dev |
| Dialogs & Overlays | `17:44106`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-44106&m=dev |
| Rune References    | `17:44924`   | https://www.figma.com/design/OQ9lz2369ZW8yobV6eLsGZ/Runatal?node-id=17-44924&m=dev |

### How to Use Figma MCP

To inspect any design page, call:
```
mcp__claude_ai_Figma__get_design_context(fileKey="OQ9lz2369ZW8yobV6eLsGZ", nodeId="<NODE_ID>", clientLanguages="swift", clientFrameworks="swiftui")
```
For visual reference:
```
mcp__claude_ai_Figma__get_screenshot(fileKey="OQ9lz2369ZW8yobV6eLsGZ", nodeId="<NODE_ID>", clientLanguages="swift", clientFrameworks="swiftui")
```

## Implementation Phases

### Phase 1: Design Token Foundation

**Goal**: Replace hardcoded colors with the new Scandinavian cold-slate design system.

1. **Refactor `AppThemePalette`** to use the new color tokens from the design system spec. The new palette supports proper dark/light mode via `@Environment(\.colorScheme)` instead of the current 3-theme approach (Obsidian/Parchment/NordicDawn). The Figma design uses a single cohesive dark+light system.
   - Add new tokens: `background`, `groupedBG`, `surface`, `surfaceElevated`, `accent`, `accentSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `runeText`, `success`, `warning`, `error`, `separator`
   - Wire dark/light variants via Color asset catalog or adaptive Color initializers

2. **Create `DesignTokens` enum** with spacing scale (`4, 8, 12, 16, 20, 24, 32, 40, 48, 64`) and corner radius tokens (`xs=6, sm=10, md=14, lg=18, xl=22, 2xl=26, 3xl=30, full=100`)

3. **Update `GlassCard` and `GlassButton`** to use new glass material tokens:
   - 3 intensity levels: Strong (blur 60px, sat 2.0), Medium (blur 40px, sat 1.8), Light (blur 24px, sat 1.5)
   - Glass BG, Border, Highlight tokens for dark/light

4. **Verify**: All existing views still compile and render correctly with new tokens. Run `xcodebuild -scheme RunicQuotes build`.

**Figma reference**: Design System page (node `18:48374`)

### Phase 2: Navigation & Tab Structure

**Goal**: Expand from 2-tab to 5-tab navigation matching Figma.

1. **Refactor `MainTabView`** from 2 tabs (Quote, Settings) to 5 tabs:
   - Home (quote display)
   - Collections (browse by collection)
   - Search
   - Saved (bookmarked/favorited quotes)
   - Settings

2. **Tab bar**: Liquid Glass pill style, 52px height per design spec
3. **Navigation bars**: Glass medium material, support both large-title and inline styles

4. **Create stub views** for new tabs: `CollectionsView`, `SearchView`, `SavedView` with appropriate empty states from the States Figma page (node `17:43122`)

**Figma reference**: Core Screens (node `17:31680`), States (node `17:43122`)

### Phase 3: Core Screens Redesign

**Goal**: Redesign existing screens to match Figma.

1. **Home / QuoteView**: Redesign quote display card, rune ornaments, action bar. Reference Core Screens Figma.
2. **Collections**: Grid/list of collection covers. Reference Core Screens Figma.
3. **Search**: Search bar with chip filters, results list. Reference Core Screens Figma.
4. **Saved/Favorites**: Filtered quote list with empty state. Reference States Figma.
5. **Settings**: Grouped glass sections with list rows, theme picker, script selector, notifications, about. Reference Settings Figma (node `17:39004`).

**Figma reference**: Core Screens (node `17:31680`), Settings (node `17:39004`)

### Phase 4: Onboarding Redesign

**Goal**: Update onboarding flow to match new design.

1. **5-step onboarding**: Splash -> Intro -> Atmosphere picker -> Notifications -> Ready
2. Each step uses new design tokens, glass cards, proper typography
3. Preserve existing `@AppStorage` completion logic

**Figma reference**: Onboarding (node `17:31056`)

### Phase 5: Create & Edit Flows

**Goal**: Add quote creation and editing screens.

1. **New Quote form**: text field, author, source, collection picker, rune preview
2. **Edit Quote form**: pre-filled fields, save/cancel
3. **Success confirmation**: "Quote Created" overlay with view/create-another actions
4. Requires `QuoteRepository` additions for create/update operations

**Figma reference**: Create & Edit (node `17:36754`)

### Phase 6: Share Feature

**Goal**: Add sharing capabilities.

1. **Share sheet**: Multiple share formats (text, image card, social)
2. **Share preview**: Styled quote card for sharing
3. **Share options**: Copy text, share as image, social platform cards

**Figma reference**: Share (node `17:37399`)

### Phase 7: Quote Packs & Archive

**Goal**: Add quote packs browsing and archive functionality.

1. **Quote Packs**: Browse/search packs, pack detail with preview quotes, pack install confirmation
2. **Archive**: Archived quotes list with filters, bulk actions, restore/delete

**Figma reference**: Quote Packs (node `17:40422`), Archive (node `17:41207`)

### Phase 8: Dialogs, Overlays & Polish

**Goal**: Implement dialog and overlay patterns.

1. **Action sheet**: Quote actions (share, edit, collection, copy, hide, delete)
2. **Confirmation dialogs**: Delete quote, clear archive
3. **Notification permission**: System prompt wrapper
4. **Paywall/upgrade**: "Explore More Quotes" prompt
5. **Notification settings**: Grouped list

**Figma reference**: Dialogs & Overlays (node `17:44106`)

### Phase 9: Rune Reference Screens

**Goal**: Add rune alphabet reference views.

1. **Elder Futhark grid**: Interactive rune grid with detail cards
2. **Younger Futhark grid**: Same pattern
3. **Cirth grid**: Same pattern
4. **Rune detail**: Name, transliteration, meaning, usage

**Figma reference**: Rune References (node `17:44924`)

### Phase 10: Widget Redesign

**Goal**: Update widget designs to match new system.

1. **Small/Medium/Large widget** layouts with new design tokens
2. **Widget configuration**: Script, style, collection options
3. **Lock screen widgets**: Inline and circular

**Figma reference**: Widgets (node `17:42133`)

## Conventions (from CLAUDE.md)

- `@MainActor final class` ViewModels with `@Published private(set) var state`
- `os.Logger` only -- no `print()`
- `// MARK: - Section Name` to organize types
- `AppThemePalette` for all colors -- never hardcode
- `GlassCard`, `GlassButton` for glass morphism components
- `static func preview()` on ViewModels, `#Preview` on Views
- File headers: standard Xcode template (filename, target, date)
- Enums: `String, Codable, CaseIterable, Identifiable, Sendable`
- SwiftUI + SwiftData, iOS 17+, strict concurrency, zero third-party deps
- Prefer `@Environment(\.colorScheme)` for dark/light adaptation

## Working Rules

1. **One phase at a time**. Complete and verify each phase before starting the next.
2. **Fetch Figma context** for each screen before implementing it. Use `get_design_context` MCP tool.
3. **Preserve existing behavior**. This is a redesign, not a rewrite. Keep business logic, models, and data layer intact.
4. **Build after each change**. Run `xcodebuild -scheme RunicQuotes build` to verify compilation.
5. **Commit after each phase**. Use conventional commits: `feat(design): phase N - description`.
6. **Create feature branch** before starting: `git checkout -b feat/design-refactor`.
7. **Read existing code before modifying**. Understand what exists before changing it.
8. **Follow project CLAUDE.md conventions** strictly.

## Completion

When all 10 phases are complete and the app builds successfully, write `LOOP_COMPLETE` to signal the Ralph loop is finished.

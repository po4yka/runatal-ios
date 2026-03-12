# Memories

## Patterns

### mem-1773319268-ed2e
> Widget configuration intent at RunicQuotesWidget/Intents/WidgetConfigurationIntent.swift. AppEnum types: ScriptOption, ModeOption, StyleOption bridging to RunicScript/WidgetMode/WidgetStyle. RunicQuoteConfigurationIntent with 4 @Parameter fields (script, mode, style, showRuneText). Widget uses AppIntentConfiguration instead of StaticConfiguration. QuoteTimelineProvider is AppIntentTimelineProvider with async API. Intent overrides per-widget; font/theme from UserPreferences. Commit c452bac.
<!-- tags: design-system, phase10, widget, appintent | created: 2026-03-12 -->

### mem-1773318781-79a7
> Widget views migrated to adaptive palette in Phase 10. WidgetViews.swift uses @Environment(\.colorScheme) + AppThemePalette.adaptive(for:) instead of entry.theme.palette. Uses runeText for rune display, textPrimary/textSecondary/textTertiary for content, separator for dividers. DesignTokens.Spacing/CornerRadius for layout. Medium widget has header row (rune text + Quote of the Day). Large widget has header + branding footer (glyph + Runic Quotes). RunicQuoteWidget.swift has WidgetBackgroundView with adaptive gradient. Commit 5ef395a.
<!-- tags: design-system, phase10, widget | created: 2026-03-12 -->

### mem-1773318321-a5f0
> RuneDetailView at RunicQuotes/Views/RuneDetailView.swift. Hero section (80x80 circle + glyph, name, meaning/sound). Info row: Aett (Elder only), Unicode code point, Position. About section with per-rune descriptions (24 Elder Futhark descriptions). RuneReferenceView wired via .navigationDestination(for: String.self). Rune Reference accessible from SettingsView NavigationLink. Commit 984d16f.
<!-- tags: design-system, phase9, rune-reference | created: 2026-03-12 -->

### mem-1773317927-5e93
> RuneReferenceView at RunicQuotes/Views/RuneReferenceView.swift. Segmented Picker for script selection, 4-column LazyVGrid with GlassCard cells (glyph, name, meaning). Searchable by name/meaning/sound/glyph. NavigationLink(value: rune.id) on each cell for detail wiring. Uses adaptive palette + DesignTokens. Commit 372ff07.
<!-- tags: design-system, phase9, rune-reference | created: 2026-03-12 -->

### mem-1773317706-47aa
> RuneInfo struct at RunicQuotes/Models/RuneInfo.swift. Static catalogs: elderFuthark (24), youngerFuthark (16), cirth (24). Each rune has id, glyph, name, meaning, sound, script. Helpers: runes(for:), subtitle(for:), sample. Commit 1c2f2fa.
<!-- tags: design-system, phase9, rune-reference | created: 2026-03-12 -->

### mem-1773317273-60d2
> NotificationCenterView at RunicQuotes/Views/NotificationCenterView.swift. NotificationItem struct with 4 sample types (Daily Quote Ready, Streak Reminder, New Pack Available, Weekly Summary). Unread dot indicator, mark-as-read on tap, Mark All Read toolbar button, empty state. Accessed via bell icon NavigationLink in QuoteView toolbar. Commit 2cedf49.
<!-- tags: design-system, phase8, notifications | created: 2026-03-12 -->

### mem-1773316919-aa6f
> CoachMarksView at RunicQuotes/Views/CoachMarksView.swift. CoachMarkStep enum with 3 steps (swipeQuotes, saveQuotes, exploreCollections). Full-screen dimmed overlay with glass tooltip card. Skip/Next navigation with step counter. @AppStorage(featureTourCompletedKey) persists completion. Triggers in QuoteView via onChange of isLoading. Commit fe4da7e.
<!-- tags: design-system, phase8, coach-marks | created: 2026-03-12 -->

### mem-1773316494-2c32
> QuoteActionsSheet at RunicQuotes/Views/QuoteActionsSheet.swift. QuoteAction enum with 7 actions (share, favorites, collection, copy, edit, hide, delete). Presented via sheet from QuoteView (toolbar + long-press). Delete confirmation via .alert. Hide sets isHidden=true, delete sets isDeleted=true+deletedAt. Edit opens CreateEditQuoteView with QuoteRecord. Commit eed1e8a.
<!-- tags: design-system, phase8, dialogs | created: 2026-03-12 -->

### mem-1773315554-6bd1
> ArchiveView at RunicQuotes/Views/ArchiveView.swift. Quote model has isHidden, isDeleted, deletedAt fields. ArchiveFilter enum (all/hidden/deleted) with segmented tabs. Cards show status tag + Unhide/Restore/Erase actions. Restored toast overlay. Accessible from SettingsView via NavigationLink. Commit 4dbca0b.
<!-- tags: design-system, phase7, archive | created: 2026-03-12 -->

### mem-1773314966-b6ec
> QuotePackDetailView enhanced with install flow: Install button at bottom (gradient fade), Pack Added success overlay (checkmark, title, Explore Pack CTA). UserPreferences.installedPackIDs persists installed pack IDs (same pattern as savedQuoteIDs). Commit b9d51b8.
<!-- tags: design-system, phase7, quote-packs | created: 2026-03-12 -->

### mem-1773314618-9455
> QuotePack is a static catalog model (struct, not SwiftData) at RunicQuotes/Models/QuotePack.swift with 5 packs. QuotePacksView accessible via NavigationLink from CollectionsView. QuotePackDetailView shows pack header, description, numbered preview quotes. Packs: Havamal(32), Meditations(48), PoeticEdda(24), StoicLetters(36), ProseEdda(20). Commit 29d2e35.
<!-- tags: design-system, phase7, quote-packs | created: 2026-03-12 -->

### mem-1773314232-3c49
> ShareQuoteView implements Phase 6 Share feature. ShareCardStyle enum (dark/light) with card preview and 3 action buttons (Copy/Save/Share). ShareCardContent renders styled card with rune ornament, runic text, quote, author, dot separator, branding. Dark card always uses dark palette. QuoteView presents ShareQuoteView via sheet instead of old inline share. Commit cf835a7.
<!-- tags: design-system, phase6, share | created: 2026-03-12 -->

### mem-1773313595-e28d
> CreateEditQuoteView and CreateEditQuoteViewModel implement Phase 5 Create & Edit flows. Quote model has source field. QuoteRepository extended with createQuote/updateQuote. Form sections: Quote text, Attribution (Author+Source), Collection chips, Rune Preview. Success overlay with View Quote and Create another. Create triggered via + button in QuoteView toolbar (sheet). Edit mode pre-fills from QuoteRecord. Commit f1b89b0.
<!-- tags: design-system, phase5, create-edit | created: 2026-03-12 -->

### mem-1773313056-6ff0
> OnboardingView redesigned with 5-step flow (Splash/Intro/Atmosphere/Notifications/Ready). Uses AppThemePalette.adaptive(for:), GlassCard(intensity:), GlassButton.primary(), DesignTokens spacing/radius. Splash auto-advances after 2s. Atmosphere step has 3 script cards. Notifications step requests UNUserNotificationCenter permission. Widget style selection removed (not in Figma). NativePageControl removed. Commit fe77df1.
<!-- tags: design-system, phase4, onboarding | created: 2026-03-12 -->

### mem-1773312532-6f51
> SettingsView redesigned with grouped glass sections matching Figma. Sections: Appearance (theme cards), Default Script (runic preview rows), Typography (font selector + presets), Widget (mode/style/glyphs), Accessibility (reduce transparency/motion), About (version/rate). Uses AppThemePalette.adaptive(for:), GlassCard(intensity: .medium), DesignTokens spacing/radius. Reusable helpers: selectionRow, settingsToggleRow, settingsActionRow. Commit 32bca28.
<!-- tags: design-system, phase3, settings | created: 2026-03-12 -->

### mem-1773310734-9222
> MainTabView refactored to 5-tab navigation using AppTab enum (home/collections/search/saved/settings). Tabs driven by ForEach(AppTab.allCases) with @ViewBuilder tabContent(for:). Generic switchToTab notification added in AppConstants. Legacy switchToQuoteTab/switchToSettingsTab preserved. Stub views (CollectionsView, SearchView, SavedView) created with adaptive palette empty states. Commit 1b91d93.
<!-- tags: design-system, phase2, navigation | created: 2026-03-12 -->

### mem-1773310178-77b3
> GlassCard and GlassButton updated with DesignTokens.GlassIntensity-based initializers (strong/medium/light). Uses GlassColor adaptive tokens for bg/border/highlight. Legacy initializers (opacity: GlassOpacity, blur: Material) preserved for backward compat. Convenience variants (primary=strong, secondary=light, compact=light) updated.
<!-- tags: design-system, phase1, glass-components | created: 2026-03-12 -->

### mem-1773309931-3f8a
> AppThemePalette refactored with 13 new adaptive tokens (background, groupedBG, surface, surfaceElevated, accentSecondary, textPrimary, textSecondary, textTertiary, runeText, success, warning, error, separator). Use AppThemePalette.adaptive(for: colorScheme) for new dark/light system. Legacy 3-theme tokens preserved. Color(hex:) initializer added in same file.
<!-- tags: design-system, phase1, palette | created: 2026-03-12 -->

### mem-1773309641-23ce
> DesignTokens.swift created at RunicQuotes/Utilities/DesignTokens.swift with Spacing, CornerRadius, GlassIntensity, and GlassColor enums. Build verified on feat/design-refactor branch. xcodeproj is gitignored -- must run xcodegen generate after adding new files.
<!-- tags: design-system, phase1, tokens | created: 2026-03-12 -->

## Decisions

## Fixes

### mem-1773310410-df36
> Pre-existing RunicQuotesWidgetTests build failure: Cannot find type EnvironmentVariants/TimelineProviderContext. Unrelated to design refactor. Widget tests currently broken.
<!-- tags: testing, widget, pre-existing | created: 2026-03-12 -->

## Context

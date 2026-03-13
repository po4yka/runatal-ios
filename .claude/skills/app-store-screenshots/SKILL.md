---
name: app-store-screenshots
description: "Generate App Store screenshots for the Runic Quotes iOS app (iPhone and iPad). Use when: creating App Store listing assets, marketing screenshots, or store listing images. Triggers on: app store, screenshots, marketing, store listing, iphone, ipad."
---

# App Store Screenshots Generator (Runic Quotes)

## Overview

Build a Next.js page that renders App Store screenshots as **advertisements** (not UI showcases) and exports them via `html-to-image` at Apple's required resolutions. Screenshots are the single most important conversion asset on the App Store.

**Runic Quotes ships to 2 device types:**
- App Store (iPhone)
- App Store (iPad)

**Apple App Store constraints:**
- Max 10 screenshots per device type
- Screenshots must match exact device display sizes
- No pricing, "free", or ranking claims
- Screenshots must accurately represent the app UI
- iPhone screenshots cannot be reused for iPad listings
- PNG or JPEG, no alpha transparency
- Minimum 1 screenshot per supported device, 4+ recommended

## Core Principle

**Screenshots are advertisements, not documentation.** Every screenshot sells one idea. If you're showing UI, you're doing it wrong -- you're selling a *feeling*, an *outcome*, or killing a *pain point*.

## Step 1: Confirm Runic Quotes Defaults with the User

The following brand details are pre-filled for Runic Quotes. Confirm them and collect the remaining items.

### Pre-Filled (confirm, don't ask from scratch)

| Item | Default |
|------|---------|
| App name | Runic Quotes |
| Brand colors (Obsidian) | Background: `#080B11` / Text: `#F4EFE6` / Accent: `#C6A46A` / Surface: `#202733` / Rune Text: `#E6D4B2` |
| Brand colors (Parchment) | Background: `#16100B` / Text: `#F3E5CE` / Accent: `#D39D4B` / Surface: `#432F20` / Rune Text: `#E8BE74` |
| Brand colors (Nordic Dawn) | Background: `#0A141B` / Text: `#EAF4F7` / Accent: `#8BC7D8` / Surface: `#1E3543` / Rune Text: `#BDE2ED` |
| Fonts | Inter (SF Pro web fallback) for UI text. Source Serif 4 for quote body. Runic fonts (NotoSansRunic, BabelStoneRunic, CirthAngerthas) for decorative rune elements. |
| Style direction | Dark/moody, glassmorphism, frosted glass surfaces, stone-carving mystique |
| Feature list | 1. Three runic scripts (Elder Futhark, Younger Futhark, Cirth) 2. Real-time transliteration 3. Home Screen & Lock Screen widgets (WidgetKit) 4. Three visual themes (Obsidian, Parchment, Nordic Dawn) 5. Four quote collections (All, Motivation, Stoic, Tolkien) 6. Create your own quotes 7. Share as images 8. Glassmorphism UI |

### Ask the User

1. **iPhone screenshots** -- "Where are your iPhone screenshots? (PNG files from iPhone 15 Pro Max / 16 Pro Max simulator)"
2. **iPad screenshots** -- "Where are your iPad screenshots? (PNG files from iPad Pro 12.9" / 13" simulator)"
3. **App icon** -- "Where is your app icon PNG?"
4. **Number of slides** -- "How many screenshots do you want? (App Store allows up to 10)"
5. **Primary theme** -- "Which theme for the primary screenshot set? (Obsidian recommended. We can also generate per-theme sets.)"
6. **Device frame** -- "Apple discourages device frames. Use frameless (recommended) or CSS iPhone/iPad frame?"
7. **Localized screenshots** -- "Do you want screenshots in multiple languages? If yes, which languages?"
8. **App Store subtitle** -- "What App Store subtitle? (30 chars max, suggest: 'Ancient runes. Daily wisdom.')"
9. **Component assets** -- "Do you have any UI element PNGs (glass cards, widgets) for floating decorations?"
10. **Additional instructions** -- "Any specific requirements or preferences?"

### Derived from answers (do NOT ask -- decide yourself)

Based on the user's style direction, brand colors, and app aesthetic, decide:
- **Background style**: gradient direction, colors, which theme to base the primary set on
- **Decorative elements**: rune-inspired glows, frosted glass overlays, stone textures, or none
- **Dark vs light slides**: how many of each, which features suit dark/light treatment
- **Typography treatment**: weight, tracking, line height
- **Color palette**: derive secondary colors, shadow tints from the selected theme
- **Theme showcase slide**: how to present all three themes on one slide

**IMPORTANT:** If the user gives additional instructions at any point during the process, follow them. User instructions always override skill defaults.

## Step 2: Set Up the Project

### Detect Package Manager

Check what's available, use this priority: **bun > pnpm > yarn > npm**

```bash
# Check in order
which bun && echo "use bun" || which pnpm && echo "use pnpm" || which yarn && echo "use yarn" || echo "use npm"
```

### Scaffold (if no existing Next.js project)

```bash
# With bun:
bunx create-next-app@latest . --typescript --tailwind --app --src-dir --no-eslint --import-alias "@/*"
bun add html-to-image

# With pnpm:
pnpx create-next-app@latest . --typescript --tailwind --app --src-dir --no-eslint --import-alias "@/*"
pnpm add html-to-image

# With yarn:
yarn create next-app . --typescript --tailwind --app --src-dir --no-eslint --import-alias "@/*"
yarn add html-to-image

# With npm:
npx create-next-app@latest . --typescript --tailwind --app --src-dir --no-eslint --import-alias "@/*"
npm install html-to-image
```

### File Structure

```
project/
├── public/
│   ├── app-icon.png            # Runic Quotes app icon
│   ├── screenshots/
│   │   ├── iphone/             # iPhone screenshots (from simulator)
│   │   │   ├── home.png
│   │   │   ├── feature-1.png
│   │   │   └── ...
│   │   └── ipad/               # iPad screenshots (from simulator)
│   │       ├── home.png
│   │       └── ...
├── src/app/
│   ├── layout.tsx              # Inter + Source Serif 4 font setup
│   └── page.tsx                # The screenshot generator (single file)
└── package.json
```

No mockup PNG is needed. Device frames are CSS-only (optional) and frameless is the default.

**Multi-language:** nest screenshots under a locale folder per device. The generator switches the `base` path; all slide image srcs stay identical.

```
└── screenshots/
    ├── en/
    │   ├── iphone/
    │   └── ipad/
    ├── ru/
    │   └── ...
    └── {locale}/
```

**The entire generator is a single `page.tsx` file.** No routing, no extra layouts, no API routes.

### Multi-language: Locale Tabs

Add a `LOCALES` array and locale tabs to the toolbar. Every slide src uses `base` -- no hardcoded paths:

```tsx
const LOCALES = ["en", "ru"] as const; // use whatever langs were defined
type Locale = typeof LOCALES[number];

// In ScreenshotsPage:
const [locale, setLocale] = useState<Locale>("en");
const base = `/screenshots/${locale}`;

// Toolbar tabs:
{LOCALES.map(l => (
  <button key={l} onClick={() => setLocale(l)}
    style={{ fontWeight: locale === l ? 700 : 400 }}>
    {l.toUpperCase()}
  </button>
))}

// In every slide -- unchanged between single and multi-language:
<Screenshot src={`${base}/iphone/home.png`} alt="Home" />
```

### Font Setup

```tsx
// src/app/layout.tsx
import { Inter, Source_Serif_4 } from "next/font/google";
const sans = Inter({ subsets: ["latin"], variable: "--font-sans" });
const serif = Source_Serif_4({
  subsets: ["latin"], weight: ["400", "600"], variable: "--font-serif",
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <html><body className={`${sans.variable} ${serif.variable}`}
    style={{ fontFamily: "var(--font-sans)" }}>{children}</body></html>;
}
```

## Step 3: Plan the Slides

### Screenshot Framework (Narrative Arc)

Adapt this framework to the user's requested slide count (max 10). Not all slots are required -- pick what fits:

| Slot | Purpose | Runic Quotes Suggestion |
|------|---------|------------------------|
| #1 | **Hero / Main Benefit** | Runic quote on dark glass bg, accent glow. "Ancient wisdom, one rune at a time" |
| #2 | **Differentiator** | Three runic scripts showcase. "Three scripts. Thousands of years." |
| #3 | **Core Feature** | Real-time transliteration. "Watch letters become runes" |
| #4 | **Ecosystem** | Home Screen + Lock Screen widgets. "Runes on your Home Screen" |
| #5 | **Core Feature** | Create your own quotes. "Carve your own words" |
| #6 | **Core Feature** | Share as images. "Send runes to the world" |
| #7 | **Trust Signal** | Three themes showcase. "Three moods. One soul." |
| #8 | **Core Feature** | Quote collections. "Stoics. Tolkien. Timeless." |
| #9 | **Aesthetic** | Glassmorphism UI beauty shot. "Forged in glass and stone" |
| #10 | **More Features** | Feature pills + coming soon. "And so much more." |

**Rules:**
- Each slide sells ONE idea. Never two features on one slide.
- Vary layouts across slides -- never repeat the same template structure.
- Include 1-2 contrast slides (use Parchment or Nordic Dawn theme) for visual rhythm.
- **No promotional pricing, rankings, or award claims.**
- iPad slides may use landscape orientation where it benefits the content (e.g., widget showcase).

### Theme Showcase Slide (#7)

This slide is unique to the iOS app. Show all three themes side by side:
- Three phones (or frameless screenshots) at ~32% width each
- Obsidian left, Parchment center, Nordic Dawn right
- Slight overlap or stagger for depth
- Same quote displayed in each theme

## Step 4: Write Copy FIRST

Get all headlines approved before building layouts. Bad copy ruins good design.

### The Iron Rules

1. **One idea per headline.** Never join two things with "and."
2. **Short, common words.** 1-2 syllables. No jargon unless it's domain-specific.
3. **3-5 words per line.** Must be readable at thumbnail size in the App Store.
4. **Line breaks are intentional.** Control where lines break with `<br />`.
5. **Keep text minimal.** The App Store rewards visual-first screenshots.

### Three Approaches (pick one per slide)

| Type | What it does | Example |
|------|-------------|---------|
| **Paint a moment** | You picture yourself doing it | "Glance at runes over morning coffee." |
| **State an outcome** | What your life looks like after | "Your words, carved in ancient script." |
| **Kill a pain** | Name a problem and destroy it | "Never Google a rune chart again." |

### What NEVER Works

- **Feature lists as headlines**: "Transliterate text into Elder Futhark, Younger Futhark, and Cirth"
- **Two ideas joined by "and"**: "Create quotes and share with friends"
- **Compound clauses**: "Save and customize quotes for every script you like"
- **Vague aspirational**: "Every rune, transliterated"
- **Marketing buzzwords**: "AI-powered rune engine" (unless it's actually AI)
- **Promotional text**: "Best rune app 2026" or "Free for limited time"

### Bad-to-Better Headline Examples (Runic Quotes)

| Weak | Better | Why it wins |
|------|--------|-------------|
| View quotes in three ancient runic alphabets | Three scripts. Thousands of years. | emotional scale, not a feature list |
| Transliterate any text into runic scripts in real time | Watch letters become runes | action verb, curiosity hook |
| Add widgets to your Home Screen and Lock Screen | Runes on your Home Screen | concrete, Apple-native language |
| Choose from Obsidian, Parchment, or Nordic Dawn themes | Three moods. One soul. | poetic, memorable, sells personality |
| Browse Motivation, Stoic, and Tolkien quote collections | Stoics. Tolkien. Timeless. | name-drops that resonate |
| Create and transliterate your own custom quotes | Carve your own words | action verb, concrete metaphor |
| Share transliterated quotes as images with friends | Send runes to the world | bigger feeling, not a UI description |

### Copy Process

1. Write 3 options per slide using the three approaches
2. Read each at arm's length -- if you can't parse it in 1 second, it's too complex
3. Check: does each line have 3-5 words? If not, adjust line breaks
4. Verify text is minimal and visual-first
5. Present options to the user with reasoning for each

### Example Prompt Shape

If the user gives a vague request like "make App Store screenshots," reshape it using the pre-filled defaults:

```text
Generate App Store screenshots for Runic Quotes, an iOS app
that displays inspirational quotes transliterated into ancient runic scripts.
The app's main strengths are three runic scripts, real-time transliteration,
and Home Screen & Lock Screen widgets. I want 10 slides, dark/moody style
with glassmorphism surfaces and a stone-carving mystique.
```

The pattern is: app name + core outcome, top features in priority order, slide count, style direction.

### Reference Apps for Copy Style

- **Mela** -- warm, minimal, elegant
- **Notion** -- clean, one idea per slide
- **Calm** -- evocative, atmospheric

## Step 5: Build the Page

### Architecture

```
page.tsx
├── Constants (IPHONE/IPAD sizes, THEMES, BRAND tokens)
├── Screenshot component (frameless default -- rounded-rect + shadow)
├── IPhone component (CSS-only frame, optional)
├── IPad component (CSS-only frame, optional)
├── Caption component (label + headline, accepts canvasW for scaling)
├── Decorative components (rune glows, frosted glass overlays, stone textures)
├── iphoneSlide1..N components (one per slide)
├── ipadSlide1..N components (optional, reuse iPhone designs)
├── IPHONE_SCREENSHOTS / IPAD_SCREENSHOTS arrays (registries)
├── ScreenshotPreview (ResizeObserver scaling + hover export)
└── ScreenshotsPage (grid + device toggle + size dropdown + theme selector + export logic)
```

### Export Sizes (Apple App Store)

#### iPhone

```typescript
const IPHONE_SIZES = [
  { label: '6.9" iPhone 16 Pro Max', w: 1320, h: 2868 },
  { label: '6.7" iPhone 15 Pro Max', w: 1290, h: 2796 },
  { label: '6.5" iPhone 14 Plus', w: 1284, h: 2778 },
  { label: '5.5" iPhone 8 Plus', w: 1242, h: 2208 },
] as const;
```

Design at 1290x2796 (6.7" -- most common modern iPhone). Scale to other sizes.

#### iPad

```typescript
const IPAD_SIZES = [
  { label: '13" iPad Pro M4', w: 2064, h: 2752 },
  { label: '12.9" iPad Pro', w: 2048, h: 2732 },
  { label: '11" iPad Pro', w: 1668, h: 2388 },
] as const;
```

Design at 2048x2732 (12.9" -- required by Apple). Scale to other sizes.

#### Device Toggle

Add a device selector in the toolbar: iPhone / iPad. The size dropdown updates to show the relevant sizes for the selected device. Support a `?device=ipad` URL parameter for headless/automated capture workflows.

### Rendering Strategy

Each screenshot is designed at full resolution for the primary target device. Two copies exist:

1. **Preview**: CSS `transform: scale()` via ResizeObserver to fit a grid card
2. **Export**: Offscreen at `position: absolute; left: -9999px` at true resolution

Primary design resolutions:
- iPhone: 1290x2796
- iPad: 2048x2732 (portrait)

Reuse the same slide designs across devices -- adjust phone placement width and caption scaling based on `canvasW`.

### Runic Quotes Brand Tokens (3-Theme System)

```typescript
const THEMES = {
  obsidian: {
    bg: "#080B11",
    text: "#F4EFE6",
    accent: "#C6A46A",
    surface: "#202733",
    rune: "#E6D4B2",
    name: "Obsidian",
  },
  parchment: {
    bg: "#16100B",
    text: "#F3E5CE",
    accent: "#D39D4B",
    surface: "#432F20",
    rune: "#E8BE74",
    name: "Parchment",
  },
  nordicDawn: {
    bg: "#0A141B",
    text: "#EAF4F7",
    accent: "#8BC7D8",
    surface: "#1E3543",
    rune: "#BDE2ED",
    name: "Nordic Dawn",
  },
} as const;

type ThemeKey = keyof typeof THEMES;

// Default to Obsidian for primary screenshots
const BRAND = THEMES.obsidian;
```

Add a **theme selector** in the toolbar (Obsidian / Parchment / Nordic Dawn) that swaps the active `BRAND` object. This allows generating a full screenshot set per theme if desired.

### Screenshot Component (Frameless -- Default)

Apple discourages device frames. The default renders the app screenshot in a styled container with no device chrome.

```tsx
function Screenshot({ src, alt, style, className = "" }: {
  src: string; alt: string; style?: React.CSSProperties; className?: string;
}) {
  return (
    <div className={`relative ${className}`}
      style={{ aspectRatio: "1290/2796", ...style }}>
      <div style={{
        width: "100%", height: "100%",
        borderRadius: "3.5%", overflow: "hidden",
        boxShadow: "0 8px 40px rgba(0,0,0,0.3)",
      }}>
        <img src={src} alt={alt}
          style={{ display: "block", width: "100%", height: "100%",
            objectFit: "cover", objectPosition: "top" }}
          draggable={false} />
      </div>
    </div>
  );
}
```

### IPhone Component (CSS-Only Frame -- Optional)

CSS-only iPhone frame with Dynamic Island. No PNG mockup needed.

```tsx
function IPhone({ src, alt, style, className = "" }: {
  src: string; alt: string; style?: React.CSSProperties; className?: string;
}) {
  return (
    <div className={`relative ${className}`}
      style={{ aspectRatio: "430/932", ...style }}>
      <div style={{
        width: "100%", height: "100%", borderRadius: "13% / 6%",
        background: "linear-gradient(180deg, #1A1A1C 0%, #0E0E10 100%)",
        position: "relative", overflow: "hidden",
        boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.12), 0 12px 48px rgba(0,0,0,0.7)",
      }}>
        {/* Dynamic Island */}
        <div style={{
          position: "absolute", top: "1.6%", left: "50%",
          transform: "translateX(-50%)",
          width: "28%", height: "3.2%",
          borderRadius: "50px", background: "#000",
          zIndex: 20,
        }} />
        {/* Bezel edge highlight */}
        <div style={{
          position: "absolute", inset: 0, borderRadius: "13% / 6%",
          border: "1px solid rgba(255,255,255,0.08)",
          pointerEvents: "none", zIndex: 15,
        }} />
        {/* Side button (right) */}
        <div style={{
          position: "absolute", right: "-1.2%", top: "18%",
          width: "0.8%", height: "8%",
          borderRadius: "0 2px 2px 0",
          background: "linear-gradient(90deg, #2A2A2C, #1A1A1C)",
        }} />
        {/* Volume buttons (left) */}
        <div style={{
          position: "absolute", left: "-1.2%", top: "16%",
          width: "0.8%", height: "4%",
          borderRadius: "2px 0 0 2px",
          background: "linear-gradient(270deg, #2A2A2C, #1A1A1C)",
        }} />
        <div style={{
          position: "absolute", left: "-1.2%", top: "22%",
          width: "0.8%", height: "4%",
          borderRadius: "2px 0 0 2px",
          background: "linear-gradient(270deg, #2A2A2C, #1A1A1C)",
        }} />
        {/* Screen area */}
        <div style={{
          position: "absolute", left: "2.8%", top: "2.4%",
          width: "94.4%", height: "95.2%",
          borderRadius: "10% / 4.6%", overflow: "hidden", background: "#000",
        }}>
          <img src={src} alt={alt}
            style={{ display: "block", width: "100%", height: "100%",
              objectFit: "cover", objectPosition: "top" }}
            draggable={false} />
        </div>
      </div>
    </div>
  );
}
```

### IPad Component (CSS-Only Frame -- Optional)

CSS-only iPad Pro frame with thin bezels and Face ID camera.

```tsx
function IPad({ src, alt, style, className = "", landscape = false }: {
  src: string; alt: string; style?: React.CSSProperties;
  className?: string; landscape?: boolean;
}) {
  const aspectRatio = landscape ? "1366/1024" : "1024/1366";
  return (
    <div className={`relative ${className}`}
      style={{ aspectRatio, ...style }}>
      <div style={{
        width: "100%", height: "100%", borderRadius: "3.6% / 2.8%",
        background: "linear-gradient(180deg, #1A1A1C 0%, #0E0E10 100%)",
        position: "relative", overflow: "hidden",
        boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.1), 0 12px 48px rgba(0,0,0,0.65)",
      }}>
        {/* Face ID camera (top center in portrait) */}
        <div style={{
          position: "absolute",
          ...(landscape
            ? { left: "1%", top: "50%", transform: "translateY(-50%)", width: "0.5%", height: "0.8%" }
            : { top: "0.8%", left: "50%", transform: "translateX(-50%)", width: "0.8%", height: "0.5%" }),
          borderRadius: "50%", background: "#111113",
          border: "1px solid rgba(255,255,255,0.08)", zIndex: 20,
        }} />
        {/* Bezel edge highlight */}
        <div style={{
          position: "absolute", inset: 0, borderRadius: "3.6% / 2.8%",
          border: "1px solid rgba(255,255,255,0.06)",
          pointerEvents: "none", zIndex: 15,
        }} />
        {/* Screen area */}
        <div style={{
          position: "absolute", left: "2.4%", top: "2.4%",
          width: "95.2%", height: "95.2%",
          borderRadius: "1.8% / 1.4%", overflow: "hidden", background: "#000",
        }}>
          <img src={src} alt={alt}
            style={{ display: "block", width: "100%", height: "100%",
              objectFit: "cover", objectPosition: "top" }}
            draggable={false} />
        </div>
      </div>
    </div>
  );
}
```

**Device layout adjustments:**

| Platform | Phone width | Aspect | Notes |
|----------|-------------|--------|-------|
| iPhone | 80-84% | ~430:932 portrait | Standard centered layout |
| iPad | 60-70% | ~3:4 portrait or landscape | Can use landscape for widget showcase |

### Typography (Resolution-Independent)

All sizing relative to canvas width W:

| Element | Size | Weight | Line Height | Font |
|---------|------|--------|-------------|------|
| Category label | `W * 0.032` | 500 (medium) | default | Inter |
| Headline | `W * 0.085` to `W * 0.10` | 700 (bold) | 1.0 | Inter |
| Hero headline | `W * 0.10` to `W * 0.11` | 700 (bold) | 0.92 | Inter |
| Decorative rune text | `W * 0.06` | 400 | 1.2 | (rendered via screenshot, not web font) |

Use Inter for all headlines and labels (web fallback for SF Pro). Source Serif 4 for any quote body text shown outside of screenshots.

### Phone Placement Patterns

Vary across slides -- NEVER use the same layout twice in a row:

**Centered phone** (hero, single-feature):
```
bottom: 0, width: "80-84%", translateX(-50%) translateY(12-14%)
```

**Two phones layered** (comparison):
```
Back: left: "-8%", width: "65%", rotate(-4deg), opacity: 0.55
Front: right: "-4%", width: "80%", translateY(10%)
```

**Three phones** (theme showcase, slide #7):
```
Left: left: "2%", width: "38%", rotate(-4deg), opacity: 0.7
Center: left: "50%", translateX(-50%), width: "44%", zIndex: 2
Right: right: "2%", width: "38%", rotate(4deg), opacity: 0.7
```

**Phone + floating elements** (only if user provided component PNGs):
```
Cards should NOT block the phone's main content.
Position at edges, slight rotation (2-5deg), drop shadows.
If distracting, push partially off-screen or make smaller.
```

### Glassmorphism Decorative Elements

The app's signature aesthetic is frosted glass. Incorporate this into slide backgrounds:

```tsx
// Frosted glass card overlay (decorative)
<div style={{
  position: "absolute",
  background: "rgba(255, 255, 255, 0.06)",
  backdropFilter: "blur(24px)",
  WebkitBackdropFilter: "blur(24px)",
  borderRadius: "18px",
  border: "1px solid rgba(255, 255, 255, 0.08)",
}} />
```

Use glass overlays sparingly -- they add depth without competing with the screenshot content.

### "More Features" Slide (Optional)

Dark background (current theme bg) with app icon, headline ("And so much more."), and feature pills. Can include a "Coming Soon" section with dimmer pills. Use the theme accent color behind the icon as a subtle glow.

## Step 5.5: App Store Promo Considerations

Apple does not require a separate promotional graphic. The first screenshot is the hero in App Store search results.

### Key Guidance

- **Slide #1 must be the strongest** -- it appears in search results, category pages, and "Today" features
- **App Store subtitle** (30 chars) appears under the app name everywhere -- keep it punchy
- Suggested subtitle: "Ancient runes. Daily wisdom."
- Optional: If the user provides a video, offer to generate an App Preview poster frame (same dimensions as the device screenshot)

### No Separate Promotional Graphic

The App Store does not have a dedicated promotional graphic format. All marketing happens through screenshots and the optional App Preview video.

## Step 6: Export

### Why html-to-image, NOT html2canvas

`html2canvas` breaks on CSS filters, gradients, drop-shadow, backdrop-filter, and complex clipping. `html-to-image` uses native browser SVG serialization -- handles all CSS faithfully. This is especially important for glassmorphism effects.

### Export Implementation

```typescript
import { toPng } from "html-to-image";

// Before capture: move element on-screen
el.style.left = "0px";
el.style.opacity = "1";
el.style.zIndex = "-1";

const opts = {
  width: W, height: H, pixelRatio: 1, cacheBust: true,
  backgroundColor: '#080B11', // Strip alpha -- Apple requires no alpha. Uses Obsidian bg.
};

// CRITICAL: Double-call trick -- first warms up fonts/images, second produces clean output
await toPng(el, opts);
const dataUrl = await toPng(el, opts);

// After capture: move back off-screen
el.style.left = "-9999px";
el.style.opacity = "";
el.style.zIndex = "";
```

### Key Rules

- **Double-call trick**: First `toPng()` loads fonts/images lazily. Second produces clean output. Without this, exports are blank.
- **On-screen for capture**: Temporarily move to `left: 0` before calling `toPng`.
- **Offscreen container**: Use `position: absolute; left: -9999px` (not `fixed`).
- **Resizing**: Load data URL into Image, draw onto canvas at target size.
- 300ms delay between sequential exports.
- Set `fontFamily` on the offscreen container.
- **backgroundColor**: Always set to strip alpha transparency. Apple rejects PNGs with alpha channels. Use the active theme's `bg` color.
- **Numbered filenames with device prefix**: `iphone-01-hero-1290x2796.png`, `ipad-01-hero-2048x2732.png`. Use `String(index + 1).padStart(2, "0")`.
- **Theme-specific filenames** (when generating per-theme sets): `iphone-obsidian-01-hero-1290x2796.png`, `iphone-parchment-01-hero-1290x2796.png`, etc.

### Export-All Button

Add an "Export All" button that exports all screenshots for all selected devices in sequence. Show a progress indicator during batch export.

### Theme-Aware Export

When the theme selector changes, update the `backgroundColor` in export options to match:
- Obsidian: `#080B11`
- Parchment: `#16100B`
- Nordic Dawn: `#0A141B`

## Step 7: Final QA Gate

Before handing the page back to the user, review every slide against this checklist:

### Message Quality

- **One idea per slide**: if a headline sells two ideas, split it or simplify it
- **First slide is strongest**: the hero slide is the App Store search result -- it must hook immediately
- **Readable in one second**: if you cannot parse it instantly at arm's length, rewrite it

### Visual Quality

- **No repeated layouts in sequence**: adjacent slides should not feel templated
- **Decorative elements support the story**: frosted glass overlays and rune glows should add energy without covering the app UI
- **Visual rhythm exists**: include at least one contrast slide (switch theme) when the set is long enough
- **Theme showcase slide**: all three themes are clearly distinguishable and the contrast is visible
- **Glassmorphism renders correctly**: frosted glass effects should be visible in exports (test with double-call trick)

### Export Quality

- **No clipped text or assets** after scaling to the selected export size
- **Screenshots are correctly aligned** inside the frame (if framed) or container (if frameless)
- **Filenames sort correctly** with zero-padded numeric prefixes and device prefixes

### Apple App Store Compliance

- [ ] Screenshots match required device sizes exactly (see IPHONE_SIZES, IPAD_SIZES)
- [ ] No alpha transparency in exported PNGs (`backgroundColor` set in export options)
- [ ] Text is localized if the app supports multiple languages
- [ ] iPhone screenshots are NOT reused for iPad listings (Apple rejects this)
- [ ] iPad screenshots are NOT reused for iPhone listings
- [ ] No pricing, "free", or ranking claims in copy
- [ ] Screenshots accurately represent the actual app UI (Apple reviews for accuracy)
- [ ] iPad screenshots are portrait unless the app is landscape-only
- [ ] Maximum 10 screenshots per device type
- [ ] First screenshot is the strongest (hero in search results)

### Hand-off Behavior

When you present the finished work:

1. briefly explain the narrative arc across the slides
2. mention any slides that intentionally use a different theme for contrast
3. call out any assumptions you made about brand tone, copy, or missing assets
4. note which device types were generated and which sizes are available
5. if per-theme sets were generated, note which themes are included

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| All slides look the same | Vary phone position (center, left, right, two-phone, three-phone, no-phone) |
| Decorative elements invisible | Increase size and opacity -- better too visible than invisible |
| Copy is too complex | "One second at arm's length" test |
| Floating elements block the phone | Move off-screen edges or above the phone |
| Plain black background | Use gradients -- even subtle accent glows add depth |
| Too cluttered | Remove floating elements, simplify to phone + caption |
| Too simple/empty | Add larger decorative elements, frosted glass panels at edges |
| Headlines use "and" | Split into two slides or pick one idea |
| No visual contrast across slides | Switch themes between slides (Obsidian -> Nordic Dawn) |
| Export is blank | Use double-call trick; move element on-screen before capture |
| Alpha in exported PNG | Set `backgroundColor` in html-to-image options |
| Glassmorphism missing in export | Verify `backdrop-filter` renders; use double-call trick |
| Promotional text in copy | Remove pricing, awards, rankings -- Apple rejects these |
| iPhone screenshots on iPad listing | Apple rejects cross-device screenshots -- generate per device |
| Same screenshots for all themes | Use theme selector to generate distinct sets if needed |
| Theme showcase slide is flat | Use three overlapping phones with different themes for depth |

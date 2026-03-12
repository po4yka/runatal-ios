# Runatal Design System Specification

Extracted from Figma: `OQ9lz2369ZW8yobV6eLsGZ` node `18:48374`

## Color Palette

Scandinavian muted cold slate. Seed `#68707A`. Dark-first.

### Dark Mode

| Token             | Hex       |
|-------------------|-----------|
| Background        | `#070a10` |
| Grouped BG        | `#0c1118` |
| Surface           | `#141c28` |
| Surface Elevated  | `#1a2434` |
| Accent            | `#8c9ab0` |
| Accent Secondary  | `#7494ae` |
| Text Primary      | `#e6eef8` |
| Text Secondary    | `#7c8da6` |
| Text Tertiary     | `#4e5c72` |
| Rune Text         | `#a8b8d0` |
| Success           | `#68a878` |
| Warning           | `#98926c` |
| Error             | `#be5e5e` |
| Separator         | `#1e2836` |

### Light Mode

| Token             | Hex       |
|-------------------|-----------|
| Background        | `#f2f4f8` |
| Grouped BG        | `#eaecf1` |
| Surface           | `#ffffff` |
| Accent            | `#3b4b5e` |
| Accent Secondary  | `#4a6a82` |
| Text Primary      | `#0a0f17` |
| Text Secondary    | `#48566a` |
| Rune Text         | `#1a2434` |
| Success           | `#387850` |
| Error             | `#9e3636` |

## Typography

Fonts: Inter (SF Pro proxy), Source Serif 4, Noto Sans Runic

### Type Scale

| Style        | Size     | Weight |
|--------------|----------|--------|
| Large Title  | 2.12rem  | w700   |
| Title 1      | 1.7rem   | w700   |
| Title 2      | 1.34rem  | w600   |
| Title 3      | 1.16rem  | w600   |
| Headline     | 1rem     | w600   |
| Body         | 0.94rem  | w400   |
| Callout      | 0.88rem  | w400   |
| Subheadline  | 0.82rem  | w400   |
| Footnote     | 0.76rem  | w400   |
| Caption 1    | 0.70rem  | w400   |
| Caption 2    | 0.64rem  | w400   |

### Font Stacks

- **Inter**: `'Inter', -apple-system, BlinkMacSystemFont, sans-serif` -- maps to SF Pro in SwiftUI
- **Source Serif 4**: `'Source Serif 4', Georgia, serif` -- quote body text
- **Noto Sans Runic**: runic glyph display

## Spacing & Corner Radius

4px base grid, iOS 26 shape language.

### Spacing Scale

`4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`, `40px`, `48px`, `64px`

### Corner Radius

| Token  | Value  |
|--------|--------|
| xs     | 6px    |
| sm     | 10px   |
| md     | 14px   |
| lg     | 18px   |
| xl     | 22px   |
| 2xl    | 26px   |
| 3xl    | 30px   |
| full   | 100px  |

## Liquid Glass Materials

iOS 26 glass system. 3 intensity levels. Dark + Light.

### Intensity Levels

| Level  | Blur     | Saturate |
|--------|----------|----------|
| Strong | 60px     | 2.0      |
| Medium | 40px     | 1.8      |
| Light  | 24px     | 1.5      |

### Glass Tokens

| Token              | Dark                       | Light                      |
|--------------------|----------------------------|----------------------------|
| Glass BG           | `rgba(18,24,38,0.52)`      | `rgba(252,253,255,0.58)`   |
| Glass Border       | `rgba(255,255,255,0.10)`   | `rgba(255,255,255,0.55)`   |
| Glass Highlight    | `rgba(255,255,255,0.06)`   | `rgba(255,255,255,0.9)`    |

## Component Tokens

### Navigation

- **Tab Bar**: Liquid Glass pill, 52px height
  - Tabs: Home, Collections, Search, Saved, Settings
- **Navigation Bar**: Glass medium, large-title or inline

### Controls

- **Active Chip**: filled accent style
- **Chip**: outlined glass style

### Cards

- **Content Card**: Glass light, radius.xl (20px), inner highlight + subtle shadow
- **List Row**: within grouped glass sections
- **Grouped Section**: glass container with list rows

### Ornaments

- Celtic knot decorators
- Dot separators
- Rune display elements

## Iconography

24px stroke icons, 1.5px weight, round caps & joins.

Icons: Home, Collections, Search, Bookmark, Settings, Share, Refresh, Back, Forward, Check, Close, External

## App Icon

- Standalone iOS 26 icon architecture
- Deep slate base with optically-aligned Rune mark
- Layered: Base Surface -> Liquid Glass Wash -> Foreground Mark
- Modes: Default/Light, Dark, Monochrome, Tinted

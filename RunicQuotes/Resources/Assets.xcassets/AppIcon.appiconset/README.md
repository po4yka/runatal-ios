# App Icon Design Guide

## Design Concept

The Runic Quotes app icon should embody the **liquid glass/glassmorphism** aesthetic with a focus on **ancient runic wisdom**.

### Visual Elements

1. **Background**: Grayscale gradient (black → dark gray → black)
2. **Central Element**: Large Elder Futhark rune (ᚠ - Fehu, representing fortune/wealth)
3. **Glass Effect**: Translucent overlay with gradient border
4. **Texture**: Subtle noise for depth

### Color Palette

- **Background**: `#000000` → `#1A1A1A` → `#000000` (radial gradient)
- **Rune**: `#FFFFFF` with 90% opacity
- **Glass Border**: Linear gradient from `#FFFFFF` 40% → 10%
- **Inner Glow**: White with 20% opacity, 4px blur

### Design Specifications

#### Required Sizes

| Size | Usage | Filename |
|------|-------|----------|
| 1024x1024 | App Store | AppIcon-1024.png |
| 180x180 | iPhone 3x | AppIcon-60@3x.png |
| 120x120 | iPhone 2x | AppIcon-60@2x.png |
| 120x120 | iPhone Spotlight 3x | AppIcon-40@3x.png |
| 80x80 | iPhone Spotlight 2x | AppIcon-40@2x.png |
| 87x87 | iPhone Settings 3x | AppIcon-29@3x.png |
| 58x58 | iPhone Settings 2x | AppIcon-29@2x.png |
| 60x60 | iPhone Notification 3x | AppIcon-20@3x.png |
| 40x40 | iPhone Notification 2x | AppIcon-20@2x.png |
| 152x152 | iPad | AppIcon-76@2x.png |
| 76x76 | iPad | AppIcon-76@1x.png |
| 167x167 | iPad Pro | AppIcon-83.5@2x.png |
| 80x80 | iPad Spotlight | AppIcon-40@2x.png |
| 40x40 | iPad Spotlight | AppIcon-40@1x.png |
| 58x58 | iPad Settings | AppIcon-29@2x.png |
| 29x29 | iPad Settings | AppIcon-29@1x.png |
| 40x40 | iPad Notification | AppIcon-20@2x.png |
| 20x20 | iPad Notification | AppIcon-20@1x.png |

### Design Guidelines

#### 1. Main Icon (1024x1024)

```
┌────────────────────────────┐
│  Radial gradient background │
│  (black → dark gray)        │
│                             │
│         ┌─────┐            │
│         │  ᚠ  │  ← Rune    │
│         │     │    (white) │
│         └─────┘            │
│   Glass card with border   │
│                             │
└────────────────────────────┘
```

**Layers:**
1. Background: Radial gradient
2. Glass card: 80% size, rounded corners (60px), blur effect
3. Rune: 50% size, centered, white 90% opacity
4. Border: Gradient stroke, 3px width

#### 2. Smaller Sizes (< 100px)

For smaller icons, simplify:
- Remove glass card
- Keep radial gradient background
- Larger rune (70% size)
- Thinner or no border

### Creating the Icon

#### Option 1: Design Tool (Recommended)

Use **Figma**, **Sketch**, or **Adobe Illustrator**:

1. Create 1024x1024 artboard
2. Add radial gradient background
3. Create rounded rectangle (800x800, radius 60)
4. Apply glass effect (blur, opacity)
5. Add rune character (font: "Noto Sans Runic", size: 512pt)
6. Add gradient border
7. Export all required sizes

#### Option 2: Icon Generator

Use an online service:
- [appicon.co](https://appicon.co)
- [makeappicon.com](https://makeappicon.com)

Upload 1024x1024 master, generates all sizes.

#### Option 3: Placeholder (Development)

For testing, use a simple design:
- Black background
- White rune character
- No effects

### Glassmorphism Effect in Design Tools

**Figma:**
1. Rectangle → Add blur (Background Blur: 40)
2. Fill: White 20% opacity
3. Stroke: Linear gradient (White 40% → 10%)
4. Inner Shadow: White 10%, blur 8

**Sketch:**
1. Rectangle → Gaussian Blur: 40
2. Fill: #FFFFFF at 20%
3. Border: Gradient overlay
4. Inner glow: #FFFFFF at 10%

### Export Settings

- Format: PNG
- Color Profile: sRGB
- No transparency (opaque background)
- No compression (lossless)

### Accessibility

- **Contrast**: Ensure rune is readable on gradient
- **Simplicity**: Icon should be recognizable at small sizes
- **Consistency**: Match app's liquid glass aesthetic

### Testing

View icon at different sizes:
- Spotlight (40-80px)
- Home screen (60-120px)
- Settings (29-58px)
- App Store (1024px)

Ensure readability and visual appeal at all sizes.

### Notes

- Rune selection: ᚠ (Fehu) represents fortune, abundance, and new beginnings
- Alternative runes: ᚱ (Raido - journey), ᚹ (Wunjo - joy)
- Keep design minimal for clarity at small sizes
- App Store screenshot should showcase the glass aesthetic

### Resources

- Fonts: Already included in project (Noto Sans Runic)
- Color values: See `Color+Grayscale.swift`
- Gradient examples: See app views for reference

---

**Last Updated:** 2025-11-15
**Status:** Ready for design implementation

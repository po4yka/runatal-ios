# App Icon

## Design Concept

Glassmorphism aesthetic with an Elder Futhark rune.

- **Background:** Radial gradient (`#000000` to `#1A1A1A`)
- **Central element:** Fehu rune (fortune/wealth) in white at 90% opacity
- **Glass effect:** Translucent overlay with gradient border
- **Border:** Linear gradient from white 40% to 10%

## Sizes

Provide a 1024x1024 master. Xcode generates all required sizes from a single asset.

## Layers (1024x1024)

1. Radial gradient background
2. Glass card: 80% size, 60px corner radius, blur effect
3. Rune: 50% size, centered, white 90% opacity
4. Border: Gradient stroke, 3px

For sizes < 100px, simplify: drop the glass card, enlarge the rune to 70%.

## Export

- Format: PNG, sRGB, opaque (no transparency), lossless

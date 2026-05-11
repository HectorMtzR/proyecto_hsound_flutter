---
name: Alebrije Night
colors:
  surface: '#1c110b'
  surface-dim: '#1c110b'
  surface-bright: '#45362f'
  surface-container-lowest: '#170b07'
  surface-container-low: '#251913'
  surface-container: '#2a1d17'
  surface-container-high: '#352720'
  surface-container-highest: '#40312b'
  on-surface: '#f6ddd3'
  on-surface-variant: '#e1c0b2'
  inverse-surface: '#f6ddd3'
  inverse-on-surface: '#3c2d27'
  outline: '#a88b7e'
  outline-variant: '#594237'
  surface-tint: '#ffb693'
  primary: '#ffb693'
  on-primary: '#561f00'
  primary-container: '#ee6812'
  on-primary-container: '#4b1b00'
  inverse-primary: '#a04100'
  secondary: '#4fdbcc'
  on-secondary: '#003732'
  secondary-container: '#00b4a6'
  on-secondary-container: '#003f39'
  tertiary: '#e4c447'
  on-tertiary: '#3b2f00'
  tertiary-container: '#c7a92d'
  on-tertiary-container: '#4c3e00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbcc'
  primary-fixed-dim: '#ffb693'
  on-primary-fixed: '#351000'
  on-primary-fixed-variant: '#7a3000'
  secondary-fixed: '#70f8e8'
  secondary-fixed-dim: '#4fdbcc'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#ffe172'
  tertiary-fixed-dim: '#e4c447'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#554600'
  background: '#1c110b'
  on-background: '#f6ddd3'
  surface-variant: '#40312b'
typography:
  display-lg:
    fontFamily: Almendra
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Almendra
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Almendra
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Almendra
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
  body-lg:
    fontFamily: Montserrat
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Montserrat
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Montserrat
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Montserrat
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

This design system blends high-fidelity digital precision with the ancestral soul of Oaxacan craftsmanship. The visual direction, "Alebrije Night," evokes a festive, midnight atmosphere where vibrant spiritual guides emerge from deep, warm shadows. 

The style is **Tactile and Artisanal**, prioritizing rich textures over flat surfaces. It utilizes Zapotec-inspired geometric "grecas" as structural elements, creating a rhythmic visual language that mirrors the patterns found in Mitla stonework. The interface should feel hand-carved and intentional, moving away from sterile corporate aesthetics toward a "Modern Folk" digital experience. This is a premium streaming platform that treats music as a precious, curated artifact.

## Colors

The palette is rooted in the "Alebrije Night" concept. The background uses a warm near-black with purple undertones to provide a more organic feel than pure neutral grays. 

- **Primary (Alebrije Orange):** Used for critical actions, playback progress, and active states. It represents the vibrant spirit of the craft.
- **Secondary (Turquoise):** Used for highlighting genres, tags, and secondary interactions, providing a cool contrast to the warm base.
- **Highlight (Golden Yellow):** Reserved for high-fidelity badges, premium features, and star ratings.
- **Surface Tiers:** Surfaces use a deep wine-tinted dark shade to create subtle separation from the background without losing the nocturnal warmth.
- **Typography:** The warm cream primary text ensures readability against the dark backdrop while maintaining an aged, paper-like quality.

## Typography

This design system employs a high-contrast typographic pairing. **Almendra** is used for display and headings to inject a historical, calligraphic character that feels both ancient and sophisticated. **Montserrat** provides a clean, geometric counterpoint for body copy and metadata, ensuring the app remains functional and legible during high-speed navigation.

All labels and captions use slightly increased letter spacing and uppercase styling where appropriate to mimic the rhythmic spacing of textile weaving. Use 'display-lg' sparingly for artist names or album titles in featured views.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a strong emphasis on vertical rhythm. 

- **Mobile:** 4-column grid with 16px margins.
- **Tablet/Desktop:** 12-column grid with 24px gutters. Content is centered with a max-width of 1440px.

Spacing is strictly derived from an 8pt base scale, but 4px increments are allowed for tight component grouping. Decorative Zapotec "greca" patterns should be used as full-width dividers between major sections, acting as functional breaks in the layout while reinforcing the cultural narrative.

## Elevation & Depth

Depth is achieved through **Tonal Layering** and soft, tinted shadows. Because the background is a warm near-black, shadows should not be pure black; they use a slightly darker, more saturated version of the background (#0D080A) with a high blur radius.

1. **Base:** The background (#1A1014).
2. **Surface:** Cards and containers (#261820) with a 1px inner stroke of Text Secondary at 10% opacity to define edges.
3. **Floating:** Playback controls and modals use a soft shadow (0px 8px 24px) with a subtle turquoise or orange glow depending on the context.
4. **Patterns:** Greca textures are applied at 5-10% opacity on surfaces to create a "carved" tactile depth without interfering with content legibility.

## Shapes

The shape language is a mix of architectural rigidity and organic softness. While containers follow a standard rounded-lg (16px) or rounded-xl (24px) logic, specific elements like the "Now Playing" bar and primary buttons use the **30px (Pill)** radius to suggest the smoothness of polished stone or hand-molded clay.

Decorative borders and icons should lean into the sharp, geometric angles of Zapotec "grecas," creating a distinctive tension between the rounded UI containers and the jagged cultural patterns.

## Components

- **Buttons:** Primary buttons are pill-shaped (#E8630A) with dark text. Secondary buttons are outlined with a 2px stroke in Turquoise or Warm Cream.
- **Cards:** Music cards use a 12px corner radius. The "Greca" pattern appears as a subtle 4px tall footer or header on featured content cards.
- **Input Fields:** Deep wine surfaces with a bottom-only border in Terracotta, transforming to Turquoise on focus.
- **Lists:** Song items are separated by a subtle 1px dotted divider. The active song uses the Primary Accent (Orange) for the title and a small animated "Greca" equalizer.
- **Chips/Genre Tags:** Small, semi-transparent turquoise capsules with Montserrat bold labels in all-caps.
- **Playback Slider:** The track is the Terracotta muted color, while the progress fill is the vibrant Alebrije Orange. The "knob" or thumb should be a small geometric diamond shape rather than a circle.
- **Progressive Disclosure:** Use Zapotec-inspired iconography (stylized animals or geometric symbols) for custom interaction hints.
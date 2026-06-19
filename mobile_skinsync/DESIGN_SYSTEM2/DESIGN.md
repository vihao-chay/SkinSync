---
name: SkinSync Design System
colors:
  surface: '#faf9f5'
  surface-dim: '#dbdad6'
  surface-bright: '#faf9f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f4f0'
  surface-container: '#efeeea'
  surface-container-high: '#e9e8e4'
  surface-container-highest: '#e3e2df'
  on-surface: '#1b1c1a'
  on-surface-variant: '#46483c'
  inverse-surface: '#2f312e'
  inverse-on-surface: '#f2f1ed'
  outline: '#76786b'
  outline-variant: '#c6c8b8'
  surface-tint: '#56642b'
  primary: '#56642b'
  on-primary: '#ffffff'
  primary-container: '#8a9a5b'
  on-primary-container: '#253000'
  inverse-primary: '#bdce89'
  secondary: '#9f3f39'
  on-secondary: '#ffffff'
  secondary-container: '#ff897f'
  on-secondary-container: '#76211d'
  tertiary: '#735c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#cca72f'
  on-tertiary-container: '#4e3d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d9eaa3'
  primary-fixed-dim: '#bdce89'
  on-primary-fixed: '#161f00'
  on-primary-fixed-variant: '#3e4c16'
  secondary-fixed: '#ffdad6'
  secondary-fixed-dim: '#ffb4ac'
  on-secondary-fixed: '#410003'
  on-secondary-fixed-variant: '#802824'
  tertiary-fixed: '#ffe088'
  tertiary-fixed-dim: '#e9c349'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#faf9f5'
  on-background: '#1b1c1a'
  surface-variant: '#e3e2df'
typography:
  headline-lg:
    fontFamily: Playfair Display
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Playfair Display
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 20px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  grid-gutter: 12px
  max-width: 460px
---

## Brand & Style
The design system is rooted in a **High-End Wellness** aesthetic that bridges the gap between clinical data and luxury self-care. The brand personality is calming, expert, and deeply personalized. The UI evokes a sense of "digital tranquility"—providing complex dermatological insights without overwhelming the user.

The visual style is a hybrid of **Minimalism** and **Glassmorphism**. It utilizes expansive off-white surfaces to mimic high-end skincare packaging, layered with translucent "glass" headers and soft, organic shadows. Subtle AI-driven glows (soft radial gradients) are used sparingly to highlight "active" scanning or intelligence-driven insights, ensuring the technology feels like a natural extension of the user’s wellness ritual.

## Colors
The palette is inspired by natural elements: sage, earth, and light. 

- **Primary (Sage Green - #8A9A5B):** Used for primary actions, success states, and indicating healthy skin metrics. It provides a grounded, herbal feel.
- **Secondary (Soft Coral - #F88379):** Used for highlighting concerns, "needs attention" areas, or warm interactive accents.
- **Tertiary (Warm Gold - #D4AF37):** Reserved for "Premium" features, AI achievement milestones, and luxury call-outs.
- **Neutral (Ivory - #FDFCF8):** The foundational surface color. It is softer than pure white, reducing eye strain and feeling more organic.
- **Text (Charcoal - #36454F):** High contrast for legibility while maintaining a softer edge than pure black.
- **AI Glows:** Use a low-opacity radial gradient of #8A9A5B or #D4AF37 behind specific components to indicate active AI processing.

## Typography
The system uses a high-contrast typographic pairing to signal both elegance and modern efficiency.

- **Headlines:** Uses **Playfair Display**. This sophisticated serif brings a "lifestyle magazine" feel to skin reports and titles.
- **Body & UI Elements:** Uses **Plus Jakarta Sans**. Its soft, rounded terminals complement the organic nature of skin health while remaining highly legible for data-heavy metric grids.
- **Labels:** Small labels use uppercase with increased letter spacing to provide a clean, structural feel to technical data points.

## Layout & Spacing
This is a **Mobile-First** design system optimized for a maximum width of 460px. 

- **The Rhythm:** A base 4px/8px grid system ensures vertical harmony.
- **Metric Grids:** Use a 2-column grid for skin statistics (e.g., Hydration vs. Oiliness) with a 12px gutter.
- **Safe Zones:** A standard 20px horizontal padding is applied to all main containers to ensure content doesn't feel cramped against the screen edges.
- **Glass Headers:** Top navigation bars should use a fixed height of 64px with a background-blur (20px) to allow content to scroll elegantly beneath.

## Elevation & Depth
Depth in the design system is achieved through a combination of **Tonal Layering** and **Soft Shadows**.

- **Cards:** Use a very subtle, diffused shadow (Blur: 20px, Y: 4px, Color: #36454F at 5% opacity) to make them appear slightly lifted from the Ivory surface.
- **Glassmorphism:** Navigation bars and specific AI overlays use a 70% opacity Ivory (#FDFCF8) with a `backdrop-filter: blur(20px)`. A 1px white border (10% opacity) helps define the edges of these glass elements.
- **Active State:** When an element is focused or "AI-active," use a soft Sage Green outer glow rather than a harsh shadow.

## Shapes
The shape language is organic and approachable.

- **Primary Containers:** 16px (rounded-lg) corner radius for most cards and input fields.
- **Circular Elements:** Used for "Skin Scores," progress indicators, and profile avatars to mirror the organic nature of the face.
- **Pills:** All buttons and selection chips use a full pill radius to emphasize the "soft" wellness aesthetic.

## Components

### Buttons
- **Primary:** Full pill-shaped, Sage Green background with white text.
- **Secondary:** Transparent with a Sage Green border.
- **Tertiary/Premium:** Gold background with Charcoal text.

### Cards & Metric Grids
- Cards should have the standard soft shadow and 16px corner radius.
- **Metric Tiles:** Small, 2-column square tiles showing a circular progress ring (e.g., "78% Hydration").

### Inputs & Selection
- **Text Fields:** Ivory background with a subtle Charcoal border (20% opacity). Labels are always in **label-md** style.
- **Chips:** Small pill-shaped tags used for "Skin Type" (e.g., Oily, Combination). Use Soft Coral for active states.
- **Toggle/Radio:** Soft Sage Green for active states, using rounded-full tracks.

### AI Progress/Scores
- **Skin Score Circle:** A thick-stroked circular progress bar. The center displays the score in **headline-lg**.
- **AI Scanning:** A horizontal "glass" bar that moves vertically over a camera view, utilizing the Sage Green glow effect.

### Lists
- Clean, borderless list items separated by a 1px Ivory-Grey divider. Icons should be Sage Green and enclosed in a light-tinted circle.
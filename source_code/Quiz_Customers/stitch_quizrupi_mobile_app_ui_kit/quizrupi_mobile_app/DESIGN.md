---
name: QuizRupi Mobile App
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c3c6d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8d90a0'
  outline-variant: '#434655'
  surface-tint: '#b4c5ff'
  primary: '#b4c5ff'
  on-primary: '#002a78'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#0053db'
  secondary: '#ffb95f'
  on-secondary: '#472a00'
  secondary-container: '#ee9800'
  on-secondary-container: '#5b3800'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#007d55'
  on-tertiary-container: '#bdffdb'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 34px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
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
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
  price-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '800'
    lineHeight: 22px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system powers an engaging, gamified educational ecosystem paired with physical quiz book commerce. It targets dynamic learners, competitive exam aspirants, and curious minds seeking mastery through instant feedback, rewards, and study material acquisition.

The aesthetic fuses modern high-utility mobile productivity with approachable gamification:
- **Clean Tactile Modernism**: Crisp surface cards floating on a dark immersive background, avoiding visual fatigue during prolonged quiz sessions.
- **Dopamine-Driven Feedback**: High-contrast, punchy state accents (energizing amber for coins/streaks, vibrant emerald for triumphs, clear punchy red for mistakes) balanced by deeply legible neutrals.
- **Friendly Authority**: Generous corner radii, soft tactile elevations, and accessible touch targets that feel responsive, frictionless, and rewarding.

## Colors
The palette balances a dark, immersive base with purposeful, gamified functional colors:

- **Primary Canvas & Surfaces**: 
  - Base background: `#0F172A` (deep dark navy to reduce glare while retaining high contrast).
  - Elevated card surfaces: `#1E293B`.
- **Text & Hierarchy**:
  - Headings & High Emphasis: Pure White and Light Slate (`#FFFFFF`, `#F8FAFC`).
  - Secondary & Supporting Body: Medium Slate (`#94A3B8`, `#CBD5E1`).
  - Subtle & Inactive Borders/Icons: Dark Slate (`#334155`, `#475569`).
- **Functional Accents**:
  - **Primary Action (Brand)**: Royal Blue (`#2563EB`) with a warm orange secondary variant (`#F59E0B`) reserved for flash deals and urgent quiz countdowns.
  - **Points & Streaks (Gamification)**: Educational Amber Gold (`#F59E0B`) with an accessible soft container.
  - **Success & Correct Answers**: Fresh Emerald Green (`#10B981`) paired with soft emerald tint for validated option states.
  - **Error & Incorrect Answers**: Crimson Rose with a supportive dark wash container.

## Typography
Plus Jakarta Sans is selected across all roles. Its geometric underpinnings combined with warm, humanist apertures strike the exact balance needed for a modern mobile learning platform: highly legible under quick-reading quiz scenarios while remaining energetic and approachable.

- **Numerals & Currency**: Indian Rupee (`₹`) glyphs and score counters are rendered in Bold or ExtraBold weights to provide crisp scanning across shop listings and reward banners.
- **Quiz Questions**: Use `headline-sm` or `headline-md` with 1.4x line-height to guarantee high readability under timed pressure.

## Layout & Spacing
The layout relies on a mobile-first fluid column structure tuned specifically for modern Android viewport widths (360dp to 412dp), extending seamlessly to tablet breakpoints.

- **Mobile Canvas**: 4-column layout with 16px (`1rem`) outer margins and 12px-16px column gutters.
- **Vertical Rhythm**: Built strictly on an 8pt spatial grid (with 4pt half-steps reserved for fine metadata alignment and chip padding).
- **Safe Insets**: Screen bottom paddings always account for the 64dp persistent bottom navigation bar plus Android gesture navigation bar clearance (minimum +16px buffer).

## Elevation & Depth
Depth relies on ambient, diffused dark-mode appropriate shadows and low-contrast borders to maintain clean separation across the dark interface:

- **Level 0 (Flat / Canvas)**: Pure dark background with no shadow.
- **Level 1 (Default Cards & Book Tiles)**: Elevated dark surface with subtle ambient shadows and a 1px border.
- **Level 2 (Active Quiz Options & Dropdowns)**: Elevated surface with stronger diffusion for focus states.
- **Level 3 (Sticky Bottom Bar & Modals)**: Dark surface with upward ambient shadows for bottom navigation.
- **Tactile Gamification Buttons**: Interactive primary elements leverage a slight solid bottom shelf that presses down flush on active touch states.

## Shapes
A roundedness tier of 2 provides distinct, friendly geometric softening suited for educational touch interfaces:

- **Primary Cards & Modals**: 16px to 24px (`rounded-lg` through `rounded-xl`) to establish friendly modular containment.
- **Quiz Answer Option Tiles**: 16px (`rounded-lg`) ensuring a comfortable thumb target.
- **Buttons & Bottom Sheets**: 12px for standard inputs; 24px to fully pill-shaped (`rounded-full`) for score badges, streak counters, and floating bottom navigation indicators.

## Components

### Buttons
- **Primary Action (CTA)**: Royal Blue (`#2563EB`) with white text, 48px height, 12px corner radius, bold label. 
- **Urgent / Deal CTA**: Bright Warm Orange (`#F59E0B`) for flash sales or "Double Points" timed actions.
- **Secondary / Ghost**: Dark surface background with 1.5px border and high-contrast text.

### Interactive Quiz Cards & Answer Options
- **Default State**: Dark card, 1.5px stroke, 16px radius, featuring question index chip (A, B, C, D).
- **Selected State**: Border shifts to `#2563EB` (2px) with primary tint background.
- **Correct State**: Border shifts to `#10B981` (2px), checkmark indicator, triggering micro-confetti or point pulse.
- **Incorrect State**: Border shifts to error accent (2px), subtle shake animation.

### Gamified Badges & Chips
- **Streak & Coin Badge**: Pill-shaped badge featuring Amber Gold icon (`#F59E0B`), soft container background, and bold numeral display.
- **Category Chips**: Horizontal scrolling pill chips with 8px horizontal padding, 32px height, switching between unselected and active states.

### Book Commerce Cards
- **Structure**: Vertical card with 2:3 ratio thumbnail, 12px rounded corner cover, book title (2 lines max), author subtext, rating badge (Amber star + score), and pricing row.
- **Pricing Format**: Current price in `price-display` token prefixed with `₹`, original crossed-out price in muted slate, and green discount percentage pill.
- **Quick Add**: Floating circular `+` button in primary blue on the bottom-right corner of the thumbnail.

### Mobile Bottom Navigation (4-Tab)
- **Bar Styling**: Docked bottom bar with 64px height, dark surface background, subtle top border, and blur elevation.
- **Destinations**: 
  1. *Home* (Dashboard, daily challenge, book highlights)
  2. *Quiz* (Arena, live categories, practice tests)
  3. *Shop* (Quiz book store, sample chapters, bundles)
  4. *Orders* (Track shipments, purchases, e-notes)
- **Active State**: 4dp pill indicator under icon in `#2563EB`, icon fills with `#2563EB`, label renders in 11px Bold. Inactive states use muted slate.
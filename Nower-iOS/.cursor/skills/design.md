# Design Skill Core

## Design Philosophy
- Follow Apple Human Interface Guidelines (HIG) and Toss Design System principles.
- Prioritize clarity, calmness, and spatial hierarchy.
- Avoid visual noise, excessive borders, and unnecessary decorations.
- Design should feel physical, grounded, and emotionally calm.
- **Full support for Dark Mode** following Apple HIG standards.

## Visual Hierarchy
- Use size, weight, spacing instead of color whenever possible.
- Primary action must dominate visual weight by at least 1.4x.
- Avoid more than 3 font sizes per screen.
- Avoid more than 2 accent colors per screen.

## Color Rules

### Dark Mode Support
- **Full dark mode compatibility** is mandatory for all UI components.
- Use dynamic colors that automatically adapt to light/dark appearance.
- All color definitions must support both light and dark mode variants.

### Color Contrast (WCAG AA Compliance)
- **Minimum contrast ratio: 4.5:1** for normal text against background.
- **Minimum contrast ratio: 3:1** for large text (18pt+ or 14pt+ bold) against background.
- All text colors must meet accessibility standards in both light and dark modes.
- Test color combinations using automated contrast checkers.

### Base Colors
- **Background (Light)**: #FFFFFF (white)
- **Background (Dark)**: #000000 (black, iOS standard)
- **Text Primary (Light)**: #0F0F0F (near black, contrast 15.8:1)
- **Text Primary (Dark)**: #F5F5F7 (light gray, contrast 16.1:1)
- **Text Main** (for colored capsules): Automatically adjusts based on background

### Accent Colors
- Accent color used only for:
  - Primary CTA
  - Active state
  - Important highlights
- Never use saturated colors for large background areas.
- Accent colors must maintain 4.5:1 contrast with background in both modes.

### Theme Colors (Calendar Events)
- All theme colors (skyblue, peach, lavender, mintgreen, coralred) support dark mode.
- Dark mode variants are automatically adjusted to maintain visibility.
- **Text color is automatically selected** based on background color using `contrastingTextColor` function.
- Bright backgrounds use dark text (#0F0F0F), dark backgrounds use white text.
- All color combinations meet WCAG 4.5:1 contrast ratio requirements.

## Spacing System
- Use 4pt or 8pt grid consistently.
- Minimum touch target: 44pt.
- Vertical rhythm must remain consistent across screens.

## Component Discipline
- Prefer reusable components over local styling.
- Avoid inline magic numbers.
- All spacing, radius, font sizes should reference tokens.
- **All components must support dark mode by default.**

## Accessibility
- Maintain WCAG 4.5:1 contrast ratio for all text.
- Support Dynamic Type for scalable text.
- Ensure sufficient touch target sizes (44pt minimum).
- Test with VoiceOver and other accessibility tools.

## UX Behavior
- Reduce cognitive load.
- Default state should always be useful.
- Empty state must guide next action.
- UI should feel native to iOS platform.

## Implementation Notes
- Use `UIColor { trait in ... }` closures for dynamic colors.
- Always test UI in both light and dark modes.
- Prefer system colors where appropriate (UIColor.label, UIColor.systemBackground, etc.).
- Avoid hardcoded color values; use AppColors enum instead.

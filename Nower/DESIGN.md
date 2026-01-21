# Design Skill Core - macOS

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
- Use `ThemeManager.isDarkMode` to detect current appearance.

### Color Contrast (WCAG AA Compliance)
- **Minimum contrast ratio: 4.5:1** for normal text against background.
- **Minimum contrast ratio: 3:1** for large text (18pt+ or 14pt+ bold) against background.
- All text colors must meet accessibility standards in both light and dark modes.
- Test color combinations using automated contrast checkers.

### Base Colors
- **Background (Light)**: #FFFFFF (white)
- **Background (Dark)**: #000000 (black, macOS standard)
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

### Button Colors (HIG Compliance)
- **buttonBackground**: #007AFF (System Blue)
- **buttonTextColor**: #FFFFFF (White)
- **buttonSecondaryBackground**: Automatically adjusts for dark mode (#3A3A3C dark, #E0E0E0 light)

### Theme Colors (Calendar Events)
- All theme colors (skyblue, peach, lavender, mintgreen, coralred) support dark mode.
- Dark mode variants are automatically adjusted to maintain visibility.
- **Text color is automatically selected** based on background color.
- Bright backgrounds use dark text (#0F0F0F), dark backgrounds use white text.
- All color combinations meet WCAG 4.5:1 contrast ratio requirements.

## Spacing System
- Use 4pt or 8pt grid consistently.
- Minimum click target: 44pt (macOS HIG standard).
- Vertical rhythm must remain consistent across screens.
- WeekView uses spacing: 0 to ensure period events connect seamlessly.

## Component Discipline
- Prefer reusable components over local styling.
- Avoid inline magic numbers.
- All spacing, radius, font sizes should reference tokens.
- **All components must support dark mode by default.**
- Use SwiftUI's `@Environment` for theme-aware components.

## Layout System

### Calendar Grid
- **Week-based layout**: Calendar is organized by weeks for seamless period event display.
- **No cell spacing**: Cells have spacing: 0 to create connected appearance.
- **Fixed cell heights**: All cells in a week have the same height to prevent period events from breaking.
- **GeometryReader**: Used to ensure consistent cell widths and heights across the week.

### Window Management
- **DraggableWindow**: Custom window class for position memory and drag control.
- **Background drag disabled**: Window can only be moved by title bar or designated areas.
- **Position locking**: Optional window position locking feature.

## Accessibility
- Maintain WCAG 4.5:1 contrast ratio for all text.
- Support Dynamic Type for scalable text (where applicable).
- Ensure sufficient click target sizes (44pt minimum).
- Test with VoiceOver and other accessibility tools.

## UX Behavior
- Reduce cognitive load.
- Default state should always be useful.
- Empty state must guide next action.
- UI should feel native to macOS platform.
- **Drag and drop**: Single-day events can be dragged to different dates.

## Implementation Notes
- Use `AppColors` struct for all color access.
- Use `ThemeManager.isDarkMode` for dark mode detection.
- Always test UI in both light and dark modes.
- Prefer system colors where appropriate.
- Avoid hardcoded color values; use AppColors instead.
- Use SwiftUI's built-in components when possible.

## macOS-Specific Guidelines

### Window Behavior
- Window should not be draggable by background click.
- Only title bar or designated drag areas should allow window movement.
- Window position should be remembered across app launches.

### Drag and Drop
- Single-day events can be dragged to different dates.
- Period events cannot be moved (display warning message).
- Use ID-based movement for stability.

### Period Events
- Period events span across multiple days seamlessly.
- All cells in a week must have the same height.
- Events connect visually across day boundaries.
- Start, middle, and end positions have distinct styling.

## File Structure

### Design System Files
- `Extension/AppColors.swift`: Color definitions
- `Extension/AppIcons.swift`: Icon definitions
- `ThemeManager`: Dark mode detection (in AppColors.swift)

### Component Files
- `View/View/ContentView.swift`: Main view container
- `View/View/CalendarGridView.swift`: Calendar grid
- `View/View/WeekView.swift`: Week container
- `View/View/DayView.swift`: Day cell
- `View/View/EventCapsuleView.swift`: Event capsule
- `View/View/AddEventView.swift`: Add event popup
- `View/View/EditTodoPopupView.swift`: Edit event popup

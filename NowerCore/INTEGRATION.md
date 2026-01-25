# NowerCore Integration Guide

## Overview

NowerCore is a shared Swift Package that provides unified domain models, use cases, and data layer for both macOS and iOS Nower apps.

## Integration Steps

### Step 1: Add Package to Xcode Project

**For macOS (Nower.xcodeproj):**
1. Open `Nower/Nower.xcodeproj` in Xcode
2. Select the project in Navigator
3. Select "Nower" target
4. Go to "General" tab
5. Scroll to "Frameworks, Libraries, and Embedded Content"
6. Click "+" button
7. Click "Add Other..." -> "Add Package Dependency..."
8. Click "Add Local..." and select the `NowerCore` folder
9. Add `NowerCore` library to the target

**For iOS (Nower-iOS.xcodeproj):**
1. Open `Nower-iOS/Nower-iOS.xcodeproj` in Xcode
2. Follow the same steps as above

### Step 2: Enable Migration Code

**macOS - AppDelegate.swift:**
Uncomment the migration code in `applicationDidFinishLaunching`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Uncomment these lines:
    Task { @MainActor in
        DependencyContainer.shared.runMigrationIfNeeded()
        DependencyContainer.shared.startSyncListening()
    }

    // ... rest of the code
}
```

**iOS - AppCoordinator.swift:**
Uncomment the migration code in `start()`:

```swift
func start() {
    // Uncomment these lines:
    Task { @MainActor in
        DependencyContainer.shared.runMigrationIfNeeded()
        DependencyContainer.shared.startSyncListening()
    }

    // ... rest of the code
}
```

### Step 3: Verify Build

1. Build the project (Cmd+B)
2. The `#if canImport(NowerCore)` blocks should now activate
3. Check the console for migration logs

## File Structure

```
NowerCore/
├── Package.swift
├── Sources/NowerCore/
│   ├── NowerCore.swift           # Public exports
│   ├── Domain/
│   │   ├── Entity/
│   │   │   ├── Event.swift       # Core event model with time support
│   │   │   ├── Reminder.swift    # Reminder with trigger calculation
│   │   │   ├── RecurrenceRule.swift
│   │   │   ├── ColorTheme.swift
│   │   │   ├── Location.swift
│   │   │   ├── SyncStatus.swift
│   │   │   ├── CalendarDay.swift
│   │   │   ├── WeekDayInfo.swift
│   │   │   └── LegacyTodoItem.swift
│   │   ├── Repository/
│   │   │   ├── EventRepository.swift
│   │   │   └── ReminderRepository.swift
│   │   ├── UseCase/
│   │   │   ├── EventUseCases.swift
│   │   │   └── ReminderUseCases.swift
│   │   └── NowerError.swift
│   ├── Data/
│   │   ├── Storage/
│   │   │   ├── StorageProvider.swift
│   │   │   └── EventRepositoryImpl.swift
│   │   └── Sync/
│   │       ├── SyncManager.swift
│   │       └── EventMigrator.swift
│   └── Util/
│       ├── DateFormatters.swift
│       ├── Validation.swift
│       └── CalendarDayGenerator.swift
└── Tests/NowerCoreTests/
    ├── EventTests.swift
    ├── ReminderTests.swift
    ├── RecurrenceRuleTests.swift
    ├── MigrationTests.swift
    └── StorageTests.swift
```

## Key Components

### Event Model
The new `Event` model supports:
- Time-based scheduling (not just date-based)
- All-day events
- Multi-day (period) events
- Time zones
- Recurrence rules
- Reminders

### Use Cases
- `AddEventUseCase`: Create new events
- `DeleteEventUseCase`: Remove events
- `UpdateEventUseCase`: Modify existing events
- `FetchEventsUseCase`: Query events by date range
- `MoveEventUseCase`: Change event dates

### Storage
- `iCloudStorageProvider`: iCloud Key-Value Store
- `LocalStorageProvider`: UserDefaults (fallback)
- `InMemoryStorageProvider`: Testing

### Migration
- `MigrationManager`: Handles schema version upgrades
- `EventMigrator`: Converts legacy `TodoItem` to new `Event`

## Gradual Migration Strategy

The integration uses adapters for backward compatibility:

1. **NowerCoreAdapter.swift** provides:
   - Type aliases (NEvent, NReminder, etc.)
   - `TodoItem.toEvent()` conversion
   - `Event.toTodoItem()` conversion

2. **DependencyContainer.swift** provides:
   - `makeLegacyUseCases()` for existing code
   - NowerCore use cases for new features

This allows gradual migration without breaking existing functionality.

## Next Steps After Integration

1. Migrate ViewModels to use `NowerCore.Event` instead of `TodoItem`
2. Add time picker UI for time-based scheduling
3. Implement `ReminderRepositoryImpl` with `UNUserNotificationCenter`
4. Add natural language parsing for event creation

# Flutter Schedule App - Main Screen Development Tasks

## Phase 1: Core Main Screen Implementation

Based on the wireframe in `main_screen.png` and the project overview, here are the tasks to build the main screen of your scheduling app.

### 1. Project Setup & Dependencies

- [x] **1.1** Verify all dependencies are properly configured in `pubspec.yaml`
  - Ensure riverpod, time_machine, fl_chart, riverpod_generator are added
  - Add any missing UI dependencies (e.g., intl for date formatting)
- [x] **1.2** Set up code generation for Riverpod
  - Add build_runner to dev_dependencies
  - Configure build.yaml if needed
- [x] **1.3** Create basic folder structure in `lib/`
  - `lib/models/` - for data models
  - `lib/providers/` - for Riverpod providers
  - `lib/screens/` - for screen widgets
  - `lib/widgets/` - for reusable widgets
  - `lib/services/` - for persistence and business logic
- [x] **1.4** Create main.dart app entry point
  - Set up MaterialApp with theme and routing
  - Define ColorScheme.fromSeed(...) for Material 3 theming
  - Set home: MainScreen() once created

### 2. Data Models Implementation

- [ ] **2.1** Create `Task` model class
  - Properties: id, name, estimatedMinutes, projectId (nullable for now)
  - Add toJson/fromJson methods for persistence
  - Add copyWith method for immutability
- [ ] **2.2** Create `Block` model class (represents a time slot)
  - Properties: id, taskId, dayLocal, startMinuteOfDay, lengthMinutes
  - Add time calculation helper methods (start/end times)
  - Add toJson/fromJson methods
- [ ] **2.3** Create `DailySchedule` model class
  - Contains a list of blocks for a specific day
  - Add methods to add/remove blocks (keep as simple data operations)
  - Include default scheduling constants (8:35 start, 1hr length, 5min breaks)
  - Note: Keep reordering logic in ScheduleNotifier, not in this model

### 3. State Management Setup

- [ ] **3.1** Create `ScheduleNotifier` using Riverpod
  - Manage current selected date
  - Manage list of blocks for the current day
  - Implement methods: addTask, removeTask, reorderTasks (with proper batching)
- [ ] **3.2** Create `DateNotifier` for current day navigation
  - Track currently viewed date
  - Methods: nextDay, previousDay, goToDate
- [ ] **3.3** Create `Settings` model and `SettingsNotifier`
  - Store user preferences: defaultStartTime, defaultTaskLength, defaultBreakTime
  - Persist settings using same data source as schedule
- [ ] **3.4** Create persistence provider
  - Save/load schedule data to local storage (SharedPreferences initially)
  - Wrap JSON read/write in a `ScheduleLocalDataSource` class so it can be replaced later
  - Auto-save when schedule changes

### 4. Core Widgets Development

- [ ] **4.1** Create `DateHeader` widget
  - Display current date in "DD - MM - YYYY" format
  - Make it tappable to open date picker (as shown in wireframe)
  - Include visual indication it's clickable
  - onTap → showDatePicker and call DateNotifier.goToDate()
- [ ] **4.2** Create `TaskBlock` widget
  - Display wavy icon/visualization on the left
  - Show time range "YY:YY - XX:XX" format
  - Display duration "X min"
  - Make it draggable for reordering
  - Add tap handler for editing
- [ ] **4.3** Create `ScheduleList` widget
  - Container for multiple TaskBlock widgets
  - Start with simple ReorderableListView for reordering (easy approach)
  - Handle empty state when no tasks scheduled
  - Add spacing between blocks (representing break time)
  - Optional: Add fancier drag-over gaps once comfortable with basics
- [ ] **4.4** Create `AddTaskButton` widget
  - Floating "+" button at bottom center
  - Open dialog/sheet to add new task

### 5. Main Screen Assembly

- [ ] **5.1** Create `MainScreen` widget structure
  - Combine DateHeader, ScheduleList, and AddTaskButton
  - Add navigation arrows (left/right) for day navigation
  - Implement responsive layout
- [ ] **5.2** Connect widgets to state providers
  - Use Riverpod to connect UI to state management
  - Implement proper loading and error states
- [ ] **5.3** Add navigation between days
  - Left arrow: go to previous day
  - Right arrow: go to next day
  - Update schedule list when date changes

### 6. Task Management Features

- [ ] **6.1** Implement "Add Task" dialog
  - Input field for task name
  - Time picker for start time (default: next available slot)
  - Duration picker (default: 60 minutes)
  - Save button that adds task to schedule
- [ ] **6.2** Implement task editing
  - Tap on TaskBlock opens edit dialog
  - Allow changing name, time, and duration
  - Include delete option
- [ ] **6.3** Implement drag & drop reordering
  - Allow dragging TaskBlocks to reorder using ReorderableListView
  - Wrap recalculation in setState/provider batch update and debounce it
  - Automatically recalculate start times based on new position
  - Maintain break time between tasks

### 7. Time Management Logic

- [ ] **7.1** Implement default scheduling algorithm
  - First task starts at 08:35
  - Default task length: 60 minutes
  - Default break between tasks: 5 minutes
  - Automatically calculate start times for new tasks
- [ ] **7.2** Add time conflict prevention
  - Prevent overlapping tasks
  - Suggest next available time slot
  - Start with simple visual indicator: If conflict, tint TaskBlock background red
  - Optional: Add more sophisticated visual cues later
- [ ] **7.3** Implement time formatting helpers
  - Convert minutes to HH:MM format
  - Handle 24-hour time display
  - Calculate and display duration properly

### 8. Persistence Implementation

- [ ] **8.1** Set up local data storage
  - Use SharedPreferences for initial implementation
  - Create service class for save/load operations
  - Implement JSON serialization for all models
- [ ] **8.2** Auto-save functionality
  - Save schedule changes automatically
  - Debounce save operations to avoid excessive writes
  - Implement didChangeAppLifecycleState to flush unsaved data on app pause/background
- [ ] **8.3** Data migration preparation _(Nice to have - do only if you enjoy geekery)_
  - Structure save format to allow future feature additions
  - Version your data format for future updates

### 9. UI Polish & User Experience

- [ ] **9.1** Add visual feedback for interactions
  - Highlight draggable items
  - Show drop zones during drag operations
  - Add loading indicators where appropriate
- [ ] **9.2** Implement proper styling
  - Use ColorScheme.fromSeed(...) defined in main.dart for consistent theming
  - Apply Material 3 design principles
  - Style all widgets with consistent spacing and alignment
  - Define typography scale for text elements
- [ ] **9.3** Add empty states and helpful messages
  - Show helpful message when no tasks are scheduled
  - Guide user on how to add first task
  - Clear visual hierarchy and readable text

### 10. Testing & Validation

- [ ] **10.1** Write unit tests for models
  - Test Task and Block model methods
  - Test time calculations and scheduling logic
  - Verify JSON serialization works correctly
- [ ] **10.2** Write widget tests for core components
  - Test TaskBlock widget behavior
  - Test ScheduleList drag & drop
  - Test AddTaskButton dialog flow
- [ ] **10.3** Integration testing
  - Test complete add task flow
  - Test day navigation
  - Test persistence (save/load schedule)

### 11. Final Integration & Bug Fixes

- [ ] **11.1** End-to-end testing of main screen
  - Test all user interactions work correctly
  - Verify data persists between app restarts
  - Check performance with multiple tasks
- [ ] **11.2** Handle edge cases
  - Very long task names
  - Tasks spanning midnight
  - Multiple tasks in quick succession
- [ ] **11.3** Performance optimization
  - Optimize rebuild frequency
  - Ensure smooth scrolling and animations
  - Memory usage optimization

## Success Criteria

After completing all tasks, you should have:

- ✅ A fully functional main screen matching the wireframe
- ✅ Ability to add, edit, and reorder tasks for any day
- ✅ Persistent storage that survives app restarts
- ✅ Smooth navigation between days
- ✅ Default scheduling that follows the specified rules (8:35 start, 1hr tasks, 5min breaks)
- ✅ Intuitive drag & drop interface
- ✅ Proper time formatting and conflict prevention

## Notes for Learning Flutter

- Start with tasks 1-3 to understand Flutter project structure and Dart models
- Tasks 4-5 will teach you widget composition and layout
- Tasks 6-7 focus on user interaction and business logic
- Tasks 8-9 cover data persistence and UI polish
- Tasks 10-11 introduce testing and debugging practices

Each task is designed to be a complete, testable unit that builds toward the final main screen functionality.

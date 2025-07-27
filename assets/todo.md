# Flutter S- [x] **1.2** Set up code generation for Riverpod and Drift

- Add build_runner to dev_dependencies
- Add drift_dev to dev_dependencies for Drift code generation
- Configure build.yaml if neededdule App - Main Screen Development Tasks

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

### 2. Data Models Implementation (Using Drift)

- [x] **2.1** Create `Task` table in Drift
  - Define table: id (primary key), name, estimatedMinutes, projectId (nullable)
  - Create corresponding `.drift` file with proper column definitions
  - Run code generation to create Dart classes
- [x] **2.2** Create `Block` table in Drift (represents a time slot)
  - Define table: id (primary key), taskId (foreign key), dayLocal, startMinuteOfDay, lengthMinutes
  - Add proper column types and constraints
  - Run code generation to create Dart classes
- [x] **2.3** Create `Settings` table in Drift
  - Define table for user preferences: defaultStartTime, defaultTaskLength, defaultBreakTime
  - Include id field and proper column types
  - Run code generation to create Dart classes
- [x] **2.4** Set up Drift database class
  - Create main database class extending \_$AppDatabase
  - Include all tables and define database version
  - Add time calculation helper methods as database extensions

### 3. State Management Setup

- [ ] **3.1** Create `ScheduleNotifier` using Riverpod
  - Manage current selected date
  - Manage list of blocks for the current day (using Drift queries)
  - Implement methods: addTask, removeTask, reorderTasks (with proper batching)
- [ ] **3.2** Create `DateNotifier` for current day navigation
  - Track currently viewed date
  - Methods: nextDay, previousDay, goToDate
- [ ] **3.3** Create `SettingsNotifier` using Drift
  - Manage user preferences from Settings table
  - Load/save defaultStartTime, defaultTaskLength, defaultBreakTime
  - Automatically persist changes to database
- [ ] **3.4** Create database provider for Drift
  - Set up Riverpod provider for the Drift database instance
  - Ensure single database instance across the app
  - Handle database initialization and connection

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

### 8. Persistence Implementation (Using Drift)

- [ ] **8.1** Set up Drift database implementation
  - Configure database file location and connection
  - Implement proper database initialization
  - Add error handling for database operations
- [ ] **8.2** Auto-save functionality
  - Leverage Drift's automatic persistence (no manual save needed)
  - Add transaction support for batch operations
  - Implement didChangeAppLifecycleState for connection management
- [ ] **8.3** Database migrations _(Built-in with Drift)_
  - Set up schema versioning in Drift database class
  - Add migration strategies for future schema changes
  - Test migration scenarios

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

- [ ] **10.1** Write unit tests for Drift models and database operations
  - Test database table operations (insert, update, delete, query)
  - Test time calculations and scheduling logic
  - Test database transactions and error handling
- [ ] **10.2** Write widget tests for core components
  - Test TaskBlock widget behavior
  - Test ScheduleList drag & drop
  - Test AddTaskButton dialog flow
- [ ] **10.3** Integration testing
  - Test complete add task flow with database persistence
  - Test day navigation with database queries
  - Test database operations with UI interactions

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

## Success Criteria

After completing all tasks, you should have:

- ✅ A fully functional main screen matching the wireframe
- ✅ Ability to add, edit, and reorder tasks for any day
- ✅ Robust database persistence using Drift (better than simple file storage)
- ✅ Smooth navigation between days
- ✅ Default scheduling that follows the specified rules (8:35 start, 1hr tasks, 5min breaks)
- ✅ Intuitive drag & drop interface
- ✅ Proper time formatting and conflict prevention

## Notes for Learning Flutter

- Start with tasks 1-3 to understand Flutter project structure, Drift database setup, and Dart models
- Tasks 4-5 will teach you widget composition and layout
- Tasks 6-7 focus on user interaction and business logic
- Tasks 8-9 cover Drift database operations and UI polish
- Tasks 10-11 introduce testing practices with database integration

Each task is designed to be a complete, testable unit that builds toward the final main screen functionality using modern Flutter and Drift best practices.

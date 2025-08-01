# Flutter Schedule App - Projects Feature Implementation

## Phase 2: Projects Feature Implementation

Based on the existing main screen implementation, here are the tasks to add a projects feature to your scheduling app. This will allow users to organize tasks under projects with deadlines and provide a dedicated projects management screen.

### 1. Database Schema Extension

- [ ] **1.1** Create `Project` table in Drift
  - Define table: id (primary key), name, startDate, deadline, createdAt
  - Add proper column definitions with constraints
  - Set up foreign key relationship for Task.projectId → Project.id
  - Run code generation to create Dart classes
- [ ] **1.2** Update database schema version and migration
  - Increment schemaVersion in AppDatabase
  - Add migration logic to create Project table
  - Handle existing data (tasks without projects)
  - Test migration on existing database
- [ ] **1.3** Extend database with project-related queries
  - Add method to get all projects
  - Add method to get projects with task counts
  - Add method to get tasks for a specific project
  - Add methods for CRUD operations on projects

### 2. Data Models Enhancement

- [ ] **2.1** Create Project model extensions
  - Add ProjectWithStats class (project + task count, completion percentage)
  - Create helper methods for date calculations
  - Add validation methods for project names and deadlines
- [ ] **2.2** Update Task model relationships
  - Ensure Task.projectId properly references Project table
  - Add helper methods to get project information for tasks
  - Update existing task creation to handle optional project assignment
- [ ] **2.3** Create combined data models
  - TaskWithProject class for displaying tasks with project context
  - ProjectSummary class for project cards display

### 3. State Management for Projects

- [ ] **3.1** Create `ProjectsNotifier` using Riverpod
  - Manage list of all projects with statistics
  - Implement methods: addProject, editProject, deleteProject
  - Handle loading states and error handling
  - Use Drift streams for reactive updates
- [ ] **3.2** Update existing notifiers to support projects
  - Modify ScheduleNotifier to handle project context
  - Update task creation/editing to include project selection
  - Ensure proper cleanup when projects are deleted
- [ ] **3.3** Create project-specific providers
  - Provider for getting tasks by project ID
  - Provider for project statistics (task count, completion %)
  - Provider for project deadline warnings

### 4. Projects Screen Implementation

- [ ] **4.1** Create `ProjectsScreen` widget
  - Implement app bar with title "Projects"
  - Add search/filter functionality for projects
  - Handle empty state when no projects exist
  - Implement proper scrolling and layout
- [ ] **4.2** Create `ProjectCard` widget
  - Display project name prominently
  - Show start date and deadline with visual indicators
  - Display task count and completion percentage
  - Add visual deadline warning (red for overdue, orange for soon)
  - Make card tappable with proper visual feedback
- [ ] **4.3** Create `AddProjectButton` widget
  - Floating action button for adding new projects
  - Open project creation dialog/sheet
  - Consistent styling with existing UI patterns
- [ ] **4.4** Implement project cards grid/list layout
  - Use responsive layout (GridView.builder or ListView)
  - Add proper spacing and margins
  - Handle different screen sizes appropriately

### 5. Project Management Dialogs

- [ ] **5.1** Create `AddProjectDialog` widget
  - Input field for project name with validation
  - Date picker for deadline (required)
  - Optional start date picker (defaults to today)
  - Save button with loading state
  - Proper error handling and validation messages
- [ ] **5.2** Create `EditProjectDialog` widget (Future Task)
  - Pre-populate fields with existing project data
  - Allow editing name and deadline
  - Include delete project option with confirmation
  - Handle tasks reassignment when project is deleted
- [ ] **5.3** Add project selection to task creation
  - Modify existing AddTaskDialog to include project dropdown
  - Allow "No Project" option
  - Update task editing to support project changes

### 6. Navigation and Routing

- [ ] **6.1** Set up navigation structure
  - Update main.dart to support multiple screens
  - Implement basic routing between MainScreen and ProjectsScreen
  - Add navigation methods to switch between screens
- [ ] **6.2** Add navigation UI elements
  - Add "Projects" button/tab to MainScreen
  - Ensure back navigation works properly
  - Consider using bottom navigation or drawer for future expansion
- [ ] **6.3** Handle project card tap (placeholder)
  - Add onTap handler to ProjectCard
  - For now, just show a snackbar/toast "Coming Soon: Project Details"
  - Prepare for future project details screen implementation

### 7. UI Integration and Polish

- [ ] **7.1** Update main screen to show project context
  - Display project names in task blocks (if assigned)
  - Add visual indicators for project-related tasks
  - Maintain existing functionality while adding project info
- [ ] **7.2** Implement project-based task filtering (optional)
  - Add filter option to show tasks for specific projects only
  - Consider adding this as a future enhancement
- [ ] **7.3** Add project statistics and visual indicators
  - Show overdue projects with warning colors
  - Display progress indicators on project cards
  - Add deadline countdown for urgent projects

### 8. Database Operations and Performance

- [ ] **8.1** Optimize database queries for projects
  - Ensure efficient joins between Project and Task tables
  - Add appropriate database indexes
  - Test performance with larger datasets
- [ ] **8.2** Implement proper transaction handling
  - Use database transactions for complex operations
  - Handle concurrent access to project data
  - Ensure data consistency during project operations
- [ ] **8.3** Add data validation and constraints
  - Validate project names (non-empty, reasonable length)
  - Ensure deadlines are in the future for new projects
  - Handle edge cases (project deletion with tasks, etc.)

### 9. Testing and Error Handling

- [ ] **9.1** Add error handling for project operations
  - Handle database errors gracefully
  - Show user-friendly error messages
  - Implement retry mechanisms where appropriate
- [ ] **9.2** Test project creation and management
  - Test creating projects with various dates
  - Test project cards display and interaction
  - Test navigation between screens
- [ ] **9.3** Test edge cases
  - Test with no projects
  - Test with many projects
  - Test deadline validation and warnings

## Success Criteria

After completing all tasks, you should have:

- ✅ A fully functional projects screen with project cards
- ✅ Ability to create and view projects with deadlines
- ✅ Database schema properly extended with Project table
- ✅ Navigation between main schedule screen and projects screen
- ✅ Project cards that are clickable (with placeholder functionality)
- ✅ Visual indicators for project deadlines and status
- ✅ Robust database persistence for projects using Drift
- ✅ Proper state management using Riverpod for projects
- ✅ Clean architecture maintaining existing code patterns
- ✅ Error handling and validation for project operations

## Future Enhancements (Not in Current Scope)

- Project details screen with task management
- Project statistics and analytics
- Project archiving functionality
- Advanced filtering and search
- Project templates
- Task assignment from projects screen
- Project-based time tracking
- Export/import project data

## Notes for Implementation

- Start with database schema (tasks 1-2) to establish foundation
- Follow existing patterns from main screen implementation
- Use same state management patterns (Riverpod + Drift)
- Maintain consistent UI styling with existing screens
- Test each feature incrementally as you build
- Focus on core functionality first, polish later

Each task builds on the previous ones and follows the established patterns in your codebase. The implementation maintains the clean architecture you've already established while adding the projects functionality systematically.

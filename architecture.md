## 📝 Proposed Architecture

This proposes a **lean, feature-first clean architecture** adapted for Flutter and FRB (flutter_rust_bridge).  
It keeps **UI clean**, **providers lightweight**, and isolates FRB calls in the data layer.
Each folder has a clear responsibility:

```
lib/
├── config/
│   ├── providers/     # global app providers (not tied to UI)
│   ├── extensions/
│   ├── theme/         # app_theme.dart, colors.dart..
│   └── constants/     # app-wide constants (keys, regex, etc.)
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── [feature]_remote.dart           # wraps FRB APIs/methods
│       │   └── repositories/
│       │       └── [feature]_repository_impl.dart  # implements [feature]_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── [feature]_entity.dart           # data model
│       │   └── repositories/
│       │       └── [feature]_repository.dart       # abstract repository interface
│       └── presentation/
│           ├── controllers/
│           │   └── [feature]_controller.dart       # business logic
│           ├── providers/
│           │   ├── [feature]_provider.dart         # state management
│           │   └── [feature]_state.dart
│           ├── screens/
│           │   └── [feature]_screen.dart           # screen UI
│           └── widgets/
│               └── [feature]_widget.dart           # locally reusable UI components
├── shared/
│   ├── widgets/      # globally reusable UI components
│   └── utils/        # globally reusable helpers (formatters, validators, etc.)
├── routes/
│   └── app_router.dart   # app navigation
└── main.dart
```

## 📂 lib/config
Holds all **global app setup** that is not tied to a single feature.

- **providers/** → Global providers for things like authentication, relay configuration, or environment state. These are not directly linked to UI changes but configure the app.  
- **extensions/** → Dart extension methods on core types (e.g., `StringX`, `DateX`, `BuildContextX`).  
- **theme/** → App-wide theming such as `app_theme.dart`, `colors.dart`, and `typography.dart`.  

Think of `config` as the **environment and wiring** of the app.

---

## 📂 lib/core
Contains only **foundational building blocks** of the app.  
It should remain **minimal and stable**.

- **constants/** → Global constants like storage keys, regex patterns, or environment values.  

`core` is the **skeleton** of the app — fundamental, but not feature-specific.

---

## 📂 lib/features
Each feature has its own self-contained folder with **data, domain, and presentation layers**.

### Data Layer
Responsible for low-level implementations.  

- **datasources/** → Wraps FRB-generated methods. Keeps Rust/FFI bindings isolated.  
- **repositories/** → Implements domain repository interfaces by using datasources.  

### Domain Layer
Pure Dart code. Defines the **business logic contracts** without depending on frameworks.  

- **entities/** → Core models (e.g., `Message`, `User`, `Relay`).  
- **repositories/** → Abstract repository interfaces used by controllers.  

### Presentation Layer
Responsible for UI and state management.  

- **controllers/** → Orchestrates business logic, coordinates repositories, and updates providers. Keeps providers lean.  
- **providers/** → Own state classes (`*_state.dart`) and expose state changes to the UI (e.g., Riverpod, Bloc).  
- **screens/** → Feature screens (e.g., `ChatScreen`).  
- **widgets/** → Feature-specific widgets (e.g., `MessageBubble`).  

---

## 📂 lib/shared
Contains **reusable code** that can be used across multiple features.  

- **widgets/** → Common UI components (e.g., buttons, loaders, dialogs).  
- **utils/** → Helpers such as formatters, validators, or date utilities.  

`shared` is the **toolbox** available to all features.

---

## 📂 lib/routes
Centralizes the **navigation logic** of the app.

- **app_router.dart** → Manages routes, navigation guards, and deep linking.  

---

## 📂 lib/main.dart
The **entry point** of the application.  
Sets up providers, runs the app, and wires the router + theme.

---

## 🎨 Design Principles

1. **Feature-first** → Each feature is self-contained with its data, domain, and presentation.  
2. **Controllers handle orchestration** → Complex logic lives in controllers, not providers.  
3. **Providers own state** → Providers manage and expose immutable state to the UI.  
4. **FRB isolation** → All Rust/FFI bindings are wrapped in datasources so the rest of the app is unaware of low-level details.  
5. **Minimal core** → Only constants live here; no bloated utils or network layers.  
6. **Shared and Config separation** →  
   - `shared/` = reusable widgets and utilities.  
   - `config/` = global setup (providers, extensions, theme).  

---

This structure ensures:
- Clear separation of concerns.  
- Maintainable and testable code.  
- A scalable foundation for adding new features.  

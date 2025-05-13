# Baby Whistance App (Name TBD)

A Flutter application for family and friends to guess the details of the new baby and share in the journey.

## Project Plan

### Core Setup 🟨
- [✅] Flutter Project Initialization
- [✅] Firebase Project Setup & Integration (Auth, Firestore, Storage)
- [✅] Basic Project Structure (folders for screens, widgets, services, models)
- [✅] Git Repository Initialization
- [✅] Basic App Navigation (e.g., using GoRouter or Navigator 2.0) - Decided on GoRouter
- [✅] Layout Component / Theme Setup

### Authentication (Firebase) 🟨
- [✅] Email/Password Sign-up
- [✅] Email Verification
  - [✅] Send verification email on signup
  - [✅] Screen/flow to inform user to check email and verify
  - [✅] Protect routes/features based on email verification status
- [✅] Login (Email/Password)
- [✅] Logout
- [✅] Global Auth State Management (e.g., Provider, Riverpod, BLoC) - Implemented with Riverpod
- [✅] Protected Routes (redirect unauthenticated users) - Implemented with GoRouter and Riverpod
- [✅] User Profile Creation in Firestore (store UID, email, role, display name)
- [✅] Role-Based Access Control (RBAC)
    - [✅] Define Roles: `user`, `admin`, `Whistance`
    - [✅] Assign Roles (manual for now, or part of an invite system later)
    - [✅] Firestore Security Rules for Role-Based Data Access
    - [✅] Conditional UI elements based on role (via appUserProvider)
- [✅] Password Reset
- [ ] Testing for Auth Logic

### User Features (Home Page / Main User Flow) ⬜
- [ ] **Guess Submission**
    - [ ] Data Model for Guesses (user_id, date_of_birth_guess, time_of_birth_guess, weight_guess, length_guess, hair_color_guess, eye_color_guess, etc.)
    - [ ] UI Form for Submitting Guesses
    - [ ] Save Guesses to Firestore
    - [ ] Display User's Current Guess(es)
- [ ] **Guess Editing**
    - [ ] Allow users to edit their own guesses
    - [ ] Editing disabled if `guessing_status` is "closed"
- [ ] **View Other Users' Guesses (Post-Reveal)**
    - [ ] Conditionally display all guesses after an admin reveals the actual details.
- [ ] **View Baby Details (Post-Reveal)**
    - [ ] Display actual baby details once entered by an Admin/Whistance.

### "Whistance" Role Features (Mom & Dad) ⬜
- [ ] **Photo Journey Upload**
    - [ ] UI for uploading images (e.g., pregnancy journey, ultrasound pics)
    - [ ] Store images in Firebase Storage
    - [ ] Link images to a "journey" collection in Firestore (caption, uploader, timestamp)
- [ ] **Photo Journey Display**
    - [ ] Cute and engaging way to display uploaded photos (e.g., gallery, timeline, slideshow)
    - [ ] Accessible to all authenticated users.
- [ ] **(Potentially) Enter Actual Baby Details**
    - [ ] Form to input the actual birth details once the baby arrives.

### Admin Features ⬜
- [ ] **User Management (Basic)**
    - [ ] View list of users
    - [ ] Manually assign/change user roles (if not using an invite system with pre-assigned roles)
- [ ] **Guessing Management**
    - [ ] Set `guessing_status` (e.g., "open", "closed", "revealed")
        - [ ] When "closed", users can no longer submit/edit guesses.
        - [ ] When "revealed", actual details are shown, and perhaps all guesses.
    - [ ] Input Actual Baby Details (if not handled by "Whistance" role)
    - [ ] (Optional) Trigger calculation of "winners" or closest guesses.
- [ ] **Content Management (Photos)**
    - [ ] Ability to moderate/delete uploaded photos if necessary.

### UI/UX ⬜
- [ ] Basic Responsive Layout for Web (and mobile if also targeting native)
- [ ] Consistent Theme and Styling
- [ ] User-Friendly Navigation
- [ ] Loading States and Feedback
- [ ] Error Handling and User Notifications


### Security
- [ ] Make sure everything is secure and safe
- [ ] Never actually complete as long as the app is deployed

### Backend (Firebase) ⬜
- [ ] **Firestore Data Models:**
    - [ ] `users` (uid, email, displayName, role, createdAt)
    - [ ] `guesses` (userId, submittedAt, lastEditedAt, dateGuess, timeGuess, weightGuess, lengthGuess, hairColorGuess, eyeColorGuess)
    - [ ] `photos` (uploaderId, imageUrl, caption, uploadedAt, sortOrder)
    - [ ] `app_status` (or similar, for `guessing_status`, `actual_baby_details`)
- [ ] **Firebase Storage:**
    - [ ] Rules for photo uploads (only authenticated users, size limits, etc.)
- [ ] **Firebase Authentication:**
    - [ ] Standard email/password setup.
    - [ ] Email verification enforcement.
- [ ] **Firestore Security Rules:**
    - [ ] Users can only read/write their own guesses (unless `guessing_status` is "revealed").
    - [ ] "Whistance" role can upload photos.
    - [ ] "Admin" role can manage users and `app_status`.
    - [ ] All authenticated users can read photos.

### Future Features / Ideas ⬜
- [ ] Games
- [ ] User Invites System
- [ ] Notifications (e.g., when guessing closes, when baby details are revealed)
- [ ] "Closest Guess" Highlighting / Leaderboard
- [ ] More detailed user profiles
- [ ] PWA Capabilities
- [ ] Admin dashboard enhancements

## Known Issues / Next Steps
- **P1: Investigate `LoginScreen` unmounting during login process:**
  - **Symptom:** After a successful authentication call, `LoginScreen._login()` finds `!mounted` is true before it can execute its explicit navigation (`context.goNamed`).
  - **Current State:** Login flow *is functional* because `GoRouter` correctly redirects to `/home` after `AuthController` updates its state.
  - **Concern:** The `LoginScreen` becoming unmounted prematurely is a code smell and could indicate instability or lead to other subtle bugs (e.g., if `_isLoading` isn't reset correctly in all paths, though the current `finally` block handles this).
  - **Possible Causes to Investigate:**
    - Unintentional/automatic hot restarts (IDE settings, other tools).
    - Parent widget rebuilding and replacing `LoginScreen` due to auth state changes.
    - Aggressive/premature navigation or widget replacement by GoRouter itself during the auth flow.
    - Deeper Flutter framework issue or subtle bug related to `async/await` and widget lifecycle.

## Project Structure

The project follows a feature-first directory structure to promote modularity and scalability.

```
lib/
├── main.dart                 # Main application entry point
├── firebase_options.dart     # Firebase configuration (auto-generated)
│
├── config/                   # App-wide configurations
│   └── router/
│       └── app_router.dart   # GoRouter configuration, defines all app routes
│
├── core/                     # Core utilities, constants, base classes, error handling
│   └── .gitkeep              # (e.g., utils/, constants/, exceptions/, di/)
│
├── shared/                   # Shared widgets, models, or services across features
│   ├── models/               # Shared data models
│   │   ├── app_user.dart     # User model for Firestore data
│   │   └── .gitkeep
│   ├── services/             # Shared application services
│   │   └── .gitkeep
│   └── widgets/              # Shared UI components
│       └── .gitkeep
│
└── features/                 # Contains all feature-specific modules
    ├── auth/                 # Authentication feature (login, signup, etc.)
    │   ├── application/      # Business logic (Riverpod Providers, Controllers)
    │   │   ├── auth_controller.dart
    │   │   ├── auth_controller.g.dart
    │   │   ├── auth_providers.dart
    │   │   └── auth_providers.g.dart
    │   ├── domain/           # Core business models and interfaces
    │   │   └── repositories/ # Abstract contracts for data operations (e.g., AuthRepository)
    │   ├── infrastructure/   # Data sources, repository implementations
    │   │   └── repositories/ # Concrete implementations of repositories (e.g., FirebaseAuthRepository)
    │   └── presentation/     # UI Layer
    │       ├── screens/      # Screen-level widgets (e.g., LoginScreen, SignupScreen)
    │       └── widgets/      # Reusable widgets specific to this feature - To be added
    │
    ├── home/                 # Home feature (main dashboard, etc.)
    │   └── presentation/
    │       └── screens/
    │           └── home_screen.dart
    │
    ├── admin/                # Admin-specific features
    │   └── presentation/
    │       └── screens/
    │           └── admin_screen.dart
    │
    ├── profile/              # User profile feature
    │   └── presentation/
    │       └── screens/
    │           └── profile_screen.dart
    │
    ├── upload/               # Photo upload feature
    │   └── presentation/
    │       └── screens/
    │           └── upload_photo_screen.dart
    │
    └── # (other features as they are developed) ...
```

**Brief Description:**

*   **`main.dart`**: Initializes the app, Firebase, and sets up `MaterialApp.router` with the `appRouter`.
*   **`config/`**: Contains global application configuration.
    *   `router/app_router.dart`: Manages all navigation logic using `GoRouter`, defining routes and their corresponding screens.
*   **`core/`**: Houses fundamental utilities, global constants, base classes, error handling mechanisms, and potentially dependency injection setup. This code is foundational and used across the entire application.
*   **`shared/`**: Contains elements that are reusable across multiple features but are not as foundational as those in `core/`.
    *   `models/`: For data models that don't strictly belong to a single feature and are used by several (e.g., `AppUser`).
    *   `services/`: For application-level services that might be consumed by various features (e.g., a global notification service).
    *   `widgets/`: For common UI components (e.g., custom buttons, dialogs, list items) that are used in multiple feature modules. **Note:** Actively look for opportunities to extract reusable components from individual feature pages into this directory to maintain consistency and reduce code duplication.
*   **`features/`**: Each subdirectory within `features/` represents a distinct functional module of the application (e.g., `auth`, `home`).
    *   **`application/`**: Contains the business logic for the feature, such as state management (Riverpod Providers like `authControllerProvider` and `authRepositoryProvider`, Notifiers like `AuthController`), use cases, or application services.
    *   **`domain/`** (Conceptual - To be added as needed): Includes the core business logic, entities, and interfaces (abstract repositories) for the feature, independent of any framework or infrastructure.
        *   `repositories/`: Abstract contracts defining data operations (e.g., `AuthRepository`).
    *   **`infrastructure/`** (Conceptual - To be added as needed): Implements the interfaces defined in the `domain` layer, handling external concerns like data fetching (repositories), device services, etc.
        *   `repositories/`: Concrete implementations of repository interfaces (e.g., `FirebaseAuthRepository`).
    *   **`presentation/`**: Holds all UI-related code for the feature.
        *   `screens/`: Contains the top-level widgets that represent full screens or pages.
        *   `widgets/`: Contains smaller, reusable UI components specific to this feature.

*Global directories like `lib/models/`, `lib/widgets/`, `lib/services/` can be created if there's a need for truly shared components or utilities not specific to any single feature.*

## Development Setup

1.  Ensure Flutter is installed: [Flutter Docs](https://docs.flutter.dev/get-started/install)
2.  Clone the repository (if applicable).
3.  Configure Firebase:
    *   Create a Firebase project.
    *   Set up a web app in your Firebase project.
    *   Enable Authentication (Email/Password, Email Verification), Firestore Database, and Storage.
    *   Add your Firebase project configuration to the Flutter app (e.g., via `firebase_options.dart` after running `flutterfire configure`).
4.  Get dependencies:
    ```bash
    flutter pub get
    ```
5.  Run the app:
    ```bash
    flutter run -d chrome # For web
    ```

## Status Legend
- ✅ Complete
- 🟨 In Progress
- ⬜ Not Started

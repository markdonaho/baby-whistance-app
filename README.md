# Baby Whistance App (Name TBD)

## Next Development Focus (as of YYYY-MM-DD)

- **Implement Guess Submission Feature:**
    - Define Data Model for `guesses` (see Backend section for fields).
    - Create UI Form in `HomeScreen` (or a new dedicated screen) for submitting guesses.
    - Implement logic to save guesses to Firestore.
    - Display the user's current guess(es) on the `HomeScreen`.

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

### User Features (Home Page / Main User Flow) 🟨
- [🟨] **Guess Submission**
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

**Temporary Structure Change (for Debugging Auth):**
- All authentication logic (models, repositories, providers, controller) has been temporarily consolidated into `lib/features/auth/auth_service_consolidated.dart`. This is to simplify debugging of the authentication flow. This structure will be reverted once the underlying issues are resolved.

**Project Structure (Simplified for Debugging & Monolith Approach):**
- All screen files have been moved to a top-level `lib/screens/` directory.
- Feature-specific logic (other than auth, which is consolidated) has been temporarily streamlined or will be placed directly if simple enough.

```
lib/
├── config/
│   ├── router/
│   │   └── app_router.dart   # GoRouter configuration
│   └── theme/
│       └── app_theme.dart    # App theme
├── features/
│   └── auth/
│       ├── auth_service_consolidated.dart # CONSOLIDATED AUTH LOGIC
│       └── auth_service_consolidated.g.dart # Generated for consolidated service
├── firebase_options.dart     # Firebase configuration (auto-generated)
├── main.dart                 # Main application entry point
├── screens/                  # ALL UI Screens
│   ├── admin_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   ├── signup_screen.dart
│   ├── upload_photo_screen.dart
│   └── verify_email_screen.dart
└── shared/
    └── widgets/
        └── app_scaffold.dart # Shared scaffold widget
```

**Brief Description (Updated):**

*   **`main.dart`**: Initializes the app, Firebase, and sets up `MaterialApp.router` with the `appRouter`.
*   **`config/`**: Contains global application configuration.
    *   `router/app_router.dart`: Manages all navigation logic using `GoRouter`, defining routes and their corresponding screens (now located in `lib/screens/`).
    *   `theme/app_theme.dart`: Defines the application's visual theme.
*   **`features/auth/`**: Contains the consolidated authentication logic.
    *   `auth_service_consolidated.dart`: (Temporary) All auth logic (model, repository, providers, controller).
*   **`screens/`**: Contains all the UI screen files for the application.
*   **`shared/widgets/`**: For common UI components (e.g., `AppScaffold`) used across multiple screens.

*Further consolidation of other features will follow as needed.*

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

# Baby Whistance App (Name TBD)

## Next Development Focus (as of 2025-05-15)
- [ ] **Investigate Guess Submission Issue for 'user' Role:** Users with the 'user' role are reportedly unable to submit guesses even when `guessing_status` is "open". Diagnose and resolve the root cause (client-side validation, auth state, form population, or other).
remaining stuff:

    - [ ] **Implement Feedback Mechanism (Dev Area):**
        - [ ] Create `feedback` collection in Firestore with appropriate fields (userId, timestamp, feedbackText, etc.).
        - [ ] Define Firestore security rules for the `feedback` collection (allow authenticated create, admin/Whistance manage).
        - [ ] Implement UI in `DevAreaScreen` for submitting and viewing feedback (role-dependent).
- [ ] Boy color themes
- [ ] Games
- [ ] "Closest Guess" Highlighting / Leaderboard
- [ ] ****


A Flutter application for family and friends to guess the details of the new baby and share in the journey.

## Project Plan

### Core Setup ✅
- [✅] Flutter Project Initialization
- [✅] Firebase Project Setup & Integration (Auth, Firestore, Storage)
  - [✅] Firestore data structure for `guesses` refactored to top-level collection.
  - [✅] Firestore security rules updated for top-level `guesses` collection.
- [✅] Basic Project Structure (folders for screens, widgets, services, models)
- [✅] Git Repository Initialization
- [✅] Basic App Navigation (e.g., using GoRouter or Navigator 2.0) - Decided on GoRouter
- [✅] Layout Component / Theme Setup (Includes `AppScaffold` and `AppBottomNavBar`)

### Authentication (Firebase) ✅
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

### User Features (Home Page / Main User Flow) ✅
- [✅] **Guess Submission & Editing (Single Guess per User)**
    - [✅] Data Model for Guesses (Fixed date, fields for time, weight (lbs/oz), length (inches), hair/eye color, looks like, Brycen reaction)
    - [✅] UI Form for Submitting/Editing Guesses (`GuessSubmissionEditScreen`):
        - [✅] Populates with existing guess data for editing.
        - [✅] Handles both new guess submission and updates to existing guess.
        - [✅] Fixed bug with time format preventing guess submission.
        - [✅] Navigates back to `AllGuessesScreen` after successful edit.
    - [✅] Save/Update Guesses to Firestore (top-level `guesses` collection).
    - [✅] Display User's Current Guess on `GuessSubmissionEditScreen`.
    - [✅] Add AM/PM to diplay of time in my guess and all guesses
- [✅] **Display All Guesses (`AllGuessesScreen`)**
    - [✅] Data providers created to fetch all guesses (`allGuessesStreamProvider`).
    - [✅] Basic `AllGuessesScreen` widget created.
- [✅] **View Baby Details (Post-Reveal)**
    - [✅] Display actual baby details once entered by an Admin/Whistance.

### Admin Features 🟨
- [✅] **User Management (Basic)**
    - [✅] View list of users
    - [✅] Manually assign/change user roles (if not using an invite system with pre-assigned roles)
- [✅] **Guessing Management**
    - [✅] Set `guessing_status` (e.g., "open", "closed", "revealed")
        - [✅] When "closed", users can no longer submit/edit guesses.
        - [✅] When "revealed", actual details are shown, and perhaps all guesses.
    - [✅] Input Actual Baby Details (if not handled by "Whistance" role)
    - [ ] (Optional) Trigger calculation of "winners" or closest guesses.
    - [✅] Conditionally disable editing based on `guessing_status` (admin feature).

### UI/UX ✅
- [✅] Basic Responsive Layout for Web (and mobile if also targeting native) - Using `AppScaffold`
- [✅] Consistent Theme and Styling - Using `AppScaffold`
- [✅] User-Friendly Navigation - Implemented `AppBottomNavBar`
- [✅] Loading States and Feedback
- [✅] Error Handling and User Notifications


### Security
- [✅] Firestore Security Rules updated for top-level `guesses` collection.
- [🟨] Make sure everything is secure and safe
    - Never actually complete as long as the app is deployed, but good for now.

### Backend (Firebase) ✅
- [✅] **Firestore Data Models:**
    - [✅] `users` (uid, email, displayName, role, createdAt)
    - [✅] `guesses` (userId, submittedAt, lastEditedAt (consider adding), dateGuess, timeGuess, weightGuess, lengthGuess, hairColorGuess, eyeColorGuess, looksLikeGuess, brycenReactionGuess, id) - Stored in top-level collection.
    - [✅] `app_status` (or similar, for `guessing_status`, `actual_baby_details`)
- [✅] **Firebase Storage:**
    - [✅] Rules for photo uploads (only authenticated users, size limits, etc.) - Addressed by locking down storage after feature removal.
- [✅] **Firebase Authentication:**
    - [✅] Standard email/password setup.
    - [✅] Email verification enforcement.
- [✅] **Firestore Security Rules:** (Updated for `guesses` collection, `users`, and `app_status`)
    - [✅] Users can only create/update/delete their own guesses.
    - [✅] All authenticated users can read all guesses.
    - [✅] "Admin" role can manage users and `app_status`.

### Future Features / Ideas ⬜
- [ ] Games
- [x] User Invites System
- [x] Notifications (e.g., when guessing closes, when baby details are revealed)
- [ ] "Closest Guess" Highlighting / Leaderboard
- [x] More detailed user profiles
- [ ] PWA Capabilities
- [ ] Dev area, rules and whatnot
- [ ] Boy color themes

### Known Issues(Ignore unless user EXPLICITLY ASKS ABOUT IT)
- **P1: Investigate `LoginScreen` unmounting during login process:**
  - **Symptom:** After a successful authentication call, `LoginScreen._login()` finds `!mounted` is true before it can execute its explicit navigation (`context.goNamed`).
  - **Current State:** Login flow *is functional* because `GoRouter` correctly redirects to `/home` after `AuthController` updates its state.
  - **Concern:** The `LoginScreen` becoming unmounted prematurely is a code smell and could indicate instability or lead to other subtle bugs (e.g., if `_isLoading` isn't reset correctly in all paths, though the current `finally`
    block in `LoginScreen._login()` seems to handle it for now).

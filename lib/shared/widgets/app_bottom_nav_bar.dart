import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart'; // For AppUserRole and appUserStreamProvider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final appUser = ref.watch(appUserStreamProvider).asData?.value;

    final List<BottomNavigationBarItem> navBarItems = [];
    final List<AppRoute> navBarRoutes = [];

    // Determine roles
    bool isAdmin = appUser?.role == AppUserRole.admin;
    bool isWhistance = appUser?.role == AppUserRole.whistance;

    // Always add Home/All Guesses and My Guess
    navBarItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt), // Changed to list_alt for "All Guesses"
        label: 'All Guesses',
      ),
    );
    navBarRoutes.add(AppRoute.allGuesses);

    navBarItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.edit_document),
        label: 'My Guess',
      ),
    );
    navBarRoutes.add(AppRoute.guessForm);

    // Conditional items based on role
    if (isAdmin) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
      navBarRoutes.add(AppRoute.admin);
    }
    if (isAdmin || isWhistance) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.developer_mode), 
          label: 'Dev Area',
        ),
      );
      navBarRoutes.add(AppRoute.devArea);
    }

    // // Profile is always available
    // navBarItems.add(
    //   const BottomNavigationBarItem(
    //     icon: Icon(Icons.person_outline), // Changed to person_outline
    //     label: 'Profile',
    //   ),
    // );
    // navBarRoutes.add(AppRoute.profile);

    int currentIndex = 0;
    // Order of checks matters for currentIndex determination based on typical usage flow
    if (currentLocation.startsWith(AppRoute.allGuesses.path)) { // Using .path for robustness
      currentIndex = navBarRoutes.indexOf(AppRoute.allGuesses);
    } else if (currentLocation.startsWith(AppRoute.guessForm.path)) {
      currentIndex = navBarRoutes.indexOf(AppRoute.guessForm);
    } else if (currentLocation.startsWith(AppRoute.profile.path)) {
      currentIndex = navBarRoutes.indexOf(AppRoute.profile);
    } else if (isAdmin && currentLocation.startsWith(AppRoute.admin.path)) {
      currentIndex = navBarRoutes.indexOf(AppRoute.admin);
    } else if ((isAdmin || isWhistance) && currentLocation.startsWith(AppRoute.devArea.path)) {
      currentIndex = navBarRoutes.indexOf(AppRoute.devArea);
    }
    
    // Ensure currentIndex is valid
    if (currentIndex < 0 || currentIndex >= navBarItems.length) {
      currentIndex = 0; // Default to first item if something went wrong
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index < 0 || index >= navBarRoutes.length) return; // Safety check

        final AppRoute selectedRoute = navBarRoutes[index];
        
        // Special handling for guessForm if it needs query parameters
        if (selectedRoute == AppRoute.guessForm) {
          // Example: if opening "My Guess" should always be in edit mode or pass user ID
          context.goNamed(AppRoute.guessForm.name, queryParameters: {'edit': 'true'});
        } else {
          context.goNamed(selectedRoute.name);
        }
      },
      items: navBarItems,
      type: BottomNavigationBarType.fixed, 
      // Consider adding selectedItemColor and unselectedItemColor from theme
      // selectedItemColor: Theme.of(context).colorScheme.primary,
      // unselectedItemColor: Colors.grey,
    );
  }
}

// Extension to get path from AppRoute for robust startsWith checks
extension AppRoutePath on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.login:
        return '/login';
      case AppRoute.signup:
        return '/signup';
      case AppRoute.verifyEmail:
        return '/verify-email';
      case AppRoute.guessForm:
        return '/guess-form';
      // case AppRoute.uploadPhoto: // Removed
      //   return '/upload-photo';
      case AppRoute.admin:
        return '/admin';
      case AppRoute.adminUserManagement:
        return '/admin/user-management';
      case AppRoute.adminEnterBabyDetails:
        return '/admin/enter-baby-details';
      case AppRoute.profile:
        return '/profile';
      case AppRoute.allGuesses:
        return '/all-guesses';
      case AppRoute.devArea:
        return '/dev-area';
      default:
        return '/'; // Should not happen
    }
  }
} 
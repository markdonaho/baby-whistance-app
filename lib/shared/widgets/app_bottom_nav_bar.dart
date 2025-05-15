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

    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.edit_document),
        label: 'My Guess',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt),
        label: 'All Guesses',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];

    final List<AppRoute> navBarRoutes = [
      AppRoute.guessForm,
      AppRoute.allGuesses,
      AppRoute.profile,
    ];

    bool isAdmin = appUser?.role == AppUserRole.admin;
    bool isWhistance = appUser?.role == AppUserRole.whistance;

    if (isAdmin || isWhistance) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.developer_mode),
          label: 'Dev Area',
        ),
      );
      navBarRoutes.add(AppRoute.devArea);
    }

    if (isAdmin) {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
      navBarRoutes.add(AppRoute.admin);
    }

    int currentIndex = 0;
    if (currentLocation.startsWith('/all-guesses')) {
      currentIndex = navBarRoutes.indexOf(AppRoute.allGuesses);
    } else if (currentLocation.startsWith('/profile')) {
      currentIndex = navBarRoutes.indexOf(AppRoute.profile);
    } else if (currentLocation.startsWith('/guess-form')) {
      currentIndex = navBarRoutes.indexOf(AppRoute.guessForm);
    } else if ((isAdmin || isWhistance) && currentLocation.startsWith('/dev-area')) {
      currentIndex = navBarRoutes.indexOf(AppRoute.devArea);
    } else if (isAdmin && currentLocation.startsWith('/admin')) {
      currentIndex = navBarRoutes.indexOf(AppRoute.admin);
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
        
        if (selectedRoute == AppRoute.guessForm) {
          context.goNamed(AppRoute.guessForm.name, queryParameters: {'edit': 'true'});
        } else {
          context.goNamed(selectedRoute.name);
        }
      },
      items: navBarItems,
      type: BottomNavigationBarType.fixed, // Use fixed type if more than 3 items potentially
      // Consider adding selectedItemColor and unselectedItemColor from theme
    );
  }
} 
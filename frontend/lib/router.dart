/// App Router Configuration with GoRouter
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/home/home_dashboard.dart';
import 'screens/library/my_library_screen.dart';
import 'screens/book/barcode_scanner_screen.dart';
import 'screens/book/book_detail_screen.dart';
import 'screens/book/add_edit_book_screen.dart';
import 'screens/book/key_takeaways_screen.dart';
import 'screens/review/review_hub_screen.dart';
import 'screens/review/session_summary_screen.dart';
import 'screens/flashcard/flashcard_session_screen.dart';
import 'screens/focus/focus_mode_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/notes/note_editor_screen.dart';
import 'screens/ocr/ocr_camera_screen.dart';
import 'screens/ocr/ocr_edit_screen.dart';
import 'screens/social/social_feed_screen.dart';
import 'screens/social/friend_profile_screen.dart';
import 'screens/social/find_friend_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';


class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      
      // Redirect logic based on auth state
      redirect: (context, state) {
        final authState = authBloc.state;
        final isOnAuthScreen = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';
        final isOnSplash = state.matchedLocation == '/splash';
        final isOnOnboarding = state.matchedLocation == '/onboarding';
        
        // Allow splash and onboarding
        if (isOnSplash || isOnOnboarding) return null;
        
        // First time user - show onboarding
        if (authState is AuthFirstTime) {
          return '/onboarding';
        }
        
        // Not authenticated - go to login
        if (authState is AuthUnauthenticated && !isOnAuthScreen) {
          return '/login';
        }
        
        // Authenticated - redirect away from auth screens
        if (authState is AuthAuthenticated && isOnAuthScreen) {
          return '/';
        }
        
        return null;
      },
      
      // Refresh when auth state changes
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Onboarding
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        
        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // Main App with Bottom Navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainWrapper(child: child),
          routes: [
            // Home Tab
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeDashboard(),
            ),
            
            // Library Tab
            GoRoute(
              path: '/library',
              builder: (context, state) => const MyLibraryScreen(),
            ),
            
            // Review Tab
            GoRoute(
              path: '/review',
              builder: (context, state) => const ReviewHubScreen(),
            ),
            
            // Profile Tab
            GoRoute(
              path: '/profile',
              builder: (context, state) => const UserProfileScreen(),
            ),
            
            // Social Tab (Trust Circle)
            GoRoute(
              path: '/social',
              builder: (context, state) => const SocialFeedScreen(),
            ),
          ],
        ),
        
        // Add Book (MUST be before /book/:id to avoid matching 'add' as ID)
        GoRoute(
          path: '/book/add',
          builder: (context, state) {
            final isbn = state.uri.queryParameters['isbn'];
            return AddEditBookScreen(isbn: isbn);
          },
        ),
        
        // Book Detail
        GoRoute(
          path: '/book/:id',
          builder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return BookDetailScreen(bookId: bookId);
          },
          routes: [
            GoRoute(
              path: 'notes',
              builder: (context, state) {
                final bookId = state.pathParameters['id']!;
                return NoteEditorScreen(bookId: bookId);
              },
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final bookId = state.pathParameters['id']!;
                return AddEditBookScreen(bookId: bookId);
              },
            ),
          ],
        ),
        
        // Barcode Scanner
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const BarcodeScannerScreen(),
        ),
        
        // Create/Edit Note
        GoRoute(
          path: '/note/create',
          builder: (context, state) {
            final bookId = state.uri.queryParameters['bookId'];
            return NoteEditorScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/note/:id',
          builder: (context, state) {
            final noteId = state.pathParameters['id']!;
            return NoteEditorScreen(noteId: noteId);
          },
        ),
        
        // OCR
        GoRoute(
          path: '/ocr',
          builder: (context, state) {
            final bookId = state.uri.queryParameters['bookId'];
            return OCRCameraScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/ocr/edit',
          builder: (context, state) {
            final imagePath = state.uri.queryParameters['image'];
            final bookId = state.uri.queryParameters['bookId'];
            return OCREditScreen(imagePath: imagePath, bookId: bookId);
          },
        ),
        
        // Flashcard Session
        GoRoute(
          path: '/flashcard/session',
          builder: (context, state) {
            final deckId = state.uri.queryParameters['deckId'];
            return FlashcardSessionScreen(deckId: deckId);
          },
        ),
        
        // Social - Moved to ShellRoute
        // GoRoute(
        //   path: '/social',
        //   builder: (context, state) => const SocialFeedScreen(),
        // ),
        GoRoute(
          path: '/friend/:id',
          builder: (context, state) {
            final friendId = state.pathParameters['id']!;
            return FriendProfileScreen(friendId: friendId);
          },
        ),
        
        GoRoute(
          path: '/find-friend',
          builder: (context, state) => const FindFriendScreen(),
        ),
        
        // Edit profile
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        
        // Settings
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        
        // Focus Mode
        GoRoute(
          path: '/focus',
          builder: (context, state) {
            final bookId = state.uri.queryParameters['bookId'];
            final bookTitle = state.uri.queryParameters['title'];
            return FocusModeScreen(bookId: bookId, bookTitle: bookTitle);
          },
        ),
        
        // Key Takeaways
        GoRoute(
          path: '/book/:id/takeaways',
          builder: (context, state) {
            final bookId = state.pathParameters['id']!;
            final bookTitle = state.uri.queryParameters['title'];
            return KeyTakeawaysScreen(bookId: bookId, bookTitle: bookTitle);
          },
        ),
        
        // Session Summary
        GoRoute(
          path: '/flashcard/summary',
          builder: (context, state) {
            final total = int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
            final correct = int.tryParse(state.uri.queryParameters['correct'] ?? '0') ?? 0;
            final incorrect = int.tryParse(state.uri.queryParameters['incorrect'] ?? '0') ?? 0;
            final time = int.tryParse(state.uri.queryParameters['time'] ?? '0') ?? 0;
            final deckName = state.uri.queryParameters['deck'];
            return SessionSummaryScreen(
              totalCards: total,
              correctCards: correct,
              incorrectCards: incorrect,
              timeSpentSeconds: time,
              deckName: deckName,
            );
          },
        ),
      ],
    );
  }
}

/// Stream helper for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}

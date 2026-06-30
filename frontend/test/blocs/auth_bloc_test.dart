import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tram_doc/blocs/auth/auth_bloc.dart';
import 'package:tram_doc/blocs/auth/auth_event.dart';
import 'package:tram_doc/blocs/auth/auth_state.dart';
import 'package:tram_doc/services/auth_service.dart';
import 'package:tram_doc/services/api_service.dart';
import 'package:tram_doc/models/user.dart';

class MockAuthService extends Mock implements AuthService {}
class MockApiService extends Mock implements ApiService {}

void main() {
  late AuthBloc authBloc;
  late MockAuthService mockAuthService;
  late MockApiService mockApiService;

  final mockUser = const User(
    id: '1',
    email: 'test@example.com',
    fullName: 'Test User',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    mockAuthService = MockAuthService();
    mockApiService = MockApiService();
    authBloc = AuthBloc(
      authService: mockAuthService,
      apiService: mockApiService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockAuthService.login('test@example.com', 'password123'))
            .thenAnswer((_) async => mockUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(mockUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthService.login('test@example.com', 'wrongpassword'))
            .thenThrow(Exception('Failed to login'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when logout succeeds',
      build: () {
        when(() => mockAuthService.logout()).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );
  });
}

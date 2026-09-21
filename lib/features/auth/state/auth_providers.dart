import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (Ref ref) => const TokenStorage(),
);

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (Ref ref) => ApiClient(),
);

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepository(
    client: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((Ref ref) {
  final AuthController controller =
      AuthController(ref.watch(authRepositoryProvider));

  // Istalgan so'rovda 401 kelsa sessiya tozalanadi — AppShell holat
  // o'zgarishini kuzatib, foydalanuvchini login oqimiga qaytaradi.
  ref.watch(apiClientProvider).onUnauthenticated = controller.sessionExpired;

  return controller;
});

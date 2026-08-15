import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

final sessionProvider = AsyncNotifierProvider<SessionNotifier, User?>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<User?> {
  Future<AuthRepository> _repository() async {
    final client = await ApiClient.create();
    return AuthRepository(client);
  }

  @override
  Future<User?> build() async {
    try {
      final repo = await _repository();
      return await repo.restoreSession();
    } catch (_) {
      return null;
    }
  }

  /// Authenticate and publish the session. Throws [ApiException] on failure
  /// without flipping the global session into a loading/error state, so the
  /// login form stays mounted.
  Future<void> login(String usr, String pwd) async {
    final repo = await _repository();
    final user = await repo.login(usr, pwd);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    try {
      final repo = await _repository();
      await repo.logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}

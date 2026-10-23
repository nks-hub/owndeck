import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';

final class MemoryVault implements CredentialVault {
  final values = <String, String>{};
  bool failDelete = false;
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async {
    values[reference] = password;
  }

  @override
  Future<void> delete(String reference) async {
    if (failDelete) throw StateError('vault_locked');
    values.remove(reference);
  }

  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

LoginCredentials credentials(
  String user, [
  String password = 'test-password',
]) => LoginCredentials(
  server: ServerBase.parse('https://cloud.example.com/nextcloud'),
  loginName: user,
  appPassword: password,
);

DeckBoard board(int id, String title, {bool edit = false}) =>
    DeckBoard.fromJson({
      'id': id,
      'title': title,
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': edit},
    });

import '../frb_generated.dart';
import 'accounts.dart';

/// Login with NIP-55 external signer
/// 
/// This method retrieves the public key from the external signer,
/// creates or finds the account, enables the NIP-55 signer, and sets up relays.
Future<Account> loginWithNip55() {
  return RustLib.instance.api.crateApiNip55LoginWithNip55();
}


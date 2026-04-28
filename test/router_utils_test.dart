import 'package:flutter_test/flutter_test.dart';
import 'package:coentrepreneurs/router_utils.dart';

class FakeAuth {
  bool signedIn;
  FakeAuth(this.signedIn);
  bool get isSignedIn => signedIn;
}

void main() {
  test('non connecté -> accès home redirige vers /login', () {
    final auth = FakeAuth(false);
    final redirect = computeRedirect(auth, '/home');
    expect(redirect, '/login');
  });

  test('non connecté -> accès login ne redirige pas', () {
    final auth = FakeAuth(false);
    final redirect = computeRedirect(auth, '/login');
    expect(redirect, null);
  });

  test('connecté -> accès login redirige vers /home', () {
    final auth = FakeAuth(true);
    final redirect = computeRedirect(auth, '/login');
    expect(redirect, '/home');
  });

  test('connecté -> accès home ne redirige pas', () {
    final auth = FakeAuth(true);
    final redirect = computeRedirect(auth, '/home');
    expect(redirect, null);
  });

  test('passwordRecovery -> redirige vers /reset-password', () {
    final auth = FakeAuth(true);
    final redirect = computeRedirect(auth, '/home', true);
    expect(redirect, '/reset-password');
  });
}

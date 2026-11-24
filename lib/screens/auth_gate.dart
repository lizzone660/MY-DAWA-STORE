import 'package:flutter/material.dart';
import '../services/auth_repository.dart';
import 'store_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthRepository();
  final _store = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _reportEmail = TextEditingController();
  final _opening = TextEditingController(text: '08:00');
  final _closing = TextEditingController(text: '20:00');
  bool _setup = false, _loading = true, _busy = false, _obscure = true;
  String _gender = 'unspecified';
  String? _error;

  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    try {
      final savedUser = await _auth.currentUser();
      if (savedUser != null && mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StoreShell(user: savedUser)));
        return;
      }
      final needed = await _auth.needsSetup();
      if (mounted) setState(() { _setup = needed; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }
  @override void dispose() {
    _store.dispose(); _name.dispose(); _email.dispose(); _password.dispose(); _reportEmail.dispose(); _opening.dispose(); _closing.dispose(); super.dispose();
  }
  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      if (_setup) {
        await _auth.createStore(storeName: _store.text, ownerName: _name.text, email: _email.text,
          password: _password.text, gender: _gender, reportEmail: _reportEmail.text,
          openingTime: _opening.text, closingTime: _closing.text);
      }
      final user = await _auth.signIn(_email.text, _password.text);
      if (user == null) throw StateError('Email or password is incorrect.');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StoreShell(user: user)));
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', '')); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.local_pharmacy_rounded, size: 52, color: Color(0xFFB69AFF)),
        const SizedBox(height: 12),
        const Text('MY DAWA STORE', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text(_setup ? 'Create your pharmacy workspace' : 'Secure local sign in', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9DA6C7))),
        const SizedBox(height: 24),
        if (_setup) ...[
          TextField(controller: _store, decoration: const InputDecoration(labelText: 'Pharmacy / store name', prefixIcon: Icon(Icons.store))),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Owner full name', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _gender, decoration: const InputDecoration(labelText: 'Owner profile'), items: const [
            DropdownMenuItem(value: 'unspecified', child: Text('Prefer not to say')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'multiple', child: Text('Multiple owners')),
          ], onChanged: (v) => setState(() => _gender = v ?? 'unspecified')),
          const SizedBox(height: 12),
          TextField(controller: _reportEmail, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Report email (optional)', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: TextField(controller: _opening, decoration: const InputDecoration(labelText: 'Opening (HH:mm)'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _closing, decoration: const InputDecoration(labelText: 'Closing (HH:mm)')))]),
          const SizedBox(height: 12),
        ],
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email))),
        const SizedBox(height: 12),
        TextField(controller: _password, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password (minimum 10 characters)', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off)))),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFFF7777)))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _busy ? null : _submit, child: Padding(padding: const EdgeInsets.all(12), child: Text(_busy ? 'PLEASE WAIT…' : _setup ? 'CREATE STORE & ADMIN' : 'SIGN IN'))),
        const SizedBox(height: 10),
        const Text('Your local records remain on this device when offline.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF8992B2))),
      ]))),
    ))));
  }
}

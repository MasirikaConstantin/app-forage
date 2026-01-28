import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_shell.dart';
import '../models/app_user.dart';
import '../widgets/app_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final payload = <String, dynamic>{
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://gestion.royalhouse-deboraa.com/api/v1/login'),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      final Map<String, dynamic>? dataMap =
          data is Map<String, dynamic> ? data : null;
      final success = dataMap != null && dataMap['success'] == true;

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && success) {
        final dataNode = dataMap['data'];
        final dataPayload =
            dataNode is Map<String, dynamic> ? dataNode : null;
        String? token;
        var tokenType = 'Bearer';
        if (dataPayload != null) {
          final tokenValue = dataPayload['token'];
          if (tokenValue != null) {
            token = tokenValue.toString();
          }
          final tokenTypeValue = dataPayload['token_type'];
          if (tokenTypeValue != null &&
              tokenTypeValue.toString().isNotEmpty) {
            tokenType = tokenTypeValue.toString();
          }
        }
        if (token != null && token.isNotEmpty) {
          final store = AppScope.of(context);
          await store.saveAuthToken(token: token, tokenType: tokenType);
          if (dataPayload != null) {
            final userNode = dataPayload['user'];
            if (userNode is Map<String, dynamic>) {
              final currentUser = AppUser.fromApi(userNode);
              await store.saveCurrentUser(currentUser);
            }
          }
          await Future.wait(<Future<dynamic>>[
            store.syncUsers(force: true),
            store.syncSubscribers(force: true),
          ]);
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(HomeShell.routeName);
        return;
      }

      debugPrint(
        'Login failed: status=${response.statusCode}, body=${response.body}',
      );
      final message = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? 'Connexion echouee.')
          : 'Connexion echouee.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error, stackTrace) {
      debugPrint('Login error: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + viewInsets.bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Gestion Forage',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connexion',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acces reserve a l equipe de gestion.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez votre email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Se connecter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

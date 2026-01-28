import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/app_scope.dart';

const List<String> _roles = <String>[
  'utilisateur',
  'admin',
  'visiteur',
];

String _roleLabel(String role) {
  if (role.isEmpty) return role;
  return role[0].toUpperCase() + role.substring(1);
}

Future<void> showUserFormDialog(BuildContext context, {AppUser? user}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => UserFormDialog(user: user),
  );
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});

  final AppUser? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  late String _role;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    final existingRole = widget.user?.role;
    _role = existingRole != null && _roles.contains(existingRole)
        ? existingRole
        : _roles.first;
    _active = widget.user?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final store = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    try {
      if (widget.user == null) {
        final password = _passwordController.text;
        final confirmation = _confirmController.text;
        await store.addUser(
          AppUser(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _role,
            active: _active,
            createdAt: now,
            password: password,
            passwordConfirmation: confirmation,
          ),
        );
      } else {
        await store.updateUser(
          widget.user!.copyWith(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _role,
            active: _active,
            createdAt: widget.user!.createdAt,
          ),
        );
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.user == null
                  ? 'Utilisateur ajoute'
                  : 'Utilisateur mis a jour',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.user == null ? 'Nouvel utilisateur' : 'Modifier utilisateur'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Telephone'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez un numero';
                  }
                    return null;
                  },
                ),
                if (widget.user == null) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entrez un mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer mot de passe',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Confirmez le mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  items: _roles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(_roleLabel(role)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.user == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
      surfaceTintColor: theme.colorScheme.surface,
    );
  }
}

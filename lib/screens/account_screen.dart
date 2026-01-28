import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/app_scope.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _uploading = false;
  bool _checked = false;
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        store.refreshCurrentUser().whenComplete(() {
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
        });
      });
    }

    if (_loading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (user == null) {
      return const Center(
        child: Text('Aucune information de compte.'),
      );
    }

    final avatarUrl = user.avatarUrl.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width >= 900 ? 820.0 : width;
        final avatarSize = width.clamp(140, 200).toDouble();
        var columns = 1;
        if (width >= 900) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  Center(
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                      ),
                      child: avatarUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                width: avatarSize,
                                height: avatarSize,
                              ),
                            )
                          : Center(
                              child: Text(
                                _initials(user),
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed:
                              _uploading ? null : () => _pickAvatar(context),
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.photo_camera_outlined),
                          label: const Text('Changer avatar'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openEdit(context, user),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier compte'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1
                        ? 3.8
                        : columns == 2
                            ? 3.2
                            : 2.8,
                    children: <Widget>[
                      _InfoTile(label: 'Nom', value: user.fullName),
                      _InfoTile(label: 'Email', value: user.email),
                      _InfoTile(label: 'Telephone', value: user.phone),
                      _InfoTile(label: 'Role', value: user.role),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final store = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _uploading = true;
    });
    try {
      await store.uploadCurrentUserAvatar(path);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Avatar mis a jour')),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors du telechargement')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  String _initials(AppUser user) {
    final trimmed = user.fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Future<void> _openEdit(BuildContext context, AppUser user) async {
    final updated = await showDialog<AppUser>(
      context: context,
      builder: (context) => _AccountEditDialog(user: user),
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte mis a jour')),
      );
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}

class _AccountEditDialog extends StatefulWidget {
  const _AccountEditDialog({required this.user});

  final AppUser user;

  @override
  State<_AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _active = true;
  String _role = 'utilisateur';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _active = widget.user.active;
    _role = widget.user.role.toLowerCase();
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
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    final updated = widget.user.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _role,
      active: _active,
      password: password.isEmpty ? null : password,
      passwordConfirmation: confirm.isEmpty ? null : confirm,
    );

    try {
      await AppScope.of(context).updateUser(updated);
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le compte'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
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
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Entrez un email';
                    }
                    if (!trimmed.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telephone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: 'Laissez vide pour ne pas modifier',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation',
                  ),
                  validator: (value) {
                    final pwd = _passwordController.text.trim();
                    final confirm = value?.trim() ?? '';
                    if (pwd.isNotEmpty && confirm.isEmpty) {
                      return 'Confirmez le mot de passe';
                    }
                    if (pwd.isNotEmpty && confirm != pwd) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'utilisateur', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'visiteur', child: Text('Visiteur')),
                  ],
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

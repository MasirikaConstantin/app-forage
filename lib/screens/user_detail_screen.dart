import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/app_scope.dart';
import 'user_form_dialog.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    AppUser? user;
    for (final item in store.users) {
      if (item.id == userId) {
        user = item;
        break;
      }
    }

    final currentUser = user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details utilisateur'),
      ),
      body: currentUser == null
          ? _MissingUser(onBack: () => Navigator.of(context).pop())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  _HeaderAvatar(user: currentUser),
                  const SizedBox(height: 16),
                  _HeaderCard(user: currentUser),
                  _InfoTile(
                    label: 'Email',
                    value: currentUser.email.isEmpty ? '-' : currentUser.email,
                    icon: Icons.email_outlined,
                  ),
                  _InfoTile(
                    label: 'Telephone',
                    value: currentUser.phone.isEmpty ? '-' : currentUser.phone,
                    icon: Icons.phone_outlined,
                  ),
                  _InfoTile(
                    label: 'Role',
                    value: currentUser.role,
                    icon: Icons.badge_outlined,
                  ),
                  _InfoTile(
                    label: 'Statut',
                    value: currentUser.active ? 'Actif' : 'Inactif',
                    icon: currentUser.active
                        ? Icons.verified_outlined
                        : Icons.block,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => showUserFormDialog(
                      context,
                      user: currentUser,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, currentUser),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer utilisateur'),
          content: Text('Retirer ${user.fullName} ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await AppScope.of(context).removeUser(user.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          user.fullName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(user.role),
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = user.active
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final avatarUrl = user.avatarUrl.trim();
    final size = MediaQuery.of(context).size.width.clamp(140, 220).toDouble();
    final trimmed = user.fullName.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor.withValues(alpha: 0.12),
        ),
        child: avatarUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

class _MissingUser extends StatelessWidget {
  const _MissingUser({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.warning_amber_outlined, size: 40),
            const SizedBox(height: 12),
            const Text('Utilisateur introuvable.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBack,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

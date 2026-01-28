import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/app_scope.dart';
import '../widgets/decorated_background.dart';
import '../widgets/fade_slide_in.dart';
import 'user_create_screen.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';
  bool _synced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) return;
    _synced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).syncUsers(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final background = theme.colorScheme.surface;
    final users = store.users
        .where((user) => _matches(user, _query))
        .toList(growable: false);

    return DecoratedBackground(
      gradientColors: <Color>[background],
      accents: const <Widget>[],
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FadeSlideIn(
                child: Text(
                  'Equipe de gestion',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajoutez, modifiez ou desactivez les comptes utilisateurs.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher par nom, email ou role',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SyncButton(
                    isLoading: store.isSyncingUsers,
                    onPressed: () => _handleSync(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: users.isEmpty
                    ? (store.isSyncingUsers
                        ? const _LoadingState()
                        : _EmptyState(
                            message: 'Aucun utilisateur trouve.',
                            actionLabel: 'Ajouter un utilisateur',
                            onAction: () => _openCreateUser(context),
                          ))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                      final computed = (width / 260).floor();
                      final crossAxisCount = computed.clamp(1, 3);
                      const mainAxisExtent = 96.0;

                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: mainAxisExtent,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 30 * index),
                                child: _UserCard(
                                  user: user,
                                  onTap: () => _openDetails(context, user.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: FloatingActionButton.extended(
                onPressed: () => _openCreateUser(context),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(AppUser user, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return user.fullName.toLowerCase().contains(q) ||
        user.email.toLowerCase().contains(q) ||
        user.role.toLowerCase().contains(q);
  }

  Future<void> _handleSync(BuildContext context) async {
    final store = AppScope.of(context);
    final result = await store.syncUsers(force: true);
    if (!context.mounted) return;
    final message = result.message ?? 'Synchronisation terminee';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateUser(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const UserCreateScreen(),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, String userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => UserDetailScreen(userId: userId),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = user.avatarThumbUrl.trim().isNotEmpty
        ? user.avatarThumbUrl.trim()
        : user.avatarUrl.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _Avatar(
                    name: user.fullName,
                    avatarUrl: avatarUrl,
                    statusColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isEmpty ? '-' : user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.statusColor,
  });

  final String name;
  final String avatarUrl;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: statusColor.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: statusColor.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.people_outline, size: 40),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Chargement des utilisateurs...'),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
      ),
    );
  }
}

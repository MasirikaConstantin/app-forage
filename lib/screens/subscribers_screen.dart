import 'package:flutter/material.dart';

import '../models/subscriber.dart';
import '../widgets/app_scope.dart';
import '../widgets/decorated_background.dart';
import '../widgets/fade_slide_in.dart';
import 'subscriber_create_screen.dart';
import 'subscriber_detail_screen.dart';

class SubscribersScreen extends StatefulWidget {
  const SubscribersScreen({super.key});

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen> {
  String _query = '';
  bool _synced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) return;
    _synced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).syncSubscribers(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final background = theme.colorScheme.surface;
    final subscribers = store.subscribers
        .where((subscriber) => _matches(subscriber, _query))
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
                  'Portefeuille abonnés',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Suivi des contrats et de la facturation.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher par nom, email ou telephone',
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
                    isLoading: store.isSyncingSubscribers,
                    onPressed: () => _handleSync(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: subscribers.isEmpty
                    ? (store.isSyncingSubscribers
                          ? const _LoadingState()
                          : _EmptyState(
                              message: 'Aucun abonné trouvé.',
                              actionLabel: 'Ajouter un abonné',
                              onAction: () => _openCreate(context),
                            ))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final computed = (width / 260).floor();
                          final crossAxisCount = computed.clamp(1, 3);
                          const mainAxisExtent = 90.0;

                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: mainAxisExtent,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: subscribers.length,
                            itemBuilder: (context, index) {
                              final subscriber = subscribers[index];
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 30 * index),
                                child: _SubscriberCard(
                                  subscriber: subscriber,
                                  onTap: () =>
                                      _openDetails(context, subscriber.id),
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
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(Subscriber subscriber, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return subscriber.fullName.toLowerCase().contains(q) ||
        subscriber.email.toLowerCase().contains(q) ||
        subscriber.phone.toLowerCase().contains(q);
  }

  Future<void> _handleSync(BuildContext context) async {
    final store = AppScope.of(context);
    final result = await store.syncSubscribers(force: true);
    if (!context.mounted) return;
    final message = result.message ?? 'Synchronisation terminee';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SubscriberCreateScreen(),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, String subscriberId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            SubscriberDetailScreen(subscriberId: subscriberId),
      ),
    );
  }
}

class _SubscriberCard extends StatelessWidget {
  const _SubscriberCard({required this.subscriber, required this.onTap});

  final Subscriber subscriber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.person_outline, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      subscriber.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscriber.email.isEmpty ? '-' : subscriber.email,
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
        ),
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
              const Icon(Icons.water_drop_outlined, size: 40),
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
          Text('Chargement des abonnés...'),
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

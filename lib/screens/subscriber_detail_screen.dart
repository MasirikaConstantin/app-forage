import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscriber.dart';
import '../widgets/app_scope.dart';
import 'subscriber_form_dialog.dart';

class SubscriberDetailScreen extends StatelessWidget {
  const SubscriberDetailScreen({super.key, required this.subscriberId});

  final String subscriberId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    Subscriber? subscriber;
    for (final item in store.subscribers) {
      if (item.id == subscriberId) {
        subscriber = item;
        break;
      }
    }

    final current = subscriber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details abonne'),
      ),
      body: current == null
          ? _MissingSubscriber(onBack: () => Navigator.of(context).pop())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  _HeaderCard(subscriber: current),
                  _InfoGrid(subscriber: current),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => showSubscriberFormDialog(
                      context,
                      subscriber: current,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, current),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subscriber subscriber) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer abonne'),
          content: Text('Retirer ${subscriber.fullName} ?'),
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
      await AppScope.of(context).removeSubscriber(subscriber.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.subscriber});

  final Subscriber subscriber;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subscriber.fullName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              subscriber.email.isEmpty ? '-' : subscriber.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.subscriber});

  final Subscriber subscriber;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InfoTile(
        label: 'Email',
        value: subscriber.email.isEmpty ? '-' : subscriber.email,
        icon: Icons.email_outlined,
      ),
      _InfoTile(
        label: 'Telephone',
        value: subscriber.phone.isEmpty ? '-' : subscriber.phone,
        icon: Icons.phone_outlined,
      ),
      _InfoTile(
        label: 'Adresse',
        value: subscriber.location.isEmpty ? '-' : subscriber.location,
        icon: Icons.place_outlined,
      ),
      _InfoTile(
        label: 'Profession',
        value: subscriber.plan.isEmpty ? '-' : subscriber.plan,
        icon: Icons.work_outline,
      ),
      _InfoTile(
        label: 'Date',
        value: DateFormat('dd/MM/yyyy').format(subscriber.startDate),
        icon: Icons.calendar_today_outlined,
      ),
      _InfoTile(
        label: 'Statut',
        value: subscriber.active ? 'Actif' : 'Inactif',
        icon: subscriber.active ? Icons.verified_outlined : Icons.block,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (!isWide) {
          return Column(children: tiles);
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 96,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) => tiles[index],
        );
      },
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

class _MissingSubscriber extends StatelessWidget {
  const _MissingSubscriber({required this.onBack});

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
            const Text('Abonne introuvable.'),
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

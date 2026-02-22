import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/releve.dart';
import '../models/subscriber.dart';
import '../widgets/app_scope.dart';
import 'subscriber_form_dialog.dart';

class SubscriberDetailScreen extends StatefulWidget {
  const SubscriberDetailScreen({super.key, required this.subscriberId});

  final String subscriberId;

  @override
  State<SubscriberDetailScreen> createState() => _SubscriberDetailScreenState();
}

class _SubscriberDetailScreenState extends State<SubscriberDetailScreen> {
  Subscriber? subscriber;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSubscriberFromApi();
  }

  Future<void> _loadSubscriberFromApi() async {
    setState(() => isLoading = true);
    try {
      // Utiliser la méthode du store pour récupérer l'abonné avec ses relevés
      final store = AppScope.of(context);
      final subscriber = await store.fetchSubscriber(widget.subscriberId);

      if (subscriber != null && mounted) {
        setState(() => this.subscriber = subscriber);
      }
    } catch (e) {
      debugPrint('Error loading subscriber from API: $e');
      // Fallback au cache local
      _loadSubscriberFromCache();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<String?> _getAuthToken() async {
    // Essayer de récupérer le token depuis plusieurs sources
    try {
      // Pour l'instant, on va essayer de charger depuis l'API sans token
      // et voir si ça marche, sinon on utilisera le cache
      return null; // Temporairement null pour tester
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _loadSubscriberFromCache() async {
    final store = AppScope.of(context);
    debugPrint('Store subscribers count: ${store.subscribers.length}');
    debugPrint('Looking for subscriber ID: ${widget.subscriberId}');

    for (final item in store.subscribers) {
      debugPrint('Checking subscriber: ${item.id} - ${item.fullName}');
      if (item.id == widget.subscriberId) {
        if (mounted) {
          debugPrint('Found subscriber in cache: ${item.fullName}');
          setState(() => subscriber = item);
        }
        break;
      }
    }

    // Si toujours pas trouvé après le fallback, afficher quand même l'erreur
    if (subscriber == null && mounted) {
      debugPrint('Subscriber not found in cache, showing dummy');
      setState(
        () => subscriber = Subscriber(
          id: widget.subscriberId,
          fullName: 'Chargement...',
          email: '',
          phone: '',
          location: '',
          plan: '',
          active: true,
          startDate: DateTime.now(),
          monthlyFee: 0.0,
          releves: [],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails abonné')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscriber == null
          ? _MissingSubscriber(onBack: () => Navigator.of(context).pop())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  _HeaderCard(subscriber: subscriber!),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: FilledButton.icon(
                          onPressed: () => showSubscriberFormDialog(
                            context,
                            subscriber: subscriber,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, subscriber!),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoGrid(subscriber: subscriber!),
                  if (subscriber!.releves != null &&
                      subscriber!.releves!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _FacturationSection(releves: subscriber!.releves!),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Subscriber subscriber,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer abonné'),
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

class _FacturationSection extends StatelessWidget {
  const _FacturationSection({required this.releves});

  final List<Releve> releves;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des facturations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: releves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final releve = releves[index];
                final facturation = releve.facturation;

                if (facturation == null) {
                  return _ReleveCard(releve: releve);
                }

                return _FacturationCard(
                  releve: releve,
                  facturation: facturation,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



class _FacturationCard extends StatelessWidget {
  const _FacturationCard({required this.releve, required this.facturation});

  final Releve releve;
  final Facturation facturation;

  @override
  Widget build(BuildContext context) {
    final montant = double.tryParse(facturation.montantTotal) ?? 0;
    final estPaye = facturation.estPaye == 1;
    final theme = Theme.of(context);

    return Card(
      color: estPaye 
          ? theme.colorScheme.surfaceVariant.withOpacity(0.5)  // Vert adapté au thème
          : theme.colorScheme.errorContainer.withOpacity(0.3), // Orange/rouge adapté
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  facturation.periode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estPaye 
                        ? theme.colorScheme.primary  // Utiliser la couleur primaire
                        : theme.colorScheme.error,   // Utiliser la couleur d'erreur
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estPaye ? 'Payé' : 'Non payé',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary, // Texte contrasté
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Flexible(
                  child: Text(
                    'Consommation: ${facturation.consommationM3} m³',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    'Prix: ${facturation.prixM3} CDF/m³',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Flexible(
                  child: Text('Index: ${releve.index}'),
                ),
                Flexible(
                  child: Text(
                    '${montant.toStringAsFixed(0)} CDF',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: montant < 0 
                          ? theme.colorScheme.error  // Rouge adapté au thème
                          : theme.colorScheme.primary, // Vert/primaire adapté
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            Text(
              'Date relevé: ${releve.dateReleve}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
class _ReleveCard extends StatelessWidget {
  const _ReleveCard({required this.releve});

  final Releve releve;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relevé sans facturation',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Index: ${releve.index}'),
                Text('Index cumulé: ${releve.cumulIndex}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Date relevé: ${releve.dateReleve}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
            const Text('Abonné introuvable.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onBack, child: const Text('Retour')),
          ],
        ),
      ),
    );
  }
}

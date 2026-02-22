import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_stats.dart';
import '../widgets/app_scope.dart';
import '../widgets/decorated_background.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  AppStats? _stats;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final stats = await AppScope.of(context).fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0.##');
    final background = theme.colorScheme.surface;
    final stats = _stats;
    final showStatsSkeleton = _loading && stats == null;

    final summaryCards = showStatsSkeleton
        ? List<Widget>.generate(4, (_) => const _SummaryCardSkeleton())
        : <Widget>[
            SummaryCard(
              title: 'Utilisateurs',
              value: (stats?.users.total ?? store.users.length).toString(),
              icon: Icons.people_outline,
            ),
            SummaryCard(
              title: 'Abonnés',
              value: (stats?.abonnes.total ?? store.subscribers.length)
                  .toString(),
              icon: Icons.water_drop_outlined,
              accentColor: const Color(0xFF0B6E4F),
            ),
            SummaryCard(
              title: 'Relevés',
              value: (stats?.releves.total ?? 0).toString(),
              icon: Icons.list_alt_outlined,
            ),
            SummaryCard(
              title: 'Facturations',
              value: (stats?.facturations.total ?? 0).toString(),
              icon: Icons.receipt_long_outlined,
              accentColor: const Color(0xFFD98C3F),
            ),
          ];

    final details = stats == null
        ? <_StatItem>[]
        : <_StatItem>[
            _StatItem('Utilisateurs actifs', stats.users.active.toString()),
            _StatItem('Utilisateurs inactifs', stats.users.inactive.toString()),
            _StatItem('Roles', _formatMap(stats.users.byRole)),
            _StatItem('Abonnés actifs', stats.abonnes.active.toString()),
            _StatItem('Abonnés inactifs', stats.abonnes.inactive.toString()),
            _StatItem(
              'Relevés somme index',
              formatter.format(stats.releves.sumIndex),
            ),
            _StatItem(
              'Relevés max cumul',
              formatter.format(stats.releves.maxCumulIndex),
            ),
            _StatItem('Relevés dernière date', stats.releves.lastDate),
            _StatItem(
              'Facturations payées',
              stats.facturations.payees.toString(),
            ),
            _StatItem(
              'Facturations impayées',
              stats.facturations.impayees.toString(),
            ),
            _StatItem(
              'Montant impayés',
              formatter.format(stats.facturations.montantImpayes),
            ),
            _StatItem(
              'Consommation total m3',
              formatter.format(stats.facturations.consommationTotalM3),
            ),
            _StatItem('Derniere periode', stats.facturations.lastPeriode),
            _StatItem('Parametres actifs', stats.parametres.active.toString()),
            _StatItem(
              'Parametres inactifs',
              stats.parametres.inactive.toString(),
            ),
            _StatItem('Sync total', stats.syncLogs.total.toString()),
            _StatItem('Derniere sync', stats.syncLogs.lastSyncAt),
            _StatItem(
              'Devices distincts',
              stats.syncLogs.distinctDevices.toString(),
            ),
            _StatItem('User devices total', stats.userDevices.total.toString()),
            _StatItem(
              'Users distincts',
              stats.userDevices.distinctUsers.toString(),
            ),
            _StatItem('Dernier usage', stats.userDevices.lastUsedAt),
            _StatItem('Logs total', stats.userLogs.total.toString()),
            _StatItem('Logs 7 jours', stats.userLogs.last7Days.toString()),
            _StatItem('Actions', _formatMap(stats.userLogs.byAction)),
            _StatItem('Media total', stats.media.total.toString()),
            _StatItem('Taille media', formatter.format(stats.media.totalSize)),
            _StatItem('Genere le', stats.generatedAt ?? '-'),
          ];

    return DecoratedBackground(
      gradientColors: <Color>[background],
      accents: const <Widget>[],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FadeSlideIn(
              child: Text('Accueil', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 6),
            Text(
              'Vue rapide des donnees principales du forage.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final computed = (width / 260).floor();
                final crossAxisCount = computed.clamp(1, 5);
                const mainAxisExtent = 90.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: mainAxisExtent,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: summaryCards.length,
                  itemBuilder: (context, index) => summaryCards[index],
                );
              },
            ),
            const SizedBox(height: 16),
            if (showStatsSkeleton)
              const _StatGridSkeleton()
            else if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (details.isNotEmpty)
              _StatGrid(items: details),
            const SizedBox(height: 24),
            
            const SizedBox(height: 12),
            
          ],
        ),
      ),
    );
  }

  String _formatMap(Map<String, int> items) {
    if (items.isEmpty) return '-';
    return items.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value);

  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final computed = (width / 260).floor();
        final crossAxisCount = computed.clamp(1, 3);
        const mainAxisExtent = 90.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.label),
                subtitle: Text(item.value.isEmpty ? '-' : item.value),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final shadowOpacity = theme.brightness == Brightness.dark ? 0.0 : 0.06;

    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: <Widget>[
          _SkeletonBlock(height: 44, width: 44, shape: BoxShape.circle),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _SkeletonBlock(height: 12, width: 86),
                SizedBox(height: 8),
                _SkeletonBlock(height: 18, width: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGridSkeleton extends StatelessWidget {
  const _StatGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final computed = (width / 260).floor();
        final crossAxisCount = computed.clamp(1, 3);
        const mainAxisExtent = 90.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _SkeletonBlock(height: 12, width: 130),
                    SizedBox(height: 8),
                    _SkeletonBlock(height: 14, width: 86),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.width,
    this.shape = BoxShape.rectangle,
  });

  final double height;
  final double width;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.75,
        ),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(8),
      ),
    );
  }
}
